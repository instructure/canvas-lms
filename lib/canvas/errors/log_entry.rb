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

require_relative '../errors'
module Canvas
  class Errors

    # Class for formatting any error captured
    # through this subsystem as a digestable stack trace in
    # canvas debug logs.  Intended to be hooked into
    # Canvas::Errors as a callback in an initializer.
    class LogEntry
      # 'exception' can also just be a string
      # which is itself a message, sometimes we assert
      # on a condition and write a message if a surprising
      # thing happens
      def self.write(exception, data, level=:error)
        msg = self.new(exception, data).message
        Rails.logger.send(level, msg)
      end

      def initialize(exception, data_hash)
        @ex = exception
        @data = data_hash
      end

      def message
        msg = ""
        ActiveSupport::Deprecation.silence do
          msg << "\n\n[CANVAS_ERRORS] EXCEPTION LOG"
          if @ex.is_a?(String)
            msg << "\n#{@ex}\n"
          else
            msg << "\n#{@ex.class}"
            msg << " (#{@ex.message}):" if @ex.respond_to?(:message)
            msg << "\n"
            msg << @ex.annoted_source_code.to_s if @ex.respond_to?(:annoted_source_code)
            if @ex.respond_to?(:backtrace)
              b_trace = @ex.backtrace&.join("\n  ")
              msg << "  " << b_trace if b_trace
            end
          end
          msg << "CONTEXT: #{@data}\n\n"
        end
        msg
      end
    end
  end
end