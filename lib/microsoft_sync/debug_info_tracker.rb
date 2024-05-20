# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# Methods to record debuging info when running the sync job, and a method to
# fetch/decode/localize that debug info for use in the UI.

module MicrosoftSync
  class DebugInfoTracker
    def initialize(ms_group)
      @ms_group = ms_group
    end

    # returns an array of objects {localized msg, user_ids} so user_ids can be
    # shown separately in the UI
    # localizes the message in the current locale using the message and the
    # interpolation data stored previously in the DB
    def self.localize_debug_info(debug_info)
      debug_info&.map(&:symbolize_keys)&.map do |info|
        data = info.delete(:data)&.symbolize_keys || {}
        info[:msg] = I18n.t!(info[:msg], data)
        info
      end
    end

    def restart!(group_id, new_group:)
      msg = make_debug_msg(group_id:) do
        if new_group
          I18n.t "Created new group with Microsoft ID: %{group_id}"
        else
          I18n.t "Using existing group with Microsoft ID: %{group_id}"
        end
      end
      @ms_group.update_unless_deleted debug_info: [msg]
    end

    def record_diff_stats(diff)
      n_owners = diff.local_owners.size
      msg1 =
        case n_owners
        when 0
          make_debug_msg { I18n.t("Syncing Microsoft group to have no owners") }
        when 1
          make_debug_msg { I18n.t("Syncing Microsoft group to have one owner") }
        else
          make_debug_msg(n_owners:) do
            I18n.t("Syncing Microsoft group to have %{n_owners} owners")
          end
        end

      n_owners_or_members = diff.local_owners_or_members.size
      msg2 =
        case n_owners_or_members
        when 0
          make_debug_msg { I18n.t("Syncing Microsoft group to have no members") }
        when 1
          make_debug_msg { I18n.t("Syncing Microsoft group to have one member (including owner)") }
        else
          make_debug_msg(n_owners_or_members:) do
            I18n.t("Syncing Microsoft group to have %{n_owners_or_members} members (including owners)")
          end
        end

      @ms_group.update_unless_deleted debug_info: (@ms_group.debug_info || []) + [msg1, msg2]
    end

    def record_filtered_users(irrelevant_enrollments_scope:, users_without_uluvs:, users_without_aads:)
      msgs = [
        irrelevant_enrollments_msg(irrelevant_enrollments_scope),
        *users_without_uluvs_msgs(users_without_uluvs),
        *users_without_aads_msgs(users_without_aads)
      ].compact

      if msgs.any?
        @ms_group.update_unless_deleted debug_info: (@ms_group.debug_info || []) + msgs
      end
    end

    def irrelevant_enrollments_cap
      100
    end

    def max_shown_users
      5
    end

    private

    # Make message for storing in debug_info in DB.
    # Forces en locale so we can store in English in DB and localize later.
    # The block needs to call I18n.t() so our i18n static analysis can extract
    # the strings to be translated.
    # See similar code in MicrosoftSync::Errors
    def make_debug_msg(interpolated_values = {}, &)
      i18nized_str = I18n.with_locale(:en, &)
      return nil if i18nized_str.blank?

      { timestamp: Time.now.utc.iso8601, msg: i18nized_str, data: interpolated_values }
    end

    def make_debug_msg_with_user_ids(user_ids, interpolated_values = {}, &)
      make_debug_msg(interpolated_values, &).merge(user_ids:)
    end

    def irrelevant_enrollments_msg(irrelevant_enrollments_scope)
      n_irrelevant_enrollments = irrelevant_enrollments_scope.limit(irrelevant_enrollments_cap + 1).count
      return unless n_irrelevant_enrollments > 0

      users = irrelevant_enrollments_scope.limit(max_shown_users).pluck(:user_id)

      if n_irrelevant_enrollments > irrelevant_enrollments_cap
        make_debug_msg_with_user_ids(users, irrelevant_enrollments_cap:, max_shown_users:) do
          I18n.t "More than %{irrelevant_enrollments_cap} irrelevant enrollments (enrollments not eligible for sync). First %{max_shown_users} users:"
        end
      elsif n_irrelevant_enrollments > max_shown_users
        make_debug_msg_with_user_ids(users, n_irrelevant_enrollments:, max_shown_users:) do
          I18n.t "%{n_irrelevant_enrollments} irrelevant enrollments (enrollments not eligible for sync). First %{max_shown_users} users:"
        end
      elsif n_irrelevant_enrollments != 1
        make_debug_msg_with_user_ids(users, n_irrelevant_enrollments:) do
          I18n.t "%{n_irrelevant_enrollments} irrelevant enrollments (enrollments not eligible for sync). Users:"
        end
      else
        make_debug_msg_with_user_ids(users) do
          I18n.t "one irrelevant enrollment (enrollment not eligible for sync). User:"
        end
      end
    end

    def users_without_uluvs_msgs(users_without_uluvs)
      intro_msg = make_debug_msg do
        {
          "email" => I18n.t("Using login attribute: email address"),
          "preferred_username" => I18n.t("Using login attribute: unique user ID"),
          "integration_id" => I18n.t("Using login attribute: integration ID"),
          "sis_user_id" => I18n.t("Using login attribute: SIS user ID"),
        }[@ms_group.root_account.settings[:microsoft_sync_login_attribute]]
      end

      n_users = users_without_uluvs.length
      list_msg =
        if users_without_uluvs.length > max_shown_users
          user_ids = users_without_uluvs.take(max_shown_users).to_a
          make_debug_msg_with_user_ids(user_ids, n_users:, n_shown: max_shown_users) do
            I18n.t("%{n_users} users without valid login attribute. First %{n_shown}:")
          end
        elsif users_without_uluvs.length > 1
          make_debug_msg_with_user_ids(users_without_uluvs.to_a, n_users:) do
            I18n.t("%{n_users} users without valid login attribute:")
          end
        elsif users_without_uluvs.length == 1
          make_debug_msg_with_user_ids(users_without_uluvs.to_a) do
            I18n.t("One user without valid login attribute:")
          end
        end

      [intro_msg, list_msg].compact
    end

    def users_without_aads_msgs(users_without_aads)
      intro_msg = make_debug_msg do
        {
          "userPrincipalName" => I18n.t("Looking up Microsoft users by remote attribute: User Principal Name (UPN)"),
          "mail" => I18n.t("Looking up Microsoft users by remote attribute: email address (mail)"),
          "mailNickname" => I18n.t("Looking up Microsoft users by remote attribute: mail nickname"),
        }[@ms_group.root_account.settings[:microsoft_sync_remote_attribute]]
      end

      n_users = users_without_aads.length
      list_msg =
        if users_without_aads.length > max_shown_users
          make_debug_msg_with_user_ids(users_without_aads.take(max_shown_users), n_users:, n_shown: max_shown_users) do
            I18n.t("%{n_users} Canvas users without corresponding Microsoft user. First %{n_shown}:")
          end
        elsif users_without_aads.length > 1
          make_debug_msg_with_user_ids(users_without_aads.to_a, n_users:) do
            I18n.t("%{n_users} Canvas users without corresponding Microsoft user:")
          end
        elsif users_without_aads.length == 1
          make_debug_msg_with_user_ids(users_without_aads.to_a) do
            I18n.t("One Canvas user without corresponding Microsoft user:")
          end
        end

      [intro_msg, list_msg].compact
    end
  end
end
