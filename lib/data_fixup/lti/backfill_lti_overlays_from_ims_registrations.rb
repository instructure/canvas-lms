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

module DataFixup::Lti::BackfillLtiOverlaysFromIMSRegistrations
  def self.run
    Lti::IMS::Registration.preload(:lti_registration, :developer_key).find_each do |ims_registration|
      overlay_data = Schemas::Lti::IMS::RegistrationOverlay.to_lti_overlay(ims_registration.registration_overlay)

      Lti::Overlay.create!(
        registration: ims_registration.lti_registration || ims_registration.developer_key.lti_registration,
        account: ims_registration.lti_registration&.account || ims_registration.developer_key.account,
        data: overlay_data,
        updated_by: nil
      )
    rescue
      Sentry.configure_scope do |scope|
        scope.set_context(
          "DataFixup.backfill_lti_overlays",
          {
            ims_registration_global_id: ims_registration.global_id,
          }
        )
      end
      raise
    end
  end
end
