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

module PageViews
  class Configuration
    attr_reader :uri

    def self.configured?
      ConfigFile.load("pv5").present?
    end

    def initialize(region: nil)
      config = ConfigFile.load("pv5")
      raise Common::ConfigurationError, "PV5 is not configured for this environment" unless config.present?

      regional_config = get_regional_config(config, region) || {}
      @uri = URI.parse(regional_config["uri"] || config["uri"])
    rescue URI::InvalidURIError => e
      raise Common::ConfigurationError, "Invalid URI in pv5 config: #{e.message}"
    end

    private

    def get_regional_config(config, region)
      return unless config["regions"].is_a?(Hash)

      regional_config = config["regions"][region]
      return unless regional_config.is_a?(Hash)

      regional_config
    end
  end
end
