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

# @API Temporary Enrollment Pairings
#
# @model TemporaryEnrollmentPairing
#     {
#       "id": "TemporaryEnrollmentPairing",
#       "description": "A pairing unique to that enrollment period given to a recipient of that temporary enrollment.",
#       "properties": {
#         "id": {
#           "description": "the ID of the temporary enrollment pairing",
#           "example": 1,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current status of the temporary enrollment pairing",
#           "example": "active",
#           "type": "string"
#         }
#       }
#     }
#
class TemporaryEnrollmentPairingsApiController < ApplicationController
  before_action :require_feature_flag
  before_action :authorize_action
  before_action :load_temporary_enrollment_pairing, only: %i[show destroy]

  include GranularPermissionEnforcement

  # @API List temporary enrollment pairings
  # Returns the list of temporary enrollment pairings for a root account.
  #
  # @returns [TemporaryEnrollmentPairing]
  #
  def index
    @temporary_enrollment_pairings = @domain_root_account.temporary_enrollment_pairings.order(:created_at)
    render json: @temporary_enrollment_pairing.as_json
  end

  # @API Get a single temporary enrollment pairing
  # Returns the temporary enrollment pairing with the given id.
  #
  # @returns TemporaryEnrollmentPairing
  #
  def show
    render json: @temporary_enrollment_pairing.as_json
  end

  # @API New TemporaryEnrollmentPairing
  # Initialize an unsaved Temporary Enrollment Pairing.
  #
  # @returns TemporaryEnrollmentPairing
  #
  def new
    @temporary_enrollment_pairing = TemporaryEnrollmentPairing.new(root_account: @domain_root_account)
    render json: @temporary_enrollment_pairing.as_json
  end

  # @API Create Temporary Enrollment Pairing
  # Create a Temporary Enrollment Pairing.
  #
  # @argument workflow_state [String]
  #   The workflow state of the temporary enrollment pairing.
  #
  # @argument ending_enrollment_state [String, "deleted"|"completed"|"inactive"]
  #   The ending enrollment state to be given to each associated enrollment
  #   when the enrollment period has been reached. Defaults to "deleted" if no value is given.
  #   Accepted values are "deleted", "completed", and "inactive".
  #
  # @returns TemporaryEnrollmentPairing
  #
  def create
    @temporary_enrollment_pairing = @domain_root_account.temporary_enrollment_pairings
                                                        .build(temporary_enrollment_pairing_params)
    @temporary_enrollment_pairing.created_by = @current_user

    unless @temporary_enrollment_pairing&.ending_enrollment_state.in?(%w[completed inactive])
      @temporary_enrollment_pairing.ending_enrollment_state = "deleted"
    end

    if @temporary_enrollment_pairing.save
      render json: @temporary_enrollment_pairing.as_json, status: :created
    else
      render json: { success: false, errors: @temporary_enrollment_pairing.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  # @API Delete Temporary Enrollment Pairing
  # Delete a temporary enrollment pairing
  #
  # @returns TemporaryEnrollmentPairing
  #
  def destroy
    @temporary_enrollment_pairing.workflow_state = "deleted"
    @temporary_enrollment_pairing.deleted_by = @current_user

    if @temporary_enrollment_pairing.save
      head :no_content
    end
  end

  private

  def authorize_action
    account = api_find(Account.active, params[:account_id])

    enforce_granular_permissions(
      account,
      overrides: [],
      actions: {
        index: RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS,
        show: RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS,
        new: RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS,
        create: [:temporary_enrollments_add],
        destroy: [:temporary_enrollments_delete]
      }
    )
  end

  def require_feature_flag
    not_found unless @domain_root_account.feature_enabled?(:temporary_enrollments)
  end

  def load_temporary_enrollment_pairing
    @temporary_enrollment_pairing = @domain_root_account.temporary_enrollment_pairings.find(params[:id])
  end

  def temporary_enrollment_pairing_params
    # account_id is inferred from the path, and format returned is always json
    params.except(:format, :account_id).permit(:workflow_state, :ending_enrollment_state)
  end
end
