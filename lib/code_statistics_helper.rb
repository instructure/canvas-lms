# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module CodeStatisticsHelper
  SPEC_DIRECTORIES = {
    "Model specs" => "spec/models",
    "Service specs" => "spec/services",
    "View specs" => "spec/views",
    "Controller specs" => "spec/controllers",
    "Helper specs" => "spec/helpers",
    "Library specs" => "spec/lib",
    "Routing specs" => "spec/routing"
  }.freeze

  def self.register_spec_directory(name, path)
    require "rails/code_statistics"

    return unless File.exist?(path)

    Rails::CodeStatistics.register_directory(name, path)
    Rails::CodeStatistics::TEST_TYPES << name
  end

  def self.register_all_spec_directories
    SPEC_DIRECTORIES.each { |name, path| register_spec_directory(name, path) }
  end
end
