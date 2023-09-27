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
  module Settings
    class << self
      def settings
        @sentry_settings ||= ConfigFile.load("sentry")

        @sentry_settings.presence || {}
      end

      def get(name, default = nil, skip_cache: false)
        settings[name.to_sym] || Setting.get(name, default, skip_cache:)
      rescue PG::ConnectionBad
        default
      end

      def reset_settings
        @sentry_settings = nil
      end
    end
  end
end
