class AccountNotification < ActiveRecord::Base
  attr_accessible :subject, :icon, :message,
    :account, :account_notification_roles, :user, :start_at, :end_at,
    :required_account_service, :months_in_display_cycle

  EXPORTABLE_ATTRIBUTES = [
    :id, :user_id, :account_id, :subject, :icon, :message, :start_at,
    :end_at, :required_account_service, :months_in_display_cycle, :created_at, :updated_at
  ]

  EXPORTABLE_ASSOCIATIONS = [:account, :user, :account_notification_roles]

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

  def self.for_user_and_account(user, account)
    current = self.for_account(account)

    ActiveRecord::Associations::Preloader.new(current, [:account, {account_notification_roles: :role}]).run
    user_role_ids = {}

    current.select! do |announcement|
      # use role.id instead of role_id to trigger Role#id magic for built in
      # roles. try(:id) because the AccountNotificationRole may have an
      # explicitly nil role_id to indicate the announcement's intended for
      # users not enrolled in any courses
      role_ids = announcement.account_notification_roles.map{ |anr| anr.role.try(:id) }

      unless role_ids.empty? || user_role_ids.key?(announcement.account_id)
        # choose enrollments and account users to inspect
        if announcement.account.site_admin?
          enrollments = user.enrollments.shard(user).active.uniq.select(:role_id)
          account_users = user.account_users.shard(user).uniq.select(:role_id)
        else
          enrollments = user.enrollments_for_account_and_sub_accounts(account).select(:role_id)
          account_users = account.all_account_users_for(user)
        end

        # preload role objects for those enrollments and account users
        ActiveRecord::Associations::Preloader.new(enrollments, [:role]).run
        ActiveRecord::Associations::Preloader.new(account_users, [:role]).run

        # map to role ids. user role.id instead of role_id to trigger Role#id
        # magic for built in roles. announcements intended for users not
        # enrolled in any courses have the NilEnrollment role type
        user_role_ids[announcement.account_id] = enrollments.map{ |e| e.role.id }
        user_role_ids[announcement.account_id] = [nil] if user_role_ids[announcement.account_id].empty?
        user_role_ids[announcement.account_id] |= account_users.map{ |au| au.role.id }
      end

      role_ids.empty? || (role_ids & user_role_ids[announcement.account_id]).present?
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

      roles = user.enrollments.shard(user).active.uniq.pluck(:type)

      if roles == ['StudentEnrollment'] && !account.include_students_in_global_survey?
        current.reject! { |announcement| announcement.required_account_service == 'account_survey_notifications' }
      end
    end

    current
  end

  def self.for_account(account)
    # Refreshes every 10 minutes at the longest
    Rails.cache.fetch(['account_notifications2', account].cache_key, :expires_in => 10.minutes) do
      now = Time.now.utc
      # we always check the given account for the flag, even if the announcement is from the site_admin account
      # this allows us to make a global announcement that is filtered to only accounts with this flag
      enabled_flags = ACCOUNT_SERVICE_NOTIFICATION_FLAGS & account.allowed_services_hash.keys.map(&:to_s)

      Shard.partition_by_shard([Account.site_admin, account]) do |accounts|
        AccountNotification.where("account_id IN (?) AND start_at <? AND end_at>?", accounts, now, now).
          where("required_account_service IS NULL OR required_account_service IN (?)", enabled_flags).
          order('start_at DESC').all
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
