# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class CreateStreamEntries < ::ROM::Changeset::Create
        module Defaults
          def self.included(base)
            base.class_eval do
              relation :stream_entries

              map do |tuple|
                Hash(created_at: RubyEventStore::ROM::Types::DateTime.call(nil)).merge(tuple)
              end
            end
          end
        end

        include Defaults
      end
    end
  end
end
