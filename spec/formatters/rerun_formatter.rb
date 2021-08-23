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

require "rspec/core/formatters/base_text_formatter"
require_relative "rerun_argument"

module RSpec
  class RerunFormatter < RSpec::Core::Formatters::BaseFormatter
    ::RSpec::Core::Formatters.register self, :dump_failures

    def dump_failures(notification)
      notification.failed_examples.each do |example|
        log_rerun(example)
      end
    end

    def log_rerun(example)
      path = RerunArgument.for(example)
      path_without_line_number = path.gsub(/(\.\/|[:\[].*)/, "")

      if modified_specs.include?(path_without_line_number)
        puts "not adding modified spec to rerun #{path}"
        return
      end

      puts "adding spec to rerun #{path}"
    end

    def modified_specs
      @modified_specs ||= ENV["RELEVANT_SPECS"] && ENV["RELEVANT_SPECS"].split("\n") || []
    end
  end
end
