class AccountNotification < ActiveRecord::Base
  attr_accessible :subject, :icon, :message,
    :account, :user, :start_at, :end_at,
    :required_account_service, :months_in_display_cycle

  validates_presence_of :start_at, :end_at, :account_id
  before_validation :infer_defaults
  belongs_to :account, :touch => true
  belongs_to :user
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => false, :allow_blank => false
  sanitize_field :message, Instructure::SanitizeField::SANITIZE

  ACCOUNT_SERVICE_NOTIFICATION_FLAGS = %w[account_survey_notifications]
  validates_inclusion_of :required_account_service, in: ACCOUNT_SERVICE_NOTIFICATION_FLAGS, allow_nil: true

  validates_inclusion_of :months_in_display_cycle, in: 1..48, allow_nil: true

  def infer_defaults
    self.start_at ||= Time.now.utc
    self.end_at ||= self.start_at + 2.weeks
    self.end_at = [self.end_at, self.start_at].max
  end

  def self.for_user_and_account(user, account)
    current = self.for_account(account)

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
