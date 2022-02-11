# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

module SentryExtensions
  class Settings
    def self.disabled?
      Canvas::Plugin.value_to_boolean(get("sentry_disabled", "false"))
    end

    def self.settings
      @sentry_settings ||= ConfigFile.load("sentry")

      @sentry_settings.presence || {}
    end

    def self.get(name, default = nil)
      settings[name.to_sym] || Setting.get(name, default)
    rescue PG::ConnectionBad
      default
    end

    def self.reset_settings
      @sentry_settings = nil
    end
  end
end
