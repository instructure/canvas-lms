#
# Copyright (C) 2015 - present Instructure, Inc.
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

class EncryptGoogleDriveSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    PluginSetting.where(name: 'google_drive').each do |ps|
      # do a dance so that we don't delete the unencrypted copy yet
      ps.encrypt_settings
      ps.initialize_plugin_setting
      ps.settings[:client_secret] = ps.settings[:client_secret_dec]
      PluginSetting.where(id: ps).update_all(settings: ps.settings.to_yaml)
    end
  end
end
