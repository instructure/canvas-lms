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

    def initialize
      config = ConfigFile.load("pv5")
      raise Common::ConfigurationError, "Missing or invalid 'uri' in pv5 config file" unless config["uri"].is_a?(String) && !config["uri"].strip.empty?

      @uri = URI.parse(config["uri"])
    end
  end
end
