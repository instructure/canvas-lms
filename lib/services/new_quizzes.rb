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

module Services
  class NewQuizzes
    def self.launch_url
      config["launch_url"]
    end

    def self.ui_version
      url = launch_url
      return nil unless url

      uri = URI.parse(url)
      path_segments = uri.path.split("/").reject(&:empty?)

      # Expected format: /<version>/remoteEntry.js
      unless path_segments.length >= 2 && path_segments.last == "remoteEntry.js"
        raise URI::InvalidURIError, "Launch URL does not match expected format: /<version>/remoteEntry.js"
      end

      path_segments[-2]
    rescue URI::InvalidURIError => e
      Rails.logger.error("Failed to parse New Quizzes launch URL: #{e.message}")
      nil
    end

    class << self
      private

      def config
        @config ||= YAML.safe_load(DynamicSettings.find(tree: :private)["new_quizzes.yml", failsafe: nil] || "{}")
      end
    end
  end
end
