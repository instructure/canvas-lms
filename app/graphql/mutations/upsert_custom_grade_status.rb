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
  class UpsertCustomGradeStatus < BaseMutation
    argument :color, String, required: true
    argument :id, ID, required: false
    argument :name, String, required: true
    field :custom_grade_status, Types::CustomGradeStatusType, null: true

    def resolve(input:)
      raise GraphQL::ExecutionError, "custom gradebook statuses feature flag is disabled" unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)

      root_account = context[:domain_root_account]
      custom_grade_status = input[:id] ? root_account.custom_grade_statuses.active.find(input[:id]) : CustomGradeStatus.new(root_account:, created_by: current_user)

      required_permission = custom_grade_status.new_record? ? :create : :update
      unless custom_grade_status.grants_right?(current_user, session, required_permission)
        raise GraphQL::ExecutionError, I18n.t("Insufficient permissions")
      end

      if custom_grade_status.new_record?
        InstStatsd::Statsd.increment("custom_grade_status.graphql.create")
      else
        InstStatsd::Statsd.increment("custom_grade_status.graphql.update")
      end

      if custom_grade_status.update(name: input[:name], color: input[:color])
        { custom_grade_status: }
      else
        errors_for(custom_grade_status)
      end
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "custom grade status not found"
    end
  end
end
