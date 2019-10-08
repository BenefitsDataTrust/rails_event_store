# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class CreateEvents < ::ROM::Changeset::Create
        module Defaults
          def self.included(base)
            base.class_eval do
              relation :events

              map(&:to_h)
              map do
                rename_keys event_id: :id, timestamp: :created_at
                accept_keys %i[id data metadata event_type created_at]
              end
            end
          end
        end

        include Defaults
      end
    end
  end
end
