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

# == Schema Information
#
# Table name: plugin_settings
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     default(""), not null
#  settings   :text
#  created_at :datetime
#  updated_at :datetime
#
class PluginSetting < ActiveRecord::Base
  validates_uniqueness_of :name
  serialize :settings

  def self.settings_for_plugin(name, plugin=nil)
    if settings = PluginSetting.find_by_name(name.to_s)
      settings = settings.settings
    else
      plugin ||= Canvas::Plugin.find(name.to_s)
      raise Canvas::NoPluginError unless plugin
      settings = plugin.default_settings
    end
    
    settings
  end

end
