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

# OAuth parameters specific to any client identifier instead
# of being tied to a DeveloperKey.
class OAuthClientConfig < ActiveRecord::Base
  include Canvas::SoftDeletable

  # required to use `type` as a column name
  self.inheritance_column = nil

  CLIENT_TYPES = %w[product client_id lti_advantage service_user_key token user tool session ip].freeze
  # Not all identifier types are allowed to override throttling parameters
  CUSTOM_THROTTLE_CLIENT_TYPES = %w[product client_id lti_advantage service_user_key token].freeze

  belongs_to :root_account, class_name: "Account", inverse_of: :oauth_client_configs, optional: false
  belongs_to :updated_by, class_name: "User", optional: false

  validates :identifier, presence: true, uniqueness: { scope: [:root_account_id, :type] }
  validates :type, presence: true, inclusion: { in: CLIENT_TYPES }
  validate :custom_throttle_params_only_for_allowed_types

  scope :for_throttling, -> { where(type: CUSTOM_THROTTLE_CLIENT_TYPES) }

  def custom_throttle_params_only_for_allowed_types
    return if CUSTOM_THROTTLE_CLIENT_TYPES.include?(type)

    throttle_attributes = %i[maximum high_water_mark outflow upfront_cost]

    if throttle_attributes.any? { |attr| send("throttle_#{attr}").present? }
      errors.add(:type, "custom throttle parameters can only be set for client types: #{CUSTOM_THROTTLE_CLIENT_TYPES.join(", ")}")
    end
  end
end
