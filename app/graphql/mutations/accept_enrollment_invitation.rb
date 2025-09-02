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
#

module Mutations
  class AcceptEnrollmentInvitation < BaseMutation
    argument :enrollment_uuid, String, required: true

    field :enrollment, Types::EnrollmentType, null: true
    field :success, Boolean, null: false

    def resolve(input:, **)
      user = context[:current_user]
      raise GraphQL::ExecutionError, I18n.t("Must be logged in") unless user

      enrollment = Enrollment.where(uuid: input[:enrollment_uuid]).first
      raise GraphQL::ExecutionError, I18n.t("Enrollment invitation not found") unless enrollment

      # Verify the enrollment belongs to the current user
      raise GraphQL::ExecutionError, I18n.t("Unauthorized") unless enrollment.user == user

      # Verify the enrollment is in invited state
      raise GraphQL::ExecutionError, I18n.t("Enrollment is not in invited state") unless enrollment.invited?

      begin
        if enrollment.accept!
          {
            enrollment:,
            success: true
          }
        else
          {
            enrollment: nil,
            success: false,
            errors: [{ message: I18n.t("Failed to accept enrollment invitation") }]
          }
        end
      rescue => e
        {
          enrollment: nil,
          success: false,
          errors: [{ message: e.message }]
        }
      end
    end
  end
end
