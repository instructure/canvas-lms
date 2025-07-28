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
        next if (developer_key.account_id || 0) > Shard::IDS_PER_SHARD

        lti_registration = ::Lti::Registration.create!(
          {
            admin_nickname: developer_key.name,
            account_id: developer_key.account_id.presence || Account.site_admin.global_id,
            internal_service: developer_key.internal_service,
            name: developer_key.tool_configuration.internal_lti_configuration[:title],
            ims_registration: developer_key.ims_registration, # can be nil
          }
        )

        # including these models in the create params above causes these problems:
        # 1. DeveloperKey has an after_update that will try to update the Lti::Registration,
        # which is not necessary.
        # 2. any DeveloperKeys or ToolConfigurations with invalid data (which absolutely exist
        # in production) won't save the association with the registration if Rails handles the save.
        developer_key.update_column(:lti_registration_id, lti_registration.id)
        developer_key.referenced_tool_configuration.update_column(:lti_registration_id, lti_registration.id)
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
