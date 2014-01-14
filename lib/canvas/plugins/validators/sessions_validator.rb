#
# Copyright (C) 2011 Instructure, Inc.
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

module Canvas::Plugins::Validators::SessionsValidator
  def self.validate(settings, plugin_setting)
    timeout = settings["session_timeout"].to_f.minutes
    if timeout < 20.minutes
      plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.login_expiration_minimum', 'Session expiration must be 20 minutes or greater'))
    else 
      settings
    end
  end
end
