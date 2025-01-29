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
      def modules_visible_to_students(course_ids: nil, user_ids: nil, context_module_ids: nil)
        unless course_ids || user_ids || context_module_ids
          raise ArgumentError, "at least one non nil course_id, user_id, or context_module_ids is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        context_module_ids = Array(context_module_ids) if context_module_ids

        service_cache_fetch(service: name, course_ids:, user_ids:, additional_ids: context_module_ids) do
          visible_modules = []

          # add modules visible to everyone
          modules_visible_to_all = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                   .find_modules_visible_to_everyone(course_ids:, user_ids:, context_module_ids:)
          visible_modules |= modules_visible_to_all

          # add modules visible to sections (and related module section overrides)
          modules_visible_to_sections = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                        .find_modules_visible_to_sections(course_ids:, user_ids:, context_module_ids:)
          visible_modules |= modules_visible_to_sections

          if assign_to_differentiation_tags_enabled?(course_ids)
            # add modules visible to groups (and related module group overrides)
            modules_visible_to_groups = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                        .find_modules_visible_to_groups(course_ids:, user_ids:, context_module_ids:)
            visible_modules |= modules_visible_to_groups
          end

          # add modules visible due to ADHOC overrides (and related module ADHOC overrides)
          modules_visible_to_adhoc_overrides = ModuleVisibility::Repositories::ModuleVisibleToStudentRepository
                                               .find_modules_visible_to_adhoc_overrides(course_ids:, user_ids:, context_module_ids:)
          visible_modules | modules_visible_to_adhoc_overrides
        end
      end

      def assign_to_differentiation_tags_enabled?(course_ids)
        return false if course_ids.blank?

        account_ids = Course.where(id: course_ids).distinct.pluck(:account_id).uniq
        accounts = Account.where(id: account_ids).to_a

        accounts.any? { |account| account.feature_enabled?(:assign_to_differentiation_tags) }
      end
    end
  end
end
