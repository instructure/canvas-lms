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

class AccountNotification < ActiveRecord::Base
  validates :start_at, :end_at, :subject, :message, :account_id, presence: true
  validate :validate_dates
  validate :send_message_not_set_for_site_admin
  belongs_to :account, touch: true
  belongs_to :user
  has_many :account_notification_roles, dependent: :destroy
  validates :message, length: { maximum: maximum_text_length, allow_blank: false }
  validates :subject, length: { maximum: maximum_string_length }
  sanitize_field :message, CanvasSanitize::SANITIZE

  after_save :create_alert
  after_save :queue_message_broadcast
  after_save :clear_cache

  USERS_PER_MESSAGE_BATCH = 1000

  ACCOUNT_SERVICE_NOTIFICATION_FLAGS = %w[account_survey_notifications].freeze
  validates :required_account_service, inclusion: { in: ACCOUNT_SERVICE_NOTIFICATION_FLAGS, allow_nil: true }

  validates :months_in_display_cycle, inclusion: { in: 1..48, allow_nil: true }

  def validate_dates
    if start_at && end_at && end_at < start_at
      errors.add(:end_at, t("errors.invalid_account_notification_end_at", "Account notification end time precedes start time"))
    end
  end

  def create_alert
    if start_at > Time.zone.now
      delay(run_at: start_at,
            on_conflict: :overwrite,
            singleton: "create_notification_alert:#{global_id}")
        .create_alert
      return
    end

    return unless account.root_account?

    roles = account_notification_roles.map(&:role_name)
    return if roles.count > 0 && (roles & ["StudentEnrollment", "ObserverEnrollment"]).none?

    thresholds = ObserverAlertThreshold.active.where(observer: User.of_account(account), alert_type: "institution_announcement")
                                       .where.not(id: ObserverAlert.where(context: self).select(:observer_alert_threshold_id))
    thresholds.find_each do |threshold|
      ObserverAlert.create(student: threshold.student,
                           observer: threshold.observer,
                           observer_alert_threshold: threshold,
                           context: self,
                           alert_type: "institution_announcement",
                           action_date: start_at,
                           title: I18n.t('Institution announcement: "%{announcement_title}"', {
                                           announcement_title: subject
                                         }))
    end
  end

  def current?
    end_at >= Time.zone.now
  end
  alias_method :current, :current?

  def past?
    end_at < Time.zone.now
  end
  alias_method :past, :past?

  def self.for_user_and_account(user, root_account, include_past: false)
    GuardRail.activate(:secondary) do
      if root_account.site_admin?
        current = for_account(root_account, include_past:)
      else
        course_ids = user.enrollments.active_or_pending_by_date.shard(user.in_region_associated_shards).distinct.pluck(:course_id) # fetch sharded course ids
        # and then fetch account_ids separately - using pluck on a joined column doesn't give relative ids
        all_account_ids = Course.where(id: course_ids).not_deleted
                                .distinct.pluck(:account_id, :root_account_id).flatten.uniq
        all_account_ids += user.account_users.active.shard(user.in_region_associated_shards)
                               .joins(:account).where(accounts: { workflow_state: "active" })
                               .distinct.pluck(:account_id).uniq
        all_account_ids = Account.multi_account_chain_ids(all_account_ids) # get all parent sub-accounts too
        current = for_account(root_account, all_account_ids, include_past:)
      end

      user_role_ids = {}
      # because we are going through all the current announcements, we cache the
      # results of the sub_account chain to not have to calculate ids again.
      sub_account_ids_map = {}

      current.select! do |announcement|
        # use role.id instead of role_id to trigger Role#id magic for built in
        # roles. try(:id) because the AccountNotificationRole may have an
        # explicitly nil role_id to indicate the announcement's intended for
        # users not enrolled in any courses
        role_ids = announcement.account_notification_roles.map { |anr| anr.role&.role_for_root_account_id(root_account.id)&.id }
        global_account_id = Shard.global_id_for(announcement.account_id, announcement.shard)

        unless role_ids.empty? || user_role_ids.key?(announcement.account_id)
          unless announcement.account.root_account?
            announcement.shard.activate do
              # we need to store the local account ids. The ids for the
              # sub_accounts are relative to the announcements shard, but we use
              # store the announcements for the user's shards which could be
              # many. This also avoids storing the same local_id and using the
              # wrong chain.
              sub_account_ids_map[global_account_id] ||=
                Account.sub_account_ids_recursive(announcement.account_id) + [announcement.account_id]
            end
          end

          # choose enrollments and account users to inspect
          account_users = announcement.account_user_roles(user)
          enrollments = announcement.shard.activate do
            announcement.enrollment_role_ids(user, account_ids: sub_account_ids_map[global_account_id])
          end
          # preload role objects for those enrollments and account users
          ActiveRecord::Associations.preload(enrollments, [:role])
          ActiveRecord::Associations.preload(account_users, [:role])

          # map to role ids. user role.id instead of role_id to trigger Role#id
          # magic for built in roles. announcements intended for users not
          # enrolled in any courses have the NilEnrollment role type
          user_role_ids[announcement.account_id] = enrollments.map { |e| e.role.role_for_root_account_id(root_account.id).id }
          user_role_ids[announcement.account_id] = [nil] if user_role_ids[announcement.account_id].empty?
          user_role_ids[announcement.account_id] |= account_users.map { |au| au.role.role_for_root_account_id(root_account.id).id }
        end

        role_ids.empty? || role_ids.intersect?(user_role_ids[announcement.account_id])
      end

      user.shard.activate do
        unless include_past
          closed_ids = user.get_preference(:closed_notifications) || []
          # If there are ids marked as 'closed' that are no longer
          # applicable, they probably need to be cleared out.
          current_ids = current.map(&:id)
          unless (closed_ids - current_ids).empty?
            GuardRail.activate(:primary) do
              user.set_preference(:closed_notifications, closed_ids & current_ids)
            end
          end
          current.reject! { |announcement| closed_ids.include?(announcement.id) }
        end

        # filter out announcements that have a periodic cycle of display,
        # and the user isn't in the set of users to display it to this month (based
        # on user id)
        current.reject! do |announcement|
          if (months_in_period = announcement.months_in_display_cycle)
            !display_for_user?(user.id, months_in_period)
          end
        end

        if !root_account.include_students_in_global_survey? && current.any? { |a| a.required_account_service == "account_survey_notifications" }
          roles = user.enrollments.shard(user.in_region_associated_shards).active_or_pending_by_date.distinct.pluck(:type)
          if roles == ["StudentEnrollment"]
            current.reject! { |announcement| announcement.required_account_service == "account_survey_notifications" }
          end
        end
      end

      current.sort_by { |item| item[:end_at] }.reverse
    end
  end

  def enrollment_role_ids(user, account_ids:)
    if account.site_admin?
      scope = user.enrollments.shard(user.in_region_associated_shards)
    else
      scope = account.root_account.all_enrollments.where(user_id: user)
      unless account.root_account?
        scope = scope.where(courses: { account_id: account_ids })
                     .joins(:course)
      end
    end
    scope.active_or_pending_by_date.distinct.select(:role_id).to_a
  end

  def account_user_roles(user)
    if account.site_admin?
      user.account_users.shard(user.in_region_associated_shards)
          .distinct.select(:role_id).to_a
    else
      account.root_account.cached_all_account_users_for(user)
    end
  end

  def self.cache_key_for_root_account(root_account_id, date)
    ["root_account_notifications2", Shard.global_id_for(root_account_id), date.strftime("%Y-%m-%d")].cache_key
  end

  def self.for_account(root_account, all_visible_account_ids = nil, include_past: false)
    account_ids = root_account_ids = root_account.account_chain(include_site_admin: true).map(&:id)
    if all_visible_account_ids
      account_ids += all_visible_account_ids
      account_ids.uniq!
    end
    all_visible_account_ids = nil if account_ids == root_account_ids

    block = proc do
      now = Time.now.utc
      start_at = include_past ? now : now.end_of_day

      end_at = now - 4.months if include_past
      end_at ||= start_at
      end_at = end_at.beginning_of_day

      # we always check the given account for the flag, even if the announcement is from the site_admin account
      # this allows us to make a global announcement that is filtered to only accounts with this flag
      enabled_flags = ACCOUNT_SERVICE_NOTIFICATION_FLAGS & root_account.allowed_services_hash.keys.map(&:to_s)

      base_shard = Shard.current
      result = Shard.partition_by_shard(account_ids) do |sharded_account_ids|
        load_by_account = lambda do |slice_account_ids|
          scope = AccountNotification.where("account_id IN (?) AND start_at <=? AND end_at >=?", slice_account_ids, start_at, end_at)
                                     .order("start_at DESC")
                                     .preload({ account: :root_account }, account_notification_roles: :role)
          if Shard.current == root_account.shard
            if slice_account_ids != [root_account.id]
              scope = scope.joins(:account).where("domain_specific=? OR #{Account.resolved_root_account_id_sql}=?", false, root_account.id)
            end
          else
            scope = scope.where(domain_specific: false)
          end
          scope.to_a
        end

        # all root accounts; do them one by one, and MultiCache them
        this_shard_root_account_ids = if Shard.current == base_shard
                                        root_account_ids
                                      else
                                        root_account_ids.map { |id| Shard.relative_id_for(id, base_shard, Shard.current) }
                                      end
        if (sharded_account_ids - this_shard_root_account_ids).empty? && !include_past
          sharded_account_ids.map do |single_root_account_id|
            MultiCache.fetch(cache_key_for_root_account(single_root_account_id, end_at)) do
              load_by_account.call([single_root_account_id])
            end
          end.flatten
        else
          load_by_account.call(sharded_account_ids)
        end
      end

      # need to post-process, since the cache covers all enabled flags
      result.select! { |n| n.required_account_service.nil? || enabled_flags.include?(n.required_account_service) }

      # need to post-process since the cache covers the entire day
      unless include_past
        result.select! { |n| n.start_at <= now && n.end_at >= now }
      end
      result
    end

    if all_visible_account_ids || include_past
      # Refreshes every 10 minutes at the longest
      all_account_ids_hash = Digest::SHA256.hexdigest all_visible_account_ids.try(:sort).to_s
      Rails.cache.fetch(["account_notifications5", root_account, all_account_ids_hash, include_past].cache_key, expires_in: 10.minutes, &block)
    else
      # no point in doing an additional layer of caching for _only_ root accounts when root accounts are explicitly cached
      block.call
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
    months_since_start_time = ((current_time.year - start_time.year) * 12) + (current_time.month - start_time.month)
    periods_since_start_time = months_since_start_time / months_in_period
    months_into_current_period = months_since_start_time % months_in_period
    mod_value = (Random.new(periods_since_start_time).rand(months_in_period) + months_into_current_period) % months_in_period
    user_id % months_in_period == mod_value
  end

  attr_accessor :message_recipients

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :account_notification
    p.to { message_recipients }
    p.whenever do |record|
      record.should_send_message? && record.message_recipients.present?
    end
  end

  def send_message_not_set_for_site_admin
    if send_message? && account.site_admin?
      # i mean maybe we could try but there are almost certainly better ways to send mass emails than this
      errors.add(:send_message, "Cannot send messages for site admin accounts")
    end
  end

  def should_send_message?
    send_message? && !messages_sent_at &&
      (start_at.nil? || (start_at < Time.now.utc)) &&
      (end_at.nil? || (end_at > Time.now.utc))
  end

  def queue_message_broadcast
    if send_message? && !messages_sent_at && !message_recipients
      delay(run_at: start_at || Time.now.utc,
            on_conflict: :overwrite,
            singleton: "account_notification_broadcast_messages:#{global_id}").broadcast_messages
    end
  end

  def clear_cache
    # yes, I could be smarter about only clearing this if the date is in range, and a relevant field changed,
    # but that is several complicated conditions, and these rarely change, so shouldn't be a big deal
    # to just let the cache clear
    MultiCache.delete(self.class.cache_key_for_root_account(account_id, Time.now.utc)) if account.root_account?
  end

  def broadcast_messages
    return unless should_send_message? # sanity check before we start grabbing user ids

    # don't try to send a message to an entire account in one job
    applicable_user_ids.each_slice(USERS_PER_MESSAGE_BATCH) do |sliced_user_ids|
      self.message_recipients = sliced_user_ids.map { |id| "user_#{id}" }
      save # trigger the broadcast policy
    ensure
      self.message_recipients = nil
    end
    update_attribute(:messages_sent_at, Time.now.utc)
  end

  def applicable_user_ids
    roles = account_notification_roles.preload(:role).to_a.map(&:role)
    GuardRail.activate(:secondary) do
      self.class.applicable_user_ids_for_account_and_roles(account, roles)
    end
  end

  def self.applicable_user_ids_for_account_and_roles(account, roles)
    account.shard.activate do
      all_account_ids = Account.sub_account_ids_recursive(account.id) + [account.id]
      user_ids = Set.new
      get_everybody = roles.empty?

      course_roles = roles.compact.select(&:course_role?).map { |r| r.role_for_root_account_id(account.resolved_root_account_id) }
      if get_everybody || course_roles.any?
        Course.find_ids_in_ranges do |min_id, max_id|
          course_ids = Course.active.where(id: min_id..max_id, account_id: all_account_ids).pluck(:id)
          next unless course_ids.any?

          course_ids.each_slice(50) do |sliced_course_ids|
            scope = Enrollment.active_or_pending_by_date.where(course_id: sliced_course_ids)
            scope = scope.where(role_id: course_roles) unless get_everybody
            user_ids += scope.distinct.pluck(:user_id)
          end
        end
      end

      account_roles = roles.compact.select(&:account_role?).map { |r| r.role_for_root_account_id(account.resolved_root_account_id) }
      if get_everybody || account_roles.any?
        AccountUser.find_ids_in_ranges do |min_id, max_id|
          scope = AccountUser.where(id: min_id..max_id).active.where(account_id: all_account_ids)
          scope = scope.where(role_id: account_roles) unless get_everybody
          user_ids += scope.distinct.pluck(:user_id)
        end
      end

      if roles.include?(nil)
        users_with_no_enrollments_from_given_accounts = User.joins(:user_account_associations).where(user_account_associations: { account_id: all_account_ids }).where.not(id: Enrollment.active_or_pending_by_date.select(:user_id))
        user_ids += users_with_no_enrollments_from_given_accounts.pluck(:id)
      end

      suspended_user_ids = User.where(id: user_ids)
                               .joins(:active_pseudonyms)
                               .group("users.id")
                               .having("COUNT(pseudonyms.id) = COUNT(CASE WHEN pseudonyms.workflow_state = 'suspended' THEN 1 END)")
                               .pluck(:id)
      user_ids -= suspended_user_ids
      user_ids.to_a.sort
    end
  end
end
