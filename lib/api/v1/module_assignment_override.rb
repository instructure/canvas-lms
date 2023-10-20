# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
#

module Api::V1::ModuleAssignmentOverride
  include Api::V1::Json

  FIELDS = %i[id context_module_id title].freeze

  def module_assignment_overrides_json(overrides, user)
    adhoc_overrides = overrides.select { |override| override.set_type == "ADHOC" }
    visible_users_ids = ::AssignmentOverride.visible_enrollments_for(overrides.compact, user).select(:user_id)
    if adhoc_overrides.any? { |override| !override.preloaded_student_ids }
      AssignmentOverrideApplicator.preload_student_ids_for_adhoc_overrides(adhoc_overrides, visible_users_ids)
    end
    user_names = User.where(id: adhoc_overrides.flat_map(&:preloaded_student_ids)).pluck(:id, :name).to_h
    overrides.map { |override| module_assignment_override_json(override, user_names) }
  end

  private

  def module_assignment_override_json(override, user_names)
    api_json(override, @current_user, session, only: FIELDS).tap do |json|
      case override.set_type
      when "ADHOC"
        json[:students] = override.preloaded_student_ids.map { |user_id| { id: user_id, name: user_names[user_id] } }
      when "CourseSection"
        json[:course_section] = { id: override.set.id, name: override.set.name }
      end
    end
  end
end
