# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class NodeCountRecorder
  RSpec::Core::Formatters.register self, :dump_summary

  def initialize(output)
    @output = output
  end

  def dump_summary(output)
    node_total = output.examples.reduce(0.0) { |sum, e| sum + (e.location.include?("selenium") ? 1.0 / (25 * ENV["RSPEC_PROCESSES"].to_f) : 1.0 / (190 * ENV["RSPEC_PROCESSES"].to_f)) }.ceil
    spec_total = output.examples.count

    @output << "#{node_total} #{spec_total}"
  end
end
