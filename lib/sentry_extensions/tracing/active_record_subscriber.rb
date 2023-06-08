# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "sentry-rails"
require "pg_query"

module SentryExtensions
  module Tracing
    # This is derived from Sentry's `ActiveRecordSubscriber`. We needed to normalize our SQL statements so that we don't
    # leak any sensitive information in the parameter values. This class is identical to Sentry's, except for the
    # `description` modification in the interior lambda body.
    class ActiveRecordSubscriber < Sentry::Rails::Tracing::AbstractSubscriber
      SQL_REGEX = /^(\d+::)?(.*)/m
      EVENT_NAMES = ["sql.active_record"].freeze
      SPAN_PREFIX = "db."
      EXCLUDED_EVENTS = %w[SCHEMA TRANSACTION].freeze

      def self.subscribe!
        subscribe_to_event(EVENT_NAMES) do |event_name, duration, payload|
          next if EXCLUDED_EVENTS.include? payload[:name]

          record_on_current_span(op: SPAN_PREFIX + event_name, start_timestamp: payload[Sentry::Rails::Tracing::START_TIMESTAMP_NAME], description: payload[:sql], duration:) do |span|
            begin
              if payload[:sql]
                # $1 is the Switchman shard prefix (which PgQuery doesn't understand), $2 is the standard SQL statement
                match = SQL_REGEX.match(payload[:sql])
                span.set_description("#{match[1]}#{PgQuery.normalize(match[2])}")
              end
            rescue PgQuery::ParseError => e
              Canvas::Errors.capture_exception(:tracing, e, :warn)
              span.set_description("<sql hidden; error during normalization>")
            end

            span.set_data(:connection_id, payload[:connection_id])
          end
        end
      end
    end
  end
end
