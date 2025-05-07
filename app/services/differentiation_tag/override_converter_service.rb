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
  class OverrideConverterService
    class << self
      # For now this method only handles context modules but will be expanded in the next ticket
      def convert_tags_to_adhoc_overrides_for(learning_object:, course:, executing_user:)
        errors = validate_params(learning_object, course)
        return errors if errors.present?

        tag_overrides = differentiation_tags(learning_object)
        return unless tag_overrides.present?

        begin
          convert_tags_to_adhoc(learning_object, course, executing_user, tag_overrides)
        rescue DifferentiationTagServiceError => e
          return e.message
        end

        # no errors
        nil
      end

      private

      def convert_tags_to_adhoc(learning_object, course, executing_user, tag_overrides)
        ActiveRecord::Base.transaction do
          errors = handle_context_module(learning_object, course, executing_user, tag_overrides)
          raise(DifferentiationTagServiceError, errors) if errors.present?

          destroy_differentiation_tag_overrides(tag_overrides)
        end
      end

      def handle_context_module(context_module, course, executing_user, tag_overrides)
        tags = tag_overrides.map(&:set)
        students = find_students_to_override(context_module, tags)

        return unless students.present?

        override_data = { student_ids: students }
        AdhocOverrideCreatorService.create_adhoc_override(course, context_module, override_data, executing_user)
      end

      def differentiation_tags(learning_object)
        group_table = Group.quoted_table_name
        override_table = AssignmentOverride.quoted_table_name

        learning_object.assignment_overrides
                       .active
                       .where(set_type: "Group")
                       .joins("JOIN #{group_table} ON #{group_table}.id = #{override_table}.set_id")
                       .where("#{group_table}.non_collaborative = true")
      end

      def destroy_differentiation_tag_overrides(overrides)
        overrides.destroy_all
      end

      def find_students_to_override(learning_object, tags)
        students = find_students_in_tags(tags)
        filter_out_students_already_overriden(learning_object, students)
      end

      def find_students_in_tags(tags)
        students = Set.new
        tags.each do |tag|
          students.merge(tag.users.map(&:id))
        end
        students
      end

      def filter_out_students_already_overriden(learning_object, students)
        adhoc_overrides = learning_object.assignment_overrides.adhoc
        return students if adhoc_overrides.empty?

        students_with_overrides = Set.new
        adhoc_overrides.each do |adhoc_override|
          students_with_overrides.merge(adhoc_override.assignment_override_students.map(&:user_id))
        end
        (students - students_with_overrides).to_a
      end

      def validate_params(learning_object, course)
        errors = []

        errors.append("Invalid course provided") unless course.is_a?(Course)
        errors.append("Invalid learning object provided") unless learning_object && overridable?(learning_object)

        errors
      end

      def overridable?(learning_object)
        return false unless learning_object.present?

        DifferentiationTag::OVERRIDABLE_LEARNING_OBJECTS.include?(learning_object.class.name)
      end
    end
  end
end
