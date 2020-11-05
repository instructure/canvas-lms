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

# kinda like SummaryNotification#rerun_argument_for, except that it's
#  * general purpose
#  * works correctly even if just a subset of spec files are loaded
module RerunArgument
  class << self
    def for(example)
      if shared_example?(example) || duplicate_location?(example)
        example.id
      else
        example.location_rerun_argument
      end
    end

    def shared_example?(example)
      example.example_group.parent_groups.any? { |group| group.metadata[:shared_group_name] }
    end

    def duplicate_location?(example)
      examples_at_location = examples_by_location(example.example_group.parent_groups.last)[example.location_rerun_argument]
      examples_at_location.size > 1
    end

    def examples_by_location(root_group)
      @examples_by_location ||= {}
      @examples_by_location[root_group] ||= begin
        all_examples = root_group.descendants.inject([]) do |examples, group|
          examples.concat group.examples
        end
        all_examples.each_with_object({}) do |example, map|
          map[example.location_rerun_argument] ||= []
          map[example.location_rerun_argument] << example
        end
      end
    end
  end
end
