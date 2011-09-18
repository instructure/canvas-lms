class AccountNotification < ActiveRecord::Base
  attr_accessible :subject, :icon, :message,
    :account, :user, :start_at, :end_at

  validates_presence_of :start_at
  before_save :infer_defaults
  after_save :touch_account
  belongs_to :account
  belongs_to :user
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => false, :allow_blank => false
  sanitize_field :message, Instructure::SanitizeField::SANITIZE
  
  def infer_defaults
    end_at ||= start_at + 2.weeks
    end_at = [end_at, start_at].max
  end
  
  def touch_account
    Account.update_all({:updated_at => Time.now.utc}, {:id => self.account_id}) if self.account_id
  end
  
  named_scope :for_account, lambda{|account|
    {:conditions => ['account_id = ? AND end_at > ?', account.id, Time.now], :order => 'start_at' }
  }
  
  def self.for_user_and_account(user, account)
    closed_ids = (user && user.preferences[:closed_notifications]) || []
    now = Time.now.utc
    # Refreshes every 10 minutes at the longest
    current = AccountNotification.find_all_cached(['account_notifications', account, (now.to_i / 600).to_s].cache_key) do
      AccountNotification.find(:all, :conditions => ['account_id IN (?,?) AND start_at < ? AND end_at > ?', Account.site_admin.id, account.id, now, now], :order => 'start_at DESC')
    end
    current ||= []
    # If there are ids marked as 'closed' that are no longer
    # applicable, they probably need to be cleared out.
    if !(closed_ids - current.map(&:id)).empty?
      Rails.cache.fetch(['old_closed_notifications', user.id].cache_key, :expires_in => 60.minutes) do
        old_closed = AccountNotification.find(:all, :conditions => ["id IN (#{closed_ids.join(',')}) AND end_at < ?", now]) unless closed_ids.empty?
        if !old_closed.empty?
          user.preferences[:closed_notifications] -= old_closed.map(&:id)
          user.save!
        end
      end
    end
    for_user = current.reject{|n| closed_ids.include?(n.id) }
  end
end
