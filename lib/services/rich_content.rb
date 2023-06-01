# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Services
  class RichContent
    def self.env_for(user: nil, domain: nil, real_user: nil, context: nil)
      env_hash = service_settings.dup
      if user && domain
        begin
          env_hash[:JWT] = CanvasSecurity::ServicesJwt.for_user(
            domain,
            user,
            context:,
            real_user:,
            workflows: [:rich_content, :ui],
            # TODO: remove this once we teach the rcs to consume the asymmetric ones
            symmetric: true
          )
        rescue Canvas::Security::InvalidJwtKey => e
          Canvas::Errors.capture_exception(:jwt, e)
          env_hash[:JWT] = "InvalidJwtKey"
        end
      end

      # TODO: Remove once rich content service pull from jwt
      env_hash[:RICH_CONTENT_CAN_UPLOAD_FILES] = (
        user &&
        context &&
        context.grants_right?(user, :manage_files_add)
      ) || false

      env_hash[:RICH_CONTENT_CAN_EDIT_FILES] = (
        user &&
        context &&
        context.grants_right?(user, :manage_files_edit)
      ) || false

      env_hash
    end

    class << self
      private

      def service_settings
        settings = DynamicSettings.find("rich-content-service", default_ttl: 5.minutes)
        {
          RICH_CONTENT_APP_HOST: settings["app-host", failsafe: "error"]
        }
      end
    end
  end
end
