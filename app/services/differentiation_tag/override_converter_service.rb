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
      def convert_tags_to_adhoc_overrides_for(learning_object:, course:)
        errors = validate_params(learning_object, course)
        return errors if errors.present?

        converter = get_converter(learning_object)
        errors = converter.convert_tags_to_adhoc_overrides(learning_object, course)
        return errors if errors.present?

        # no errors
        nil
      end

      private

      def get_converter(learning_object)
        if learning_object.is_a?(ContextModule)
          Converters::ContextModuleOverrideConverter
        elsif learning_object.is_a?(Assignment) && learning_object.has_sub_assignments?
          Converters::CheckpointedDiscussionOverrideConverter
        else
          Converters::GeneralAssignmentOverrideConverter
        end
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
