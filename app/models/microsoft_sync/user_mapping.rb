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
# (internal Microsoft user ID) which is used in all of Microsoft's APIs, so we
# don't have to look it up every time we use Microsoft's APIs.
#
class MicrosoftSync::UserMapping < ActiveRecord::Base
  belongs_to :root_account, class_name: 'Account'
  belongs_to :user
  validates_presence_of :root_account
  validates_presence_of :user_id
  validates_uniqueness_of :user_id, scope: :root_account

  # Get the IDs of users enrolled in a course which do not have UserMappings
  # for the Course's root account. Works in batches, yielding arrays of user ids.
  def self.find_enrolled_user_ids_without_mappings(course:, batch_size:, &blk)
    GuardRail.activate(:secondary) do
      Enrollment.active.where(course_id: course.id).joins(%{
          LEFT JOIN #{quoted_table_name} AS mappings
          ON mappings.user_id=enrollments.user_id
          AND mappings.root_account_id=#{course.root_account_id.to_i}
        }).
        where('mappings.id IS NULL').select(:user_id).
        find_in_batches(batch_size: batch_size) do |enrollments|
          blk.call(enrollments.map(&:user_id))
        end
    end
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
    GuardRail.activate(:primary) { insert_all(records) }
  end
end
