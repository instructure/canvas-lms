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
#

#
# See MicrosoftSync::Group for more info on Microsoft sync. This model is
# essentially a cache between a Canvas user, and their Microsoft AAD object ID
# (internal Microsoft user ID, also called just an "AAD" in this code) which is
# used in all of Microsoft's APIs, so we don't have to look it up every time we
# use Microsoft's APIs.
#
# Typically, a user's AAD is looked up by asking Microsoft for the AAD for a given
# UserPrincipalName (UPN) or other field on the Microsoft side that corresponds
# to a Canvas user's email address, username, or other field. The fields on the
# Canvas side and Microsoft side to match on are configurable in the root account
# settings (see microsoft_sync_login_attribute setting and other
# microsoft_sync_* settings). The value passed to the Microsoft API to match on
# such as the Canvas user's email address is referred to throughout MicrosoftSync
# as a "ULUV" or User Lookup Value.
#
class MicrosoftSync::UserMapping < ActiveRecord::Base
  belongs_to :root_account, class_name: "Account"
  belongs_to :user
  validates :root_account, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :root_account }
  MAX_ENROLLMENT_MEMBERS = MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS

  DEPENDED_ON_ACCOUNT_SETTINGS = %i[
    microsoft_sync_tenant
    microsoft_sync_login_attribute
    microsoft_sync_login_attribute_suffix
    microsoft_sync_remote_attribute
  ].freeze

  class AccountSettingsChanged < MicrosoftSync::Errors::GracefulCancelError
    def self.public_message
      I18n.t "The account-wide sync settings were changed while syncing. " \
             "Please attempt the sync again."
    end
  end

  # Get the IDs of users enrolled in a course which do NOT have valid
  # UserMappings for the Course's root account. Works in batches, yielding
  # arrays of user ids.
  #
  # For our purposes here, UserMappings with needs_updating=TRUE are ignored,
  # so later in the sync process they will be refreshed. (These UserMapping
  # rows are not deleted so they can be used while they are waiting to be
  # refreshed, which is better than the users being removed from the Microsoft
  # 365 group, in case the mapping being refreshed is not actually incorrect.)
  def self.find_enrolled_user_ids_without_mappings(course:, batch_size:)
    user_ids = GuardRail.activate(:secondary) do
      Enrollment
        .microsoft_sync_relevant
        .where(course_id: course.id)
        .joins(<<~SQL.squish)
          LEFT JOIN #{quoted_table_name} AS mappings
          ON mappings.user_id=enrollments.user_id
          AND mappings.root_account_id=#{course.root_account_id.to_i}
          AND mappings.needs_updating = FALSE
        SQL
        .where(mappings: { id: nil })
        .select(:user_id).distinct.limit(MAX_ENROLLMENT_MEMBERS)
        .pluck(:user_id)
    end

    user_ids.in_groups_of(batch_size) do |batch|
      yield(batch.compact)
    end
  end

  def self.user_ids_without_mappings(user_ids, root_account_id)
    existing_mappings = where(root_account_id:, user_id: user_ids)
    user_ids - existing_mappings.pluck(:user_id)
  end

  # Example: bulk_insert_for_root_account_id(course.root_account_id,
  #                                          user1.id => 'aad1', user1.id => 'aad2')
  # Uses Rails 6's upsert_all, which unlike our bulk_insert(), overrides
  # duplicates (including any possible needs_updating rows). (Don't need the
  # partition support that bulk_insert provides.)
  #
  # This method also refetches the Account settings after adding to make sure
  # the ULUV settings (login_attribute, login_attribute_suffix,
  # remote_attribute) and tenant haven't changed from the root_account that is
  # passed in. The settings in root_account should be what was used to fetch
  # the aads. This ensures that the values we are adding are actually for the
  # ULUV settings and tenant currently in the Account settings. If the settings
  # have changed, the just-added values will be deleted and this method will
  # raise an AccountSettingsChanged error.
  def self.bulk_insert_for_root_account(root_account, user_id_to_aad_hash)
    return if user_id_to_aad_hash.empty?

    now = Time.zone.now
    records = user_id_to_aad_hash.map do |user_id, aad_id|
      {
        root_account_id: root_account.id,
        created_at: now,
        updated_at: now,
        user_id:,
        aad_id:,
        needs_updating: false
      }
    end

    result = upsert_all(records, unique_by: [:user_id, :root_account_id])

    # In rare circumstances during account settings, this could end up deleting
    # valid rows (if they were just added by another process after an account
    # settings changed), but it doesn't matter too much as a full sync will
    # re-create them.
    if account_microsoft_sync_settings_changed?(root_account)
      ids_upserted = result.rows.map(&:first)
      where(id: ids_upserted).delete_all if ids_upserted.present?
      raise AccountSettingsChanged
    end
  end

  private_class_method def self.account_microsoft_sync_settings_changed?(root_account)
    current_settings = Account.where(id: root_account.id).take.settings
    DEPENDED_ON_ACCOUNT_SETTINGS.any? { |key| root_account.settings[key] != current_settings[key] }
  end

  # Find the enrollments for course which have a UserMapping for the user.
  # Selects "type" (enrollment type) and "aad_id".
  # Returns a scope that can be used with find_each.
  def self.enrollments_and_aads(course)
    Enrollment
      .microsoft_sync_relevant
      .where(course_id: course.id)
      .joins(<<~SQL.squish)
        JOIN #{quoted_table_name} AS mappings
        ON mappings.user_id=enrollments.user_id
        AND mappings.root_account_id=#{course.root_account_id.to_i}
      SQL
      .select(:id, :type, "mappings.aad_id as aad_id")
  end

  def self.delete_old_user_mappings_later(account, batch_size = 1000)
    Rails.logger.info("Triggering Microsoft Sync User Mappings hard delete for account #{account.global_id}")
    # We only need one job deleting UserMappings, so we can drop all other jobs
    # for the same root account that try to start up.
    delay_if_production(singleton: "microsoft_sync_delete_old_user_mappings_account_#{account.global_id}")
      .delete_user_mappings_for_account(account, batch_size)
  end

  def self.delete_user_mappings_for_account(account, batch_size)
    while where(root_account: account).limit(batch_size).delete_all > 0; end
  end

  # Finds mappings in all accounts with possible enrollments. Mirrors logic in
  # User#update_root_account_ids (but here we only care about strong
  # associations as we require enrollments, and just reading root_account_ids
  # may be less reliable than looking up again here)
  def self.flag_as_needs_updating_if_using_email(user)
    GuardRail.activate(:secondary) do
      Shard.with_each_shard(user.associated_shards(:strong)) do
        ra_ids = UserAccountAssociation.for_root_accounts.for_user_id(user.id).select(:account_id)
        # Seems to be some weird spec failures if we use "find_each" here. There shouldn't be
        # too many (definitely less than 1000) accounts for a user on a shard anyway
        Account.where(id: ra_ids).each do |acct|
          next unless acct.settings[:microsoft_sync_enabled] &&
                      acct.settings[:microsoft_sync_login_attribute] == "email"

          GuardRail.activate(:primary) do
            where(user:, root_account: acct)
              .update_all(updated_at: Time.now, needs_updating: true)
          end
        end
      end
    end
  end

  def self.delete_if_needs_updating(root_account_id, user_ids)
    user_ids.each_slice(1000) do |batch|
      where(root_account_id:, user_id: batch, needs_updating: true).delete_all
    end
  end
end
