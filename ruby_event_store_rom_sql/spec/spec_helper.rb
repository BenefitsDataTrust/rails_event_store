require 'ruby_event_store/rom'
require 'support/rspec_defaults'
require 'support/mutant_timeout'

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

ENV['DATABASE_URL']  ||= 'sqlite:db.sqlite3'

rom = ROM::Configuration.new(
  :sql,
  ENV['DATABASE_URL'],
  max_connections: ENV['DATABASE_URL'] =~ /sqlite/ ? 1 : 5,
  preconnect: :concurrently
)
rom.default.run_migrations
# rom.default.use_logger Logger.new(STDOUT)

RubyEventStore::ROM.env = RubyEventStore::ROM.setup(rom)

module SchemaHelper
  def rom
    RubyEventStore::ROM.env
  end

  def rom_db
    rom.gateways[:default]
  end

  def establish_database_connection
    # Manually preconnect because disconnecting and reconnecting
    # seems to lose the "preconnect concurrently" setting
    rom_db.connection.pool.send(:preconnect, true)
  end

  def load_database_schema
    rom_db.run_migrations
  end

  def drop_database
    rom_db.connection.drop_table?('event_store_events')
    rom_db.connection.drop_table?('event_store_events_in_streams')
    rom_db.connection.drop_table?('schema_migrations')
  end

  # See: https://github.com/rom-rb/rom-sql/blob/master/spec/shared/database_setup.rb
  def close_database_connection
    rom_db.connection.disconnect
    # Prevent the auto-reconnect when the test completed
    # This will save from hardly reproducible connection run outs
    rom_db.connection.pool.available_connections.freeze
  end
end

RSpec.configure do |config|
  config.failure_color = :magenta
end