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
#
module Mutations
  class SetRubricSelfAssessment < BaseMutation
    argument :assignment_id, ID, required: true
    argument :rubric_self_assessment_enabled, Boolean, required: true

    def resolve(input:)
      assignment = Assignment.find(input[:assignment_id])
      rubric_association = assignment.rubric_association

      unless Rubric.rubric_self_assessment_enabled?(assignment.course)
        raise GraphQL::ExecutionError, "enhanced_rubrics, rubric_self_assesment and assignments_2_student must be enabled"
      end

      unless assignment.active_rubric_association?
        raise GraphQL::ExecutionError, I18n.t("Rubric Association not found")
      end

      unless rubric_association.grants_right?(current_user, session, :update)
        raise GraphQL::ExecutionError, I18n.t("Insufficient permissions")
      end

      if assignment.has_group_category?
        raise GraphQL::ExecutionError, I18n.t("Cannot set rubric self assessment for group assignments")
      end

      unless assignment.can_update_rubric_self_assessment?
        raise GraphQL::ExecutionError, I18n.t("Assignment has self assessments or due date has passed")
      end

      rubric_self_assessment_enabled = input[:rubric_self_assessment_enabled]

      if assignment.update(rubric_self_assessment_enabled:)
        { rubric_self_assessment_enabled: }
      else
        errors_for(assignment)
      end
    rescue ActiveRecord::RecordNotFound => e
      raise GraphQL::ExecutionError, "#{e.model} not found"
    end
  end
end
