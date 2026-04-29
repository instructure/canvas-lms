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

module Services
  class Athena
    def self.developer_key
      client_id = config["oauth_client_id"]
      return nil if client_id.blank?

      DeveloperKey.find_cached(client_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def self.user_authenticated?(user)
      return false if user.nil?

      key = developer_key
      return false unless key

      Rails.cache.fetch(
        ["athena_user_authenticated", user.global_id, key.global_id],
        expires_in: 5.minutes
      ) do
        user.access_tokens.where(developer_key: key).active.exists?
      end
    end

    def self.launch_domain
      config["launch_domain"]
    end

    def self.launch_path
      config["launch_path"]
    end

    # Returns config safe to expose to the frontend via js_env.
    # Do not add secrets or sensitive values here.
    def self.public_app_config(user)
      {
        authenticated: user_authenticated?(user),
        launch_domain:,
        launch_path:
      }
    end

    class << self
      private

      Canvas::Reloader.on_reload do
        @config = nil
      end

      def config
        @config ||= YAML.safe_load(
          DynamicSettings.find(tree: :private)["athena.yml", failsafe: nil] || "{}"
        )
      end
    end
  end
end
