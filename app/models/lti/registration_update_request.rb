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

class Lti::RegistrationUpdateRequest < ApplicationRecord
  belongs_to :lti_registration, class_name: "Lti::Registration"
  belongs_to :root_account, class_name: "Account"
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  self.table_name = "lti_registration_update_requests"

  scope :active, -> { where(accepted_at: nil, rejected_at: nil) }
  scope :pending, -> { active }

  def applied?
    accepted_at.present?
  end

  def rejected?
    rejected_at.present?
  end

  def pending?
    accepted_at.blank? && rejected_at.blank?
  end

  def as_json(options = {})
    super({ include_root: false }.merge(options)).merge(
      {
        # TODO: switch this on type of underlying registration
        internal_lti_configuration:
          if lti_ims_registration
            Lti::IMS::Registration.to_internal_lti_configuration(lti_ims_registration)
          else
            Schemas::InternalLtiConfiguration.from_lti_configuration(canvas_lti_configuration)
          end
      }
    )
  end

  # Returns true if this is the most recent update request for the registration, false otherwise.
  # This is used to determine whether or not to apply an update request when it is accepted,
  # as well as whether or not to show an update request as pending in the UI.
  def most_recent?
    return true unless Account.site_admin.feature_enabled?(:lti_dr_registrations_update)

    most_recent = Lti::RegistrationUpdateRequest
                  .where(lti_registration_id:)
                  .order(created_at: :desc)
                  .first

    most_recent&.id == id
  end
end
