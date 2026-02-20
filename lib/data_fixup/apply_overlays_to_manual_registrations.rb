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

module DataFixup
  # TEMPORARY: This data fixup applies existing overlays to manual registrations.
  # After we disable the old developer keys page, we can remove this code along with
  # the temporary changes that make manual registrations edit directly instead of using overlays.
  class ApplyOverlaysToManualRegistrations < CanvasOperations::DataFixup
    self.mode = :individual_record
    self.progress_tracking = false

    scope do
      # Find all registrations that:
      # 1. Have a manual_configuration (are manual registrations, not dynamic)
      # 2. Have at least one overlay (checked in process_record)
      ::Lti::Registration.joins(:manual_configuration)
                         .preload(:manual_configuration, :lti_overlays)
    end

    def process_record(registration)
      # Get the overlay for the registration's root account
      overlay = registration.lti_overlays.find { |o| o.account_id == registration.account_id }

      return if overlay.blank? || overlay.data.blank?

      # Get the current internal configuration from the manual configuration
      tool_config = registration.manual_configuration
      current_config = tool_config.internal_lti_configuration

      # Apply the overlay to the configuration (additive: true for manual configs)
      merged_config = ::Lti::Overlay.apply_to(overlay.data, current_config, additive: true)

      # Update the tool configuration with the merged config
      # No need to propagate to external tools - they already have the overlaid config
      ::Lti::ToolConfiguration.suspend_callbacks(:update_external_tools!) do
        tool_config.update!(
          title: merged_config[:title],
          description: merged_config[:description],
          domain: merged_config[:domain],
          custom_fields: merged_config[:custom_fields],
          scopes: merged_config[:scopes],
          target_link_uri: merged_config[:target_link_uri],
          oidc_initiation_url: merged_config[:oidc_initiation_url],
          public_jwk_url: merged_config[:public_jwk_url],
          public_jwk: merged_config[:public_jwk],
          redirect_uris: merged_config[:redirect_uris],
          privacy_level: merged_config[:privacy_level],
          launch_settings: merged_config[:launch_settings],
          placements: merged_config[:placements]
        )
      end

      # Delete the overlay since it's now been merged into the base configuration
      # We keep this for historical purposes initially, but could delete later
      overlay.update!(data: {})

      log_message("Applied overlay to manual registration #{registration.global_id}")
    rescue ActiveRecord::RecordInvalid => e
      log_message("Failed to apply overlay to registration #{registration.global_id}: #{e}")
    rescue => e
      log_message("Unexpected error for registration #{registration.global_id}: #{e}")
    end
  end
end
