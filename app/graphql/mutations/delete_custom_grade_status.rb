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
  class DeleteCustomGradeStatus < BaseMutation
    argument :id, ID, required: true
    field :custom_grade_status_id, ID, null: true

    def resolve(input:)
      raise GraphQL::ExecutionError, "custom gradebook statuses feature flag is disabled" unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)

      custom_grade_status = CustomGradeStatus.active.find(input[:id])

      unless custom_grade_status.grants_right?(current_user, session, :delete)
        raise GraphQL::ExecutionError, I18n.t("Insufficient permissions")
      end

      context[:deleted_models] ||= {}
      context[:deleted_models][:custom_grade_status] = custom_grade_status
      custom_grade_status_id = custom_grade_status.id
      custom_grade_status.deleted_by = current_user
      custom_grade_status.destroy

      InstStatsd::Statsd.increment("custom_grade_status.graphql.delete")

      { custom_grade_status_id: }
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "custom grade status not found"
    end

    def self.custom_grade_status_id_log_entry(_entry, context)
      context[:deleted_models][:custom_grade_status]
    end
  end
end
