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
    Lti::IMS::Registration.preload(:developer_key, lti_registration: :lti_overlays).find_each do |ims_registration|
      next if ims_registration.lti_registration.lti_overlays.any?

      overlay_data = Schemas::Lti::IMS::RegistrationOverlay.to_lti_overlay(ims_registration.registration_overlay)

      Lti::Overlay.create!(
        registration: ims_registration.lti_registration || ims_registration.developer_key.lti_registration,
        account: ims_registration.lti_registration&.account || ims_registration.developer_key.account,
        data: overlay_data,
        updated_by: nil
      )
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(ims_registration_global_id: ims_registration.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("Datafixup.backfill_lti_overlays", level: :warning)
      end
    end
  end
end
