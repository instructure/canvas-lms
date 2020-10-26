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

require 'canvas_partman/partition_manager'
require 'canvas_partman/migration'
require 'canvas_partman/dynamic_relation'
require 'canvas_partman/concerns/partitioned'

module CanvasPartman
  class << self
    # @property [String, "partitions"] migrations_scope
    #   The filename "scope" that identifies partition migrations. This is a key
    #   that is separated from the name of the migration file and the "rb"
    #   extension by dots.
    #
    #   Example: "partitions" => "20141215000000_add_something.partitions.rb"
    attr_accessor :migrations_scope
  end

  self.migrations_scope = 'partitions'
end
