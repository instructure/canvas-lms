# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class K5::UserService
  ROLES_THAT_CAN_DISABLE_K5 = %w[admin teacher].freeze
  BATCHED_KEYS = %i[k5_user enrollments account_users].freeze
  CACHE_EXPIRY_TIME = 12.hours

  def initialize(user, root_account, observed_user)
    @actual_user = user
    @root_account = root_account
    @observed_user = observed_user
  end

  def k5_user?(check_disabled: true)
    # unauthenticated users get classic canvas
    return false unless @actual_user

    RequestCache.cache("k5_user", @actual_user, @observed_user, @root_account, check_disabled, @actual_user.elementary_dashboard_disabled?) do
      next false if check_disabled && k5_disabled?

      set_observer_variables

      # This key is also invalidated when the k5 setting is toggled at the account level or when enrollments change
      Rails.cache.fetch_with_batched_keys(["k5_user3", @course_ids].cache_key, batch_object: @user, batched_keys: BATCHED_KEYS, expires_in: CACHE_EXPIRY_TIME) do
        user_has_association?(global_k5_account_ids)
      end
    end
  end

  def use_classic_font?
    return false unless @actual_user
    return false unless k5_user?

    RequestCache.cache("use_classic_font", @actual_user, @observed_user, @root_account) do
      set_observer_variables

      # This key is also invalidated when the k5 setting is toggled at the account level or when enrollments change
      Rails.cache.fetch_with_batched_keys(["use_classic_font", @course_ids].cache_key, batch_object: @user, batched_keys: BATCHED_KEYS, expires_in: CACHE_EXPIRY_TIME) do
        user_has_association?(global_classic_font_account_ids)
      end
    end
  end

  def k5_disabled?
    # Only admins and teachers can opt-out of being considered a k5 user
    # Observers can't disable if they have a student selected in the picker
    can_disable = @actual_user.roles(@root_account).any? { |role| ROLES_THAT_CAN_DISABLE_K5.include?(role) } && !currently_observing?
    can_disable && @actual_user.elementary_dashboard_disabled?
  end

  private

  def currently_observing?
    @actual_user.present? &&
      @observed_user.present? &&
      @actual_user.roles(@root_account).include?("observer") &&
      @observed_user != @actual_user
  end

  # set these separately (instead of in i.e. constructor) to avoid the extra db query when
  # we'll pull the necessary value from RequestCache
  def set_observer_variables
    if currently_observing?
      @user = @observed_user
      # set course_ids since we should only consider the subset of courses where the
      # observer is observing the student when determining k5 settings
      @course_ids = @actual_user
                    .observer_enrollments
                    .active_or_pending_by_date
                    .where(associated_user: @observed_user)
                    .shard(@actual_user.in_region_associated_shards)
                    .pluck(:course_id)
    else
      @user = @actual_user
      @course_ids = nil
    end
  end

  def global_k5_account_ids
    # Global ids of accounts where k5 is enabled (in shards where the user has an association)
    k5_account_ids = []

    Account.shard(@user.in_region_associated_shards).root_accounts.active.non_shadow
           .where("settings LIKE '%k5_accounts:\n- %'").select(:settings).each do |account|
      account.settings[:k5_accounts]&.each do |k5_account_id|
        k5_account_ids << Shard.global_id_for(k5_account_id, account.shard)
      end
    end

    k5_account_ids
  end

  def global_classic_font_account_ids
    # Global ids of accounts where classic font is selected (in shards where the user has an association)
    classic_font_account_ids = []

    Account.shard(@user.in_region_associated_shards).root_accounts.active.non_shadow
           .where("settings LIKE '%k5_classic_font_accounts:\n- %'").select(:settings).each do |account|
      account.settings[:k5_classic_font_accounts]&.each do |classic_font_account_id|
        classic_font_account_ids << Shard.global_id_for(classic_font_account_id, account.shard)
      end
    end

    # Accounts that have selected classic font must also be a k5 account themself
    classic_font_account_ids & global_k5_account_ids
  end

  def user_has_association?(global_account_ids)
    return false if global_account_ids.blank?

    provided_global_account_ids = @course_ids.present? ? Course.where(id: @course_ids).distinct.pluck(:account_id).map { |account_id| Shard.global_id_for(account_id) } : []

    # See if the user has associations with any of the global_account_ids (or their descendants) on each shard
    k5_associations = Shard.partition_by_shard(global_account_ids) do |k5_account_ids|
      if @course_ids.present?
        # Use only provided course_ids' account ids if passed
        provided_account_ids = provided_global_account_ids.select { |account_id| Shard.shard_for(account_id) == Shard.current }.map { |global_id| Shard.local_id_for(global_id)[0] }
        break true if provided_account_ids.intersect?(k5_account_ids)

        provided_account_chain_ids = Account.multi_account_chain_ids(provided_account_ids)
        break true if provided_account_chain_ids.intersect?(k5_account_ids)
      else
        # If course_ids isn't passed, check all their (non-observer and unlinked observer) enrollments and account_users
        # i.e., ignore observer enrollments with a linked student - the observer picker filters out these courses
        enrolled_courses_scope = @user.enrollments.shard(Shard.current).new_or_active_by_date
        enrolled_courses_scope = enrolled_courses_scope.not_of_observer_type.or(enrolled_courses_scope.of_observer_type.where(associated_user_id: nil))
        enrolled_course_ids = enrolled_courses_scope.select(:course_id)
        enrolled_account_ids = Course.where(id: enrolled_course_ids).distinct.pluck(:account_id)
        break true if enrolled_account_ids.intersect?(k5_account_ids)

        enrolled_account_ids += @user.account_users.shard(Shard.current).active.pluck(:account_id)
        break true if enrolled_account_ids.intersect?(k5_account_ids)

        enrolled_account_chain_ids = Account.multi_account_chain_ids(enrolled_account_ids)
        break true if enrolled_account_chain_ids.intersect?(k5_account_ids)
      end
    end
    k5_associations == true
  end
end
