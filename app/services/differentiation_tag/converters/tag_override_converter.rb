# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DifferentiationTag
  module Converters
    class TagOverrideConverter
      class << self
        def differentiation_tag_overrides_for(learning_object)
          group_table = Group.quoted_table_name
          override_table = AssignmentOverride.quoted_table_name

          learning_object.assignment_overrides
                         .active
                         .where(set_type: "Group")
                         .joins("JOIN #{group_table} ON #{group_table}.id = #{override_table}.set_id")
                         .where("#{group_table}.non_collaborative = true")
        end

        def destroy_differentiation_tag_overrides(tag_overrides)
          tag_overrides.destroy_all
        end

        def find_students_in_tags(tags)
          students = Set.new
          tags.each do |tag|
            students.merge(tag.users.map(&:id))
          end
          students
        end

        def students_already_overridden(learning_object)
          students_overridden = Set.new
          adhoc_overrides = learning_object.assignment_overrides.adhoc

          adhoc_overrides.each do |adhoc_override|
            students_overridden.merge(adhoc_override.assignment_override_students.map(&:user_id))
          end

          students_overridden
        end

        def sort_overrides(overrides:, sort_by:)
          # remove all overrides that have nil values for the sort_by field
          nil_overrides = overrides.select { |override| override.send(sort_by).nil? }
          overrides -= nil_overrides

          overrides = overrides.sort_by { |override| override.send(sort_by) }

          # add the nil overrides back to the end of the list
          overrides += nil_overrides

          # descending order (latest date first)
          overrides.reverse
        end
      end
    end
  end
end
