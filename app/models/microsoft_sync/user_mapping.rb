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

require_dependency 'microsoft_sync'

#
# See MicrosoftSync::Group for more info on Microsoft sync. This model is
# essentially a cache between a Canvas user, and their Microsoft AAD object ID
# (internal Microsoft user ID, also called just an "AAD" in this code) which is
# used in all of Microsoft's APIs, so we don't have to look it up every time we
# use Microsoft's APIs.
#
# Typically, a user's AAD is looked up by asking Microsoft for the AAD for a given
# "UPN" (see SyncerSteps#ensure_enrollments_user_mappings_filled). A UPN, or
# "userPrincipalName", is a field Microsoft has on their users that corresponds
# to a Canvas user's email address, username, or other field, as chosen by the
# admin (see microsoft_sync_login_attribute in the root account settings)
#
class MicrosoftSync::UserMapping < ActiveRecord::Base
  belongs_to :root_account, class_name: 'Account'
  belongs_to :user
  validates_presence_of :root_account
  validates_presence_of :user_id
  validates_uniqueness_of :user_id, scope: :root_account
  MAX_ENROLLMENT_MEMBERS = MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS

  # Get the IDs of users enrolled in a course which do not have UserMappings
  # for the Course's root account. Works in batches, yielding arrays of user ids.
  def self.find_enrolled_user_ids_without_mappings(course:, batch_size:, &blk)
    user_ids = GuardRail.activate(:secondary) do
      Enrollment.active.where(course_id: course.id).joins(%{
          LEFT JOIN #{quoted_table_name} AS mappings
          ON mappings.user_id=enrollments.user_id
          AND mappings.root_account_id=#{course.root_account_id.to_i}
        })
        .where('mappings.id IS NULL')
        .select(:user_id).distinct.limit(MAX_ENROLLMENT_MEMBERS)
        .pluck(:user_id)
    end

    user_ids.in_groups_of(batch_size) do |batch|
      blk.call(batch.compact)
    end
  end

  def self.user_ids_without_mappings(user_ids, root_account_id)
    existing_mappings = where(root_account_id: root_account_id, user_id: user_ids)
    user_ids - existing_mappings.pluck(:user_id)
  end

  # Example: bulk_insert_for_root_account_id(course.root_account_id,
  #                                          user1.id => 'aad1', user1.id => 'aad2')
  # Uses Rails 6's insert_all, which unlike our bulk_insert(), ignores
  # duplicates. (Don't need the partition support that bulk_insert provides.)
  def self.bulk_insert_for_root_account_id(root_account_id, user_id_to_aad_hash)
    return if user_id_to_aad_hash.empty?

    now = Time.zone.now
    records = user_id_to_aad_hash.map do |user_id, aad_id|
      {
        root_account_id: root_account_id,
        created_at: now, updated_at: now,
        user_id: user_id, aad_id: aad_id,
      }
    end

    # TODO: either check UPN type in Account settings transactionally when adding, or
    # check after adding and delete what we just added.
    insert_all(records)
  end

  # Find the enrollments for course which have a UserMapping for the user.
  # Selects "type" (enrollment type) and "aad_id".
  # Returns a scope that can be used with find_each.
  def self.enrollments_and_aads(course)
    Enrollment
      .active.not_fake.where(course_id: course.id)
      .joins(%{
        JOIN #{quoted_table_name} AS mappings
        ON mappings.user_id=enrollments.user_id
        AND mappings.root_account_id=#{course.root_account_id.to_i}
      })
      .select(:id, :type, 'mappings.aad_id as aad_id')
  end

  def self.delete_old_user_mappings_later(account, batch_size = 1000)
    Rails.logger.info("Triggering Microsoft Sync User Mappings hard delete for account #{account.global_id}")
    # We only need one job deleting UserMappings, so we can drop all other jobs
    # for the same root account that try to start up.
    self.delay_if_production(singleton: "microsoft_sync_delete_old_user_mappings_account_#{account.global_id}")
      .delete_user_mappings_for_account(account, batch_size)
  end

  def self.delete_user_mappings_for_account(account, batch_size)
    # TODO: When we figure out a way to ensure a UserMapping is up-to-date with an account's Sync settings
    # (like by using a hash), we'll need to update this query to filter by the account's current settings.
    while self.where(root_account: account).limit(batch_size).delete_all > 0; end
  end
end
