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
  class AdhocOverrideCreatorService
    class << self
      def create_adhoc_override(course, learning_object, override_data, executing_user)
        errors = validate_params(course, learning_object, override_data, executing_user)
        return errors if errors.present?

        # based off of learning_object type, delegate to appropriate service
        # Current ticket is only focused on Context Modules but will be handled
        # in the next ticket (https://instructure.atlassian.net/browse/EGG-870)
        #  - Context modules are done here
        #  - Checkpoints have their own service to make these adhoc overrides
        #  - Everything else will be handled by the submission lifecycle manager in lib/assignment_overrides.rb

        # Create brand new override for learning object
        create_context_module_adhoc_override(learning_object, override_data)

        # no errors so return nil
        nil
      end

      private

      def create_context_module_adhoc_override(context_module, override_data)
        override = context_module.assignment_overrides.create!(set_type: "ADHOC")
        add_students_to_override(override, override_data[:student_ids])
      end

      def add_students_to_override(override, students_ids)
        rows = students_ids.map do |student_id|
          {
            assignment_override_id: override.id,
            user_id: student_id,
            workflow_state: "active",
            assignment_id: override.assignment_id,
            quiz_id: override.quiz_id,
            wiki_page_id: override.wiki_page_id,
            discussion_topic_id: override.discussion_topic_id,
            attachment_id: override.attachment_id,
            context_module_id: override.context_module_id,
          }
        end

        rows.each_slice(1000) do |slice|
          AssignmentOverrideStudent.upsert_all(slice)
        end
      end

      def validate_params(course, learning_object, override_data, executing_user)
        errors = []

        errors.append("Invalid course provided") unless course.present? && course.is_a?(Course)
        errors.append("Invalid user provided") unless executing_user.present? && executing_user.is_a?(User)
        errors.append("Invalid learning object provided") unless learning_object.present? && overridable?(learning_object)
        errors.append("Invalid override data provided") unless override_data[:student_ids].present?

        errors
      end

      def overridable?(learning_object)
        return false unless learning_object.present?

        DifferentiationTag::OVERRIDABLE_LEARNING_OBJECTS.include?(learning_object.class.name)
      end
    end
  end
end
