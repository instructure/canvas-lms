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

module DataFixup
  module CreateLtiRegistrationsFromDeveloperKeys
    def self.run
      DeveloperKey.where(is_lti_key: true, lti_registration: nil).preload(:tool_configuration, :ims_registration).find_each do |developer_key|
        registration_values = {
          admin_nickname: developer_key.name,
          account_id: developer_key.account_id.presence || Account.site_admin.global_id,
          internal_service: developer_key.internal_service,
          name: developer_key.tool_configuration.configuration["title"],
          developer_key:,
          ims_registration: developer_key.ims_registration, # can be nil
          skip_lti_sync: true,
        }

        begin
          registration = ::Lti::Registration.create!(registration_values)

          developer_key.lti_registration = registration if registration
          developer_key.save!
        rescue => e
          Sentry.with_scope do |scope|
            scope.set_tags(developer_key_id: developer_key.global_id)
            scope.set_context("exception", { name: e.class.name, message: e.message })
            Sentry.capture_message("DataFixup#create_lti_registrations_from_developer_keys", level: :warning)
          end
        end
      end
    end
  end
end
