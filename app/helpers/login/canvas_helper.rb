#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Login::CanvasHelper
  def session_timeout_enabled?
    PluginSetting.settings_for_plugin 'sessions'
  end

  def reg_link_data(auth_type)
    template = auth_type.present? ? "#{auth_type.downcase}Dialog" : "newParentDialog"
    path = auth_type.present? ? external_auth_validation_path : users_path
    {template: template, path: path}
  end
end
