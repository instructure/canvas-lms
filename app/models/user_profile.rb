# frozen_string_literal: true

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

  delegate :short_name, :name, :asset_string, :opaque_identifier, to: :user

  has_many :links, inverse_of: :user_profile, class_name: "UserProfileLink", dependent: :destroy

  validates :title,
            length: {
              maximum: maximum_string_length, too_long: "%{count} characters is the maximum allowed"
            },
            allow_blank: true
  validates :bio,
            length: {
              maximum: maximum_text_length, too_long: "%{count} characters is the maximum allowed"
            },
            allow_blank: true

  TAB_PROFILE,
  TAB_COMMUNICATION_PREFERENCES,
  TAB_FILES,
  TAB_EPORTFOLIOS,
  TAB_PROFILE_SETTINGS,
  TAB_OBSERVEES,
  TAB_QR_MOBILE_LOGIN,
  TAB_PAST_GLOBAL_ANNOUNCEMENTS,
  TAB_CONTENT_SHARES =
    *0..10

  BASE_TABS = [
    {
      id: TAB_COMMUNICATION_PREFERENCES,
      label: -> { I18n.t("#user_profile.tabs.notifications", "Notifications") },
      css_class: "notifications",
      href: :communication_profile_path,
      no_args: true
    }.freeze,
    {
      id: TAB_FILES,
      label: -> { I18n.t("#tabs.files", "Files") },
      css_class: "files",
      href: :files_path,
      no_args: true
    }.freeze,
    {
      id: TAB_PROFILE_SETTINGS,
      label: -> { I18n.t("#user_profile.tabs.settings", "Settings") },
      css_class: "profile_settings",
      href: :settings_profile_path,
      no_args: true
    }.freeze
  ].freeze

  set_policy do
    given do |user, account|
      return unless user

      user_roles = Lti::SubstitutionsHelper.new(account, account.root_account, user).all_roles
      user_roles.include?("urn:lti:instrole:ims/lis/Administrator")
    end
    can :view_lti_tool
  end

  def tabs_available(user = nil, opts = {})
    @tabs ||=
      begin
        tabs =
          BASE_TABS.map do |tab|
            new_tab = tab.dup
            new_tab[:label] = tab[:label].call
            new_tab
          end
        insert_profile_tab(tabs, user, opts)
        insert_eportfolios_tab(tabs, user)
        insert_content_shares_tab(tabs, user, opts)
        insert_lti_tool_tabs(tabs, user, opts) if user && opts[:root_account]
        tabs = tabs.slice(0, 2) if user&.fake_student?
        insert_observer_tabs(tabs, user)
        insert_qr_mobile_login_tab(tabs, user, opts)
        insert_past_global_announcements(tabs, user, opts)
        tabs
      end
  end

  private

  def insert_profile_tab(tabs, user, opts)
    if user && opts[:root_account] && opts[:root_account].enable_profiles?
      tabs.insert 1,
                  {
                    id: TAB_PROFILE,
                    label: I18n.t("#user_profile.tabs.profile", "Profile"),
                    css_class: "profile",
                    href: :profile_path,
                    no_args: true
                  }
    end
  end

  def insert_eportfolios_tab(tabs, user)
    if user.eportfolios_enabled?
      tabs <<
        {
          id: TAB_EPORTFOLIOS,
          label: I18n.t("#tabs.eportfolios", "ePortfolios"),
          css_class: "eportfolios",
          href: :dashboard_eportfolios_path,
          no_args: true
        }
    end
  end

  def insert_content_shares_tab(tabs, user, _opts)
    if user&.can_view_content_shares?
      tabs <<
        {
          id: TAB_CONTENT_SHARES,
          label: I18n.t("Shared Content"),
          css_class: "content_shares",
          href: :content_shares_profile_path,
          no_args: true
        }
    end
  end

  def insert_lti_tool_tabs(tabs, user, opts)
    tools = Lti::ContextToolFinder.new(opts[:root_account], type: :user_navigation).all_tools_scope_union.to_unsorted_array
                                  .select { |t| t.permission_given?(:user_navigation, user, opts[:root_account]) }
    tabs.concat(
      Lti::ExternalToolTab.new(user, :user_navigation, tools, opts[:language]).tabs
        .find_all { |tab| show_lti_tab?(tab, user, opts[:root_account]) }
    )
  end

  def show_lti_tab?(tab, user, account)
    tab[:visibility] != "admins" || grants_right?(user, account, :view_lti_tool)
  end

  def insert_observer_tabs(tabs, user)
    if user&.as_observer_observation_links&.active&.exists?
      tabs <<
        {
          id: TAB_OBSERVEES,
          label: I18n.t("#tabs.observees", "Observing"),
          css_class: "observees",
          href: :observees_profile_path,
          no_args: true
        }
    end
  end

  def insert_qr_mobile_login_tab(tabs, user, opts)
    if user && instructure_misc_plugin_available? && opts[:root_account]&.mobile_qr_login_is_enabled?
      tabs <<
        {
          id: TAB_QR_MOBILE_LOGIN,
          label: I18n.t("#tabs.qr_mobile_login", "QR for Mobile Login"),
          css_class: "qr_mobile_login",
          href: :qr_mobile_login_path,
          no_args: true
        }
    end
  end

  def insert_past_global_announcements(tabs, user, _opts)
    if user
      tabs <<
        {
          id: TAB_PAST_GLOBAL_ANNOUNCEMENTS,
          label: I18n.t("#tabs.past_global_announcements", "Global Announcements"),
          css_class: "past_global_announcements",
          href: :account_notifications_path,
          no_args: { include_past: true }
        }
    end
  end
end

def instructure_misc_plugin_available?
  Object.const_defined?(:InstructureMiscPlugin)
end
private :instructure_misc_plugin_available?
