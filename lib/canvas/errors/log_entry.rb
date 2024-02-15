# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../errors"
module Canvas
  class Errors
    # Class for formatting any error captured
    # through this subsystem as a digestable stack trace in
    # canvas debug logs.  Intended to be hooked into
    # Canvas::Errors as a callback in an initializer.
    #
    # The exception itself, the backtrace, and any key/val submitted
    # as accompanying data will all get logged.
    class LogEntry
      # 'exception' can also just be a string
      # which is itself a message, sometimes we assert
      # on a condition and write a message if a surprising
      # thing happens
      def self.write(exception, data, level = :error)
        msg = new(exception, data).message
        Rails.logger.send(level, msg)
      end

      def initialize(exception, data_hash)
        @ex = exception
        @data = data_hash
      end

      def message
        msg = +""
        deprecators = ($canvas_rails == "7.0") ? ActiveSupport::Deprecation : Rails.application.deprecators
        deprecators.silence do
          msg << "\n\n[CANVAS_ERRORS] EXCEPTION LOG"
          if @ex.is_a?(String) || @ex.is_a?(Symbol)
            msg << "\n#{@ex}\n"
          else
            msg << log_entry_for_exception(@ex)
            caused_by = @ex.try(:cause)
            while caused_by.present?
              msg << "\n****Caused By****\n"
              msg << log_entry_for_exception(caused_by)
              caused_by = caused_by.cause
            end
          end
          msg << "CONTEXT: #{@data}\n\n"
        end
        msg
      end

      def log_entry_for_exception(e)
        entry = +""
        entry << "\n#{e.class}"
        begin
          entry << " (#{e.message}):" if e.respond_to?(:message)
        rescue => e
          entry << "\n***[WARNING]: Unable to extract error message due to #{e}"
        end
        entry << "\n"
        entry << e.annoted_source_code.to_s if e.respond_to?(:annoted_source_code)
        if e.respond_to?(:backtrace)
          b_trace = e.backtrace&.join("\n  ")
          entry << "  " << b_trace if b_trace
        end
        entry
      end
    end
  end
end
