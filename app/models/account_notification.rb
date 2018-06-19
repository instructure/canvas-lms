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

class AccountNotification < ActiveRecord::Base
  validates_presence_of :start_at, :end_at, :subject, :message, :account_id
  validate :validate_dates
  belongs_to :account, :touch => true
  belongs_to :user
  has_many :account_notification_roles, dependent: :destroy
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => false, :allow_blank => false
  sanitize_field :message, CanvasSanitize::SANITIZE

  ACCOUNT_SERVICE_NOTIFICATION_FLAGS = %w[account_survey_notifications]
  validates_inclusion_of :required_account_service, in: ACCOUNT_SERVICE_NOTIFICATION_FLAGS, allow_nil: true

  validates_inclusion_of :months_in_display_cycle, in: 1..48, allow_nil: true

  def validate_dates
    if self.start_at && self.end_at
      errors.add(:end_at, t('errors.invalid_account_notification_end_at', "Account notification end time precedes start time")) if self.end_at < self.start_at
    end
  end

  def self.for_user_and_account(user, root_account)
    if root_account.site_admin?
      current = self.for_account(root_account)
    else
      course_ids = user.enrollments.active.shard(user).distinct.pluck(:course_id) # fetch sharded course ids
      # and then fetch account_ids separately - using pluck on a joined column doesn't give relative ids
      all_account_ids = Course.where(:id => course_ids, :workflow_state => 'available').
        distinct.pluck(:account_id, :root_account_id).flatten.uniq
      all_account_ids += user.account_users.active.shard(user).
        joins(:account).where(accounts: {workflow_state: 'active'}).
        distinct.pluck(:account_id).uniq
      all_account_ids = Account.multi_account_chain_ids(all_account_ids) # get all parent sub-accounts too
      current = self.for_account(root_account, all_account_ids)
    end

    user_role_ids = {}

    current.select! do |announcement|
      # use role.id instead of role_id to trigger Role#id magic for built in
      # roles. try(:id) because the AccountNotificationRole may have an
      # explicitly nil role_id to indicate the announcement's intended for
      # users not enrolled in any courses
      role_ids = announcement.account_notification_roles.map { |anr| anr.role&.role_for_shard&.id }

      announcement_root_account = announcement.account.root_account
      unless role_ids.empty? || user_role_ids.key?(announcement_root_account.id)
        # choose enrollments and account users to inspect
        if announcement.account.site_admin?
          enrollments = user.enrollments.shard(user).active.distinct.select(:role_id)
          account_users = user.account_users.shard(user).distinct.select(:role_id)
        else
          # TODO (probably): restrict sub-account notifications to roles within that sub-account (vs the whole root account)
          enrollments = user.enrollments_for_account_and_sub_accounts(announcement_root_account).select(:role_id)
          account_users = announcement_root_account.all_account_users_for(user)
        end

        # preload role objects for those enrollments and account users
        ActiveRecord::Associations::Preloader.new.preload(enrollments, [:role])
        ActiveRecord::Associations::Preloader.new.preload(account_users, [:role])

        # map to role ids. user role.id instead of role_id to trigger Role#id
        # magic for built in roles. announcements intended for users not
        # enrolled in any courses have the NilEnrollment role type
        user_role_ids[announcement_root_account.id] = enrollments.map{ |e| e.role.role_for_shard.id }
        user_role_ids[announcement_root_account.id] = [nil] if user_role_ids[announcement_root_account.id].empty?
        user_role_ids[announcement_root_account.id] |= account_users.map{ |au| au.role.role_for_shard.id }
      end

      role_ids.empty? || (role_ids & user_role_ids[announcement_root_account.id]).present?
    end

    user.shard.activate do
      closed_ids = user.preferences[:closed_notifications] || []
      # If there are ids marked as 'closed' that are no longer
      # applicable, they probably need to be cleared out.
      current_ids = current.map(&:id)
      if !(closed_ids - current_ids).empty?
        closed_ids = user.preferences[:closed_notifications] &= current_ids
        user.save!
      end
      current.reject! { |announcement| closed_ids.include?(announcement.id) }

      # filter out announcements that have a periodic cycle of display,
      # and the user isn't in the set of users to display it to this month (based
      # on user id)
      current.reject! do |announcement|
        if months_in_period = announcement.months_in_display_cycle
          !self.display_for_user?(user.id, months_in_period)
        end
      end

      roles = user.enrollments.shard(user).active.distinct.pluck(:type)

      if roles == ['StudentEnrollment'] && !root_account.include_students_in_global_survey?
        current.reject! { |announcement| announcement.required_account_service == 'account_survey_notifications' }
      end
    end

    current
  end

  def self.for_account(root_account, all_visible_account_ids=nil)
    # Refreshes every 10 minutes at the longest
    all_account_ids_hash = Digest::MD5.hexdigest all_visible_account_ids.try(:sort).to_s
    Rails.cache.fetch(['account_notifications4', root_account, all_account_ids_hash].cache_key, expires_in: 10.minutes) do
      now = Time.now.utc
      # we always check the given account for the flag, even if the announcement is from the site_admin account
      # this allows us to make a global announcement that is filtered to only accounts with this flag
      enabled_flags = ACCOUNT_SERVICE_NOTIFICATION_FLAGS & root_account.allowed_services_hash.keys.map(&:to_s)
      account_ids = root_account.account_chain(include_site_admin: true).map(&:id)
      if all_visible_account_ids
        account_ids += all_visible_account_ids
        account_ids.uniq!
      end

      Shard.partition_by_shard(account_ids) do |sharded_account_ids|
        scope = AccountNotification.where("account_id IN (?) AND start_at <? AND end_at>?", sharded_account_ids, now, now).
          where("required_account_service IS NULL OR required_account_service IN (?)", enabled_flags).
          order('start_at DESC').
          preload({:account => :root_account}, account_notification_roles: :role)
        if Shard.current == root_account.shard
          # get the sub-account ids that are directly from the current root account
          domain_account_ids = Account.where(:id => sharded_account_ids, :root_account_id => root_account.id).pluck(:id) + [root_account.id]
          scope = scope.where("domain_specific = ? OR account_id IN (?)", false, domain_account_ids)
        else
          scope = scope.where(:domain_specific => false)
        end
        scope.to_a
      end
    end
  end

  def self.default_months_in_display_cycle
    Setting.get("account_notification_default_months_in_display_cycle", "9").to_i
  end

  # private
  def self.display_for_user?(user_id, months_in_period, current_time = Time.now.utc)
    # we just need a stable reference point, doesn't matter what it is, so
    # let's use unix epoch
    start_time = Time.at(0).utc
    months_since_start_time = (current_time.year - start_time.year) * 12 + (current_time.month - start_time.month)
    periods_since_start_time = months_since_start_time / months_in_period
    months_into_current_period = months_since_start_time % months_in_period
    mod_value = (Random.new(periods_since_start_time).rand(months_in_period) + months_into_current_period) % months_in_period
    user_id % months_in_period == mod_value
  end
end
