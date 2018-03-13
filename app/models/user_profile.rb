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

class UserProfile < ActiveRecord::Base
  belongs_to :user

  delegate :short_name, :name, :asset_string, :opaque_identifier, :to => :user

  has_many :links, :class_name => 'UserProfileLink', :dependent => :destroy

  validates_length_of :title, :maximum => maximum_string_length, :allow_blank => true

  TAB_PROFILE, TAB_COMMUNICATION_PREFERENCES, TAB_FILES, TAB_EPORTFOLIOS,
    TAB_PROFILE_SETTINGS, TAB_OBSERVEES = *0..10

  BASE_TABS = [
    {
      id: TAB_COMMUNICATION_PREFERENCES,
      label: -> { I18n.t('#user_profile.tabs.notifications', "Notifications") },
      css_class: 'notifications',
      href: :communication_profile_path,
      no_args: true
    }.freeze,
    {
      id: TAB_FILES,
      label: -> { I18n.t('#tabs.files', "Files") },
      css_class: 'files',
      href: :files_path,
      no_args: true
    }.freeze,
    {
      id: TAB_PROFILE_SETTINGS,
      label: -> { I18n.t('#user_profile.tabs.settings', 'Settings') },
      css_class: 'profile_settings',
      href: :settings_profile_path,
      no_args: true
    }.freeze
  ].freeze

  set_policy do
    given do |user, account|
      return unless user
      user_roles = Lti::SubstitutionsHelper.new(account, account.root_account, user).all_roles
      user_roles.include?('urn:lti:instrole:ims/lis/Administrator')
    end
    can :view_lti_tool
  end

  def tabs_available(user=nil, opts={})
    @tabs ||= begin
      tabs = BASE_TABS.map do |tab|
        new_tab = tab.dup
        new_tab[:label] = tab[:label].call
        new_tab
      end
      insert_profile_tab(tabs, user, opts)
      insert_eportfolios_tab(tabs, user)
      insert_lti_tool_tabs(tabs, user, opts) if user && opts[:root_account]
      tabs = tabs.slice(0,2) if user&.fake_student?
      insert_observer_tabs(tabs, user)
      tabs
    end
  end

  private

  def insert_profile_tab(tabs, user, opts)
    if user && opts[:root_account] && opts[:root_account].enable_profiles?
      tabs.insert 1, {
        id: TAB_PROFILE,
        label: I18n.t('#user_profile.tabs.profile', "Profile"),
        css_class: 'profile',
        href: :profile_path,
        no_args: true
      }
    end
  end

  def insert_eportfolios_tab(tabs, user)
    if user.eportfolios_enabled?
      tabs << {
        id: TAB_EPORTFOLIOS,
        label:I18n.t('#tabs.eportfolios', "ePortfolios"),
        css_class: 'eportfolios',
        href: :dashboard_eportfolios_path,
        no_args: true
      }
    end
  end

  def insert_lti_tool_tabs(tabs, user, opts)
    tools = opts[:root_account].context_external_tools.active.having_setting('user_navigation')
    tabs.concat(
      Lti::ExternalToolTab.new(user, :user_navigation, tools, opts[:language]).
      tabs.
      find_all { |tab| should_keep_tab?(tab, user, opts[:root_account]) }
    )
  end

  def should_keep_tab?(tab, user, account)
    tab[:visibility] != 'admins' || self.grants_right?(user, account, :view_lti_tool)
  end

  def insert_observer_tabs(tabs, user)
    if user&.as_observer_observation_links&.active&.exists?
      tabs << {
        id: TAB_OBSERVEES,
        label: I18n.t('#tabs.observees', 'Observing'),
        css_class: 'observees',
        href: :observees_profile_path,
        no_args: true
      }
    end
  end
end

