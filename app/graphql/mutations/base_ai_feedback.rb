# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Abstract base mutation for submitting AI feedback via CedarClient.
# Do not register this mutation directly in mutation_type.rb.
# Subclasses must implement check_feature_and_permissions! and feature_slug.
class Mutations::BaseAiFeedback < Mutations::BaseMutation
  argument :comment, String, required: false
  argument :feedback_type, Types::AiFeedbackTypeEnum, required: true
  argument :response_id, String, required: true

  field :response_id, String, null: true

  def resolve(input:)
    root_account_uuid = check_feature_and_permissions!(input)

    result = CedarClient.submit_feedback(
      response_id: input[:response_id],
      feedback_type: input[:feedback_type],
      feature_slug:,
      root_account_uuid:,
      current_user:,
      comment: input[:comment]
    )

    { response_id: result.response_id }
  rescue GraphQL::ExecutionError => e
    Rails.logger.error("[#{self.class.name} GraphQL ExecutionError] #{e.message}")
    raise e
  rescue => e
    Rails.logger.error("[#{self.class.name} ERROR] #{e.message}")
    raise GraphQL::ExecutionError, I18n.t("An unexpected error occurred while submitting feedback.")
  end

  private

  # Subclasses must perform feature flag and permission checks here,
  # then return the root_account_uuid string.
  def check_feature_and_permissions!(_input)
    raise NotImplementedError, "#{self.class} must implement check_feature_and_permissions!"
  end

  # Subclasses must return the Cedar feature slug string.
  def feature_slug
    raise NotImplementedError, "#{self.class} must implement feature_slug"
  end
end
