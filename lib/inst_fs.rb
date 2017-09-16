#
# Copyright (C) 2016 - present Instructure, Inc.
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

module InstFS
  class << self
    def enabled?
      Canvas::Plugin.find('inst_fs').enabled?
    end

    def app_host
      setting("app-host")
    end

    def jwt_secret
      setting("secret")
    end

    private
    def setting(key)
      Canvas::DynamicSettings.find(service: "inst-fs", default_ttl: 5.minutes)[key]
    rescue Imperium::TimeoutError => e
      Canvas::Errors.capture_exception(:inst_fs, e)
      nil
    end
  end
end
