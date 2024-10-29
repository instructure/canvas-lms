# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module ModuleVisibility
  class ModuleVisibilityService
    extend VisibilityHelpers::Common
    class << self
      # this is seemingly only called in specs
      def modules_visible_to_student(course_id:, user_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        modules_visible_to_students(course_ids: course_id, user_ids: user_id)
      end

      def modules_visible_to_students_in_courses(course_ids:, user_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        modules_visible_to_students(course_ids:, user_ids:)
      end

      # this is seemingly only called in specs.
      def module_visible_to_student(context_module_id:, user_id:)
        raise ArgumentError, "context_module_id cannot be nil" if context_module_id.nil?
        raise ArgumentError, "context_module_id must not be an array" if context_module_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        modules_visible_to_students(context_module_ids: context_module_id, user_ids: user_id)
      end

      def module_visible_to_students(context_module_id:, user_ids:)
        raise ArgumentError, "context_module_id cannot be nil" if context_module_id.nil?
        raise ArgumentError, "context_module_id must not be an array" if context_module_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        modules_visible_to_students(context_module_ids: context_module_id, user_ids:)
      end

      private

      def modules_visible_to_students(course_ids: nil, user_ids: nil, context_module_ids: nil)
        if course_ids.nil? && user_ids.nil? && context_module_ids.nil?
          raise ArgumentError, "at least one non nil course_id, user_id, or context_module_ids is required (for query performance reasons)"
        end

        service_cache_fetch(service: name,
                            course_ids:,
                            user_ids:,
                            additional_ids: context_module_ids) do
          visible_modules = []

          # add modules visible to everyone
          modules_visible_to_all = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                   .find_modules_visible_to_everyone(course_ids:, user_ids:, context_module_ids:)
          visible_modules |= modules_visible_to_all

          # add modules visible to sections (and related module section overrides)
          modules_visible_to_sections = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                        .find_modules_visible_to_sections(course_ids:, user_ids:, context_module_ids:)
          visible_modules |= modules_visible_to_sections

          # add modules visible due to ADHOC overrides (and related module ADHOC overrides)
          modules_visible_to_adhoc_overrides = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                               .find_modules_visible_to_adhoc_overrides(course_ids:, user_ids:, context_module_ids:)
          visible_modules | modules_visible_to_adhoc_overrides
        end
      end
    end
  end
end
