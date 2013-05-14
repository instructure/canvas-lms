class AccountNotification < ActiveRecord::Base
  attr_accessible :subject, :icon, :message,
    :account, :user, :start_at, :end_at

  validates_presence_of :start_at, :end_at, :account_id
  before_validation :infer_defaults
  belongs_to :account, :touch => true
  belongs_to :user
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => false, :allow_blank => false
  sanitize_field :message, Instructure::SanitizeField::SANITIZE
  
  def infer_defaults
    self.start_at ||= Time.now.utc
    self.end_at ||= self.start_at + 2.weeks
    self.end_at = [self.end_at, self.start_at].max
  end

  def self.for_user_and_account(user, account)
    closed_ids = user.preferences[:closed_notifications] || []
    now = Time.now.utc
    # Refreshes every 10 minutes at the longest
    current = Rails.cache.fetch(['account_notifications2', account].cache_key, :expires_in => 10.minutes) do
      Shard.partition_by_shard([Account.site_admin, account]) do |accounts|
        AccountNotification.where("account_id IN (?) AND start_at <? AND end_at>?", accounts, now, now).order('start_at DESC').all
      end
    end

    user.shard.activate do
      # If there are ids marked as 'closed' that are no longer
      # applicable, they probably need to be cleared out.
      current_ids = current.map(&:id)
      if !(closed_ids - current_ids).empty?
        closed_ids = user.preferences[:closed_notifications] &= current_ids
        user.save!
      end
      current.reject { |announcement| closed_ids.include?(announcement.id) }
    end
  end
end
