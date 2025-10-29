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
#

module Services
  class PlatformServiceGradebook
    def self.overrides
      config.fetch("overrides", {})
    end

    def self.graphql_usage_rate
      rate = config.fetch("graphql_usage_rate", 0)
      return 0 unless rate.is_a?(Numeric)

      rate.clamp(0, 100)
    end

    def self.use_graphql?(global_account_id, global_course_id)
      course_override = overrides&.dig("course", global_course_id)
      return !!course_override unless course_override.nil?

      account_override = overrides&.dig("account", global_account_id)
      return !!account_override unless account_override.nil?

      graphql_usage_rate > rand(0.0...100.0)
    end

    class << self
      private

      def config
        @config ||= begin
          yaml_content = DynamicSettings.find(tree: :private)["platform_service_gradebook.yml", failsafe: nil] || "{}"
          parsed = YAML.safe_load(yaml_content)
          parsed.is_a?(Hash) ? parsed : {}
        rescue
          {}
        end
      end
    end
  end
end
