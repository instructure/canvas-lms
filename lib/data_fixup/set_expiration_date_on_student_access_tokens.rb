# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DataFixup::SetExpirationDateOnStudentAccessTokens
  def self.run
    # If there is no default developer key, then skip this fixup.
    # User-generated access tokens are associated with the default developer key.
    # If the default developer key does not exist, then we will definitely not need
    # to fix up any access tokens. In fact, this fixup would need to be fixed in that
    # case, because when our CI system starts up, there is no default developer key created
    # yet, and simply calling DeveloperKey.default will attempt to create the dev key
    # if it does not exist. And our CI system also expects the test database to be empty.
    return unless DeveloperKey.default(create_if_missing: false)

    expiration_date = 120.days.from_now

    AccessToken.active.user_generated.where("permanent_expires_at > ? OR permanent_expires_at IS NULL", expiration_date).find_ids_in_batches(batch_size: 1000) do |access_token_batch|
      delay_if_production(priority: Delayed::LOWER_PRIORITY, n_strand: "long_datafixups")
        .run_on_batch(access_token_batch)
    end
  end

  def self.run_on_batch(access_token_batch)
    expiration_date = 120.days.from_now

    # Get the users who created those tokens
    users_with_access_tokens = AccessToken.where(id: access_token_batch).distinct(:user_id).pluck(:user_id).map { |user_id| Shard.global_id_for(user_id) }
    users = User.where(id: users_with_access_tokens).select(:id).to_a
    User.preload_shard_associations(users)

    # Save a copy of users_with_access tokens; we'll subtract from this array as we iterate
    # through the shards and figure out which users have no enrollments on any shard.
    users_with_no_enrollments = users_with_access_tokens

    Shard.partition_by_shard(users) do |users_on_shard|
      # Find all enrollments for those users that *aren't* a StudentEnrollment
      non_students = Enrollment.active_by_date.where(user: users_on_shard).where.not(type: "StudentEnrollment").distinct.pluck(:user_id).map { |user_id| Shard.global_id_for(user_id) }
      # If they had any non-student enrollments, we don't want to change their
      # access tokens, so remove them from the list.
      users_with_access_tokens -= non_students

      # If they have no enrollments on any shard, we also don't want to change
      # their access tokens.
      no_enrollments_on_this_shard = User.shard(Shard.current).active.where(id: users_on_shard.pluck(:id)).where.missing(:enrollments).pluck(:id).map do |id|
        Shard.global_id_for(id)
      end

      # Take the users who we expected to have enrollments on this shard, and subtract the ones with no enrollments on this shard.
      # That leaves us with the users who did have enrollments on this shard. Remove them from our list of users with no enrollments.
      users_on_shard_ids = users_on_shard.pluck(:global_id)
      users_with_no_enrollments -= (users_on_shard_ids - no_enrollments_on_this_shard)
    end

    # Now, subtract the users with no enrollments. If they had no enrollments, we don't want to affect their tokens.
    users_with_access_tokens -= users_with_no_enrollments

    AccessToken.active.where(id: access_token_batch, user_id: users_with_access_tokens).update_all(permanent_expires_at: expiration_date)
  end
end
