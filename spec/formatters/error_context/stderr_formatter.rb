# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "base_formatter"
require "escape_code"
require_relative "../rerun_argument"

module ErrorContext
  class StderrFormatter < BaseFormatter
    def example_finished(*)
      super
      write_to_stderr
    end

    def write_to_stderr
      output = []

      # always send js errors to stdout, even if the spec passed. we have to
      # empty the JSErrorCollector anyway, so we might as well show it.
      summary.js_errors&.each do |error|
        output << "  JS Error: #{error["errorMessage"]} (#{error["sourceName"]}:#{error["lineNumber"]})"
      end

      output << "  Screenshot: #{File.join(errors_path, summary.screenshot_name)}" if summary.screenshot_name
      # TODO: doesn't work in new docker builds
      # output << "  Screen capture: #{File.join(errors_path, summary.screen_capture_name)}" if summary.screen_capture_name

      if output.any?
        output.unshift RerunArgument.for(summary.example)
        warn output.join("\n")
      end
    end
  end
end
