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

module DataFixup::Lti::BackfillPortfolioTargetLinkUri
  def self.run
    Lti::IMS::Registration
      .active
      .where("NOT (lti_tool_configuration ? 'target_link_uri')")
      .where("lti_tool_configuration->>'domain' LIKE '%.portfolio.instructure.com'")
      .find_each do |registration|
        config = registration.lti_tool_configuration
        target_link_uri = config.dig("messages", 0, "target_link_uri")

        unless target_link_uri
          Sentry.with_scope do |scope|
            scope.set_tags(lti_ims_registration_id: registration.global_id)
            Sentry.capture_message("DataFixup#backfill_portfolio_target_link_uri: missing target_link_uri in messages", level: :warning)
          end
          next
        end

        config["target_link_uri"] = target_link_uri
        registration.update!(lti_tool_configuration: config)
      rescue => e
        Sentry.with_scope do |scope|
          scope.set_tags(lti_ims_registration_id: registration.global_id)
          scope.set_context("exception", { name: e.class.name, message: e.message })
          Sentry.capture_message("DataFixup#backfill_portfolio_target_link_uri", level: :warning)
        end
      end
  end
end
