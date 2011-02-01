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

class UserProfile
  attr_accessor :user
  def initialize(user)
    @user = user
  end
  
  def short_name
    @user.short_name
  end
  
  def name
    @user.name
  end
  
  def asset_string
    @user.asset_string
  end
  
  TAB_PROFILE = 0
  TAB_COMMUNICATION_PREFERENCES = 1
  TAB_FILES = 2
  TAB_EPORTFOLIOS = 3
  TAB_HOME = 4
  def tabs_available(user=nil, opts={})
    @tabs ||= [
      { :id => TAB_HOME, :label => "Home", :href => :dashboard_path,             :no_args => true },
      { :id => TAB_PROFILE, :label => "Profile", :href => :profile_path,               :no_args => true },
      { :id => TAB_COMMUNICATION_PREFERENCES, :label => "Communication Preferences", :href => :communication_profile_path, :no_args => true },
      { :id => TAB_FILES, :label => "Files", :href => :dashboard_files_path,       :no_args => true },
      { :id => TAB_EPORTFOLIOS, :label => "ePortfolios", :href => :dashboard_eportfolios_path, :no_args => true }
    ]
  end
end