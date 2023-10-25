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
module Mutations
  class SetOverrideStatus < BaseMutation
    argument :custom_grade_status_id, ID, required: false, default_value: nil
    argument :enrollment_id, ID, required: true
    argument :grading_period_id, ID, required: false, default_value: nil
    field :grades, Types::GradesType, null: true

    def resolve(input:)
      raise GraphQL::ExecutionError, "custom gradebook statuses feature flag is disabled" unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)

      score = score(input:)
      unless score.grants_right?(current_user, session, :update_custom_status)
        raise GraphQL::ExecutionError, I18n.t("Insufficient permissions")
      end

      if score.update(custom_grade_status: custom_grade_status(input:))
        InstStatsd::Statsd.increment("custom_grade_status.applied_to.final_grade")
        { grades: score }
      else
        errors_for(score)
      end
    rescue ActiveRecord::RecordNotFound => e
      raise GraphQL::ExecutionError, "#{e.model} not found"
    end

    private

    def score(input:)
      Score.find_by!(
        assignment_group_id: nil,
        course_score: input[:grading_period_id].blank?,
        enrollment_id: input[:enrollment_id],
        grading_period_id: input[:grading_period_id],
        root_account_id: context[:domain_root_account].id
      )
    end

    def custom_grade_status(input:)
      id = input[:custom_grade_status_id]

      return nil if id.blank?

      context[:domain_root_account].custom_grade_statuses.active.find(id)
    end
  end
end
