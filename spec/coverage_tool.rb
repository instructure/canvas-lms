# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
#

require "simplecov"
require_relative "canvas_simplecov"

class CoverageTool
  def self.start(command_name)
    # Make a unique index to avoid having duplicate rspec:{id} values at time of merge
    parallel_index = ENV["CI_NODE_INDEX"] || "0"
    rspec_command_index = (1_000_000_000 * parallel_index.to_i) + Process.pid

    ::SimpleCov.merge_timeout(3600)
    ::SimpleCov.command_name("#{command_name}:#{rspec_command_index}")

    ::SimpleCov.start "canvas_rails" do
      formatter ::SimpleCov::Formatter::MultiFormatter.new(
        [
          ::SimpleCov::Formatter::SimpleFormatter,
          ::SimpleCov::Formatter::HTMLFormatter
        ]
      )

      ::SimpleCov.at_exit do
        # generate an HTML report if this is running locally / not on jenkins:
        ::SimpleCov.result.format! unless ENV["RSPEC_PROCESSES"]
        ::SimpleCov.result
      end
    end
  end
end
