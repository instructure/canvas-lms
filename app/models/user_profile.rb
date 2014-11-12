#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

class UserProfile < ActiveRecord::Base
  belongs_to :user

  delegate :short_name, :name, :asset_string, :opaque_identifier, :to => :user

  attr_accessible :title, :bio

  has_many :links, :class_name => 'UserProfileLink', :dependent => :destroy

  EXPORTABLE_ATTRIBUTES = [:id, :bio, :title, :user_id]
  EXPORTABLE_ASSOCIATIONS = [:user, :links]

  validates_length_of :title, :maximum => maximum_string_length, :allow_blank => true

  TAB_PROFILE, TAB_COMMUNICATION_PREFERENCES, TAB_FILES, TAB_EPORTFOLIOS,
    TAB_HOME, TAB_PROFILE_SETTINGS, TAB_OBSERVEES = *0..10

  def tabs_available(user=nil, opts={})
    unless @tabs
      @tabs = [
        { :id => TAB_HOME, :label => I18n.t('#tabs.home', "Home"), :css_class => 'home', :href => :dashboard_path, :no_args => true },
        { :id => TAB_COMMUNICATION_PREFERENCES, :label => I18n.t('#user_profile.tabs.notifications', "Notifications"), :css_class => 'notifications', :href => :communication_profile_path, :no_args => true },
        { :id => TAB_FILES, :label => I18n.t('#tabs.files', "Files"), :css_class => 'files', :href => :files_path, :no_args => true },
        { :id => TAB_PROFILE_SETTINGS, :label => I18n.t('#user_profile.tabs.settings', 'Settings'), :css_class => 'profile_settings', :href => :settings_profile_path, :no_args => true },
      ]
      if user && opts[:root_account] && opts[:root_account].enable_profiles?
        @tabs.insert 1, {:id => TAB_PROFILE, :label => I18n.t('#user_profile.tabs.profile', "Profile"), :css_class => 'profile', :href => :user_profile_path, :args => [user.id]}
      end

      @tabs << { :id => TAB_EPORTFOLIOS, :label => I18n.t('#tabs.eportfolios', "ePortfolios"), :css_class => 'eportfolios', :href => :dashboard_eportfolios_path, :no_args => true } if user.eportfolios_enabled?
      if user && opts[:root_account]
        opts[:root_account].context_external_tools.active.having_setting('user_navigation').each do |tool|
          @tabs << {
            :id => tool.asset_string,
            :label => tool.label_for(:user_navigation, opts[:language]),
            :css_class => tool.asset_string,
            :href => :user_external_tool_path,
            :args => [user.id, tool.id]
          }
        end
      end
      if user && user.fake_student?
        @tabs = @tabs.slice(0,2)
      end

      if user && user.user_observees.exists?
        @tabs << { :id => TAB_OBSERVEES, :label => I18n.t('#tabs.observees', 'Observing'), :css_class => 'observees', :href => :observees_profile_path, :no_args => true }
      end
    end
    @tabs
  end
end

