require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq5_format"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1

      class Configuration
        def initialize(
          split_keys:,
          message_format:,
          batch_size:,
          database_url:,
          redis_url:
        )
          @split_keys = split_keys
          @message_format = message_format
          @batch_size = batch_size || 100
          @database_url = database_url
          @redis_url = redis_url
          freeze
        end

        def with(overriden_options)
          self.class.new(
            split_keys: overriden_options.fetch(:split_keys, split_keys),
            message_format: overriden_options.fetch(:message_format, message_format),
            batch_size: overriden_options.fetch(:batch_size, batch_size),
            database_url: overriden_options.fetch(:database_url, database_url),
            redis_url: overriden_options.fetch(:redis_url, redis_url),
          )
        end

        attr_reader :split_keys, :message_format, :batch_size, :database_url, :redis_url
      end

      def initialize(configuration, clock: Time, logger:, metrics:)
        @split_keys = configuration.split_keys
        @clock = clock
        @redis = Redis.new(url: configuration.redis_url)
        @logger = logger
        @metrics = metrics
        @batch_size = configuration.batch_size
        @process_uuid = SecureRandom.uuid
        ActiveRecord::Base.establish_connection(configuration.database_url) unless ActiveRecord::Base.connected?
        if ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ActiveRecord::Base.connection.execute("SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;")
          ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        @message_format = SIDEKIQ5_FORMAT

        @gracefully_shutting_down = false
        prepare_traps
      end

      def init
        @redis.sadd("queues", split_keys)
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")
      end

      def run
        while !@gracefully_shutting_down do
          was_something_changed = one_loop
          if !was_something_changed
            STDOUT.flush
            sleep SLEEP_TIME_WHEN_NOTHING_TO_DO
          end
        end
        logger.info "Gracefully shutting down"
      end

      def one_loop
        remaining_split_keys = @split_keys.dup

        was_something_changed = false
        while (split_key = remaining_split_keys.shift)
          was_something_changed |= handle_split(split_key)
        end
        was_something_changed
      end

      def handle_split(split_key)
        lock_obtained = obtain_lock_for_process(split_key)
        return false unless lock_obtained

        records = Record.where(format: message_format, enqueued_at: nil, split_key: split_key).order("id ASC").limit(batch_size).to_a
        if records.empty?
          metrics.write_point_queue(status: "ok")
          release_lock_for_process(split_key)
          return false
        end

        failed_record_ids = []
        updated_record_ids = []
        records.each do |record|
          begin
            now = @clock.now.utc
            parsed_record = JSON.parse(record.payload)
            queue = parsed_record["queue"]
            if queue.nil? || queue.empty?
              failed_record_ids << record.id
              next
            end
            payload = JSON.generate(parsed_record.merge({
              "enqueued_at" => now.to_f,
            }))

            @redis.lpush("queue:#{queue}", payload)

            record.update_column(:enqueued_at, now)
            updated_record_ids << record.id
          rescue => e
            failed_record_ids << record.id
            e.full_message.split($/).each {|line| logger.error(line) }
          end
        end

        metrics.write_point_queue(status: "ok", enqueued: updated_record_ids.size, failed: failed_record_ids.size)

        logger.info "Sent #{updated_record_ids.size} messages from outbox table"

        release_lock_for_process(split_key)

        true
      end

      private
      attr_reader :split_keys, :logger, :message_format, :batch_size, :metrics

      def obtain_lock_for_process(split_key)
        Lock.transaction do
          lock = Lock.lock.find_by(split_key: split_key)
          if lock.nil?
            begin
              lock = Lock.create!(split_key: split_key)
            rescue ActiveRecord::RecordNotUnique
            end
            lock = Lock.lock.find_by(split_key: split_key)
          end

          return false unless lock.locked_by.nil?

          lock.update!(
            locked_by: @process_uuid,
            locked_at: Time.now.utc,
          )
        end
        true
      rescue ActiveRecord::Deadlocked
        logger.warn "Obtaining lock for split_key '#{split_key}' failed (deadlock) [#{@process_uuid}]"
        metrics.write_point_queue(status: "deadlocked")
        false
      rescue ActiveRecord::LockWaitTimeout
        logger.warn "Obtaining lock for split_key '#{split_key}' failed (lock timeout) [#{@process_uuid}]"
        metrics.write_point_queue(status: "lock_timeout")
        false
      end

      def release_lock_for_process(split_key)
        Lock.transaction do
          lock = Lock.lock.find_by(split_key: split_key)
          return if lock.nil? || lock.locked_by != @process_uuid

          lock.update!(locked_by: nil, locked_at: nil)
        end
      rescue ActiveRecord::Deadlocked
        logger.warn "Releasing lock for split_key '#{split_key}' failed (deadlock) [#{@process_uuid}]"
      rescue ActiveRecord::LockWaitTimeout
        logger.warn "Releasing lock for split_key '#{split_key}' failed (lock timeout) [#{@process_uuid}]"
      end

      def prepare_traps
        Signal.trap("INT") do
          initiate_graceful_shutdown
        end
        Signal.trap("TERM") do
          initiate_graceful_shutdown
        end
      end

      def initiate_graceful_shutdown
        @gracefully_shutting_down = true
      end
    end
  end
end
