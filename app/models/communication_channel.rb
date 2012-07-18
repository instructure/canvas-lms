#
# Copyright (C) 2011 Instructure, Inc.
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

class CommunicationChannel < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  # You should start thinking about communication channels
  # as independent of pseudonyms
  include Workflow

  attr_accessible :user, :path, :path_type, :build_pseudonym_on_confirm, :pseudonym

  belongs_to :pseudonym
  has_many :pseudonyms
  belongs_to :user
  has_many :notification_policies, :dependent => :destroy
  has_many :messages
  
  before_save :consider_retiring, :assert_path_type, :set_confirmation_code
  before_save :consider_building_pseudonym
  validates_presence_of :path
  validate :uniqueness_of_path

  acts_as_list :scope => :user_id
  
  has_a_broadcast_policy
  
  attr_reader :request_password
  attr_reader :send_confirmation

  # Constants for the different supported communication channels
  TYPE_EMAIL    = 'email'
  TYPE_SMS      = 'sms'
  TYPE_CHAT     = 'chat'
  TYPE_TWITTER  = 'twitter'
  TYPE_FACEBOOK = 'facebook'

  def pseudonym
    self.user.pseudonyms.find_by_unique_id(self.path)
  end

  set_broadcast_policy do |p|
    p.dispatch :forgot_password
    p.to { self }
    p.whenever { |record|
      @request_password
    }
    
    p.dispatch :confirm_registration
    p.to { self }
    p.whenever { |record|
      @send_confirmation and
      (record.workflow_state == 'active' || 
        (record.workflow_state == 'unconfirmed' and (self.user.pre_registered? || self.user.creation_pending?))) and
      self.path_type == TYPE_EMAIL
    }

    p.dispatch :confirm_email_communication_channel
    p.to { self }
    p.whenever { |record| 
      @send_confirmation and
      record.workflow_state == 'unconfirmed' and self.user.registered? and
      self.path_type == TYPE_EMAIL
    }
    p.context { @root_account }
    
    p.dispatch :merge_email_communication_channel
    p.to { self }
    p.whenever {|record|
      @send_merge_notification and
      self.path_type == TYPE_EMAIL
    }
    
    p.dispatch :confirm_sms_communication_channel
    p.to { self }
    p.whenever { |record|
      @send_confirmation and
      record.workflow_state == 'unconfirmed' and
      self.path_type == TYPE_SMS and
      !self.user.creation_pending?
    }
    p.context { @root_account }
  end

  def active_pseudonyms
    self.user.pseudonyms.active
  end
  memoize :active_pseudonyms

  def uniqueness_of_path
    return if path.nil?
    return if retired?
    return unless user_id
    conditions = ["LOWER(path)=? AND user_id=? AND path_type=? AND workflow_state IN('unconfirmed', 'active')", path.mb_chars.downcase, user_id, path_type]
    unless new_record?
      conditions.first << " AND id<>?"
      conditions << id
    end
    if self.class.exists?(conditions)
      self.errors.add(:path, :taken, :value => path)
    end
  end

  # Return the 'path' for simple communication channel types like email and sms. For
  # Facebook and Twitter, return the user's configured user_name for the service.
  def path_description
    if self.path_type == TYPE_FACEBOOK
      res = self.user.user_services.for_service(TYPE_FACEBOOK).first.service_user_name rescue nil
      res ||= t :default_facebook_account, 'Facebook Account'
      res
    elsif self.path_type == TYPE_TWITTER
      res = self.user.user_services.for_service(TYPE_TWITTER).first.service_user_name rescue nil
      res ||= t :default_twitter_handle, 'Twitter Handle'
      res
    else
      self.path
    end
  end
  
  def forgot_password!
    @request_password = true
    set_confirmation_code(true)
    self.save!
    @request_password = false
  end
  
  def send_confirmation!(root_account)
    @send_confirmation = true
    @root_account = root_account
    self.save!
    @root_account = nil
    @send_confirmation = false
  end
  
  def send_merge_notification!
    @send_merge_notification = true
    self.save!
    @send_merge_notification = false
  end
  
  # If you are creating a new communication_channel, do nothing, this just
  # works.  If you are resetting the confirmation_code, call @cc.
  # set_confirmation_code(true), or just save the record to leave the old
  # confirmation code in place. 
  def set_confirmation_code(reset=false)
    self.confirmation_code = nil if reset
    if self.path_type == TYPE_EMAIL or self.path_type.nil?
      self.confirmation_code ||= AutoHandle.generate(nil, 25)
    else
      self.confirmation_code ||= AutoHandle.generate
    end
  end
  
  named_scope :for, lambda { |context| 
    case context
    when User
      { :conditions => ['communication_channels.user_id = ?', context.id] }
    when Notification
      { :include => [:notification_policies], :conditions => ['notification_policies.notification_id = ?', context.id] }
    else
      {}
    end
  }

  named_scope :by_path, lambda { |path|
    if connection_pool.spec.config[:adapter] == 'mysql'
      { :conditions => {:path => path } }
    else
      { :conditions => ["LOWER(communication_channels.path)=?", path.try(:downcase)]}
    end
  }

  named_scope :email, :conditions => { :path_type => TYPE_EMAIL }
  named_scope :active, :conditions => { :workflow_state => 'active' }
  named_scope :unretired, :conditions => ['communication_channels.workflow_state<>?', 'retired']

  named_scope :for_notification_frequency, lambda {|notification, frequency|
    { :include => [:notification_policies], :conditions => ['notification_policies.notification_id = ? and notification_policies.frequency = ?', notification.id, frequency] }
  }

  # Get the list of communication channels that overrides an association's default order clause.
  # This returns an unretired and properly ordered already fetch array of CommunicationChannel objects ready for usage.
  def self.all_ordered_for_display(user)
    # Add communication channel for users that already had Twitter
    # integrated before we started offering it as a cc
    twitter_service = user.user_services.for_service(CommunicationChannel::TYPE_TWITTER).first
    twitter_service.assert_communication_channel if twitter_service

    rank_order = [TYPE_EMAIL, TYPE_SMS]
    # Add facebook and twitter (in that order) if the user's account is setup for them.
    rank_order << TYPE_FACEBOOK unless user.user_services.for_service(CommunicationChannel::TYPE_FACEBOOK).empty?
    rank_order << TYPE_TWITTER if twitter_service
    self.unretired.scoped(:conditions => ['communication_channels.path_type IN (?)', rank_order]).
      find(:all, :order => "#{self.rank_sql(rank_order, 'communication_channels.path_type')} ASC, communication_channels.position asc")
  end

  named_scope :include_policies, :include => :notification_policies

  named_scope :in_state, lambda { |state| { :conditions => ["communication_channels.workflow_state = ?", state.to_s]}}
  named_scope :of_type, lambda {|type| { :conditions => ['communication_channels.path_type = ?', type] } }
  
  def can_notify?
    self.notification_policies.any? { |np| np.frequency == 'never' } ? false : true
  end
  
  # This is the re-worked find_for_all.  It is created to get all
  # communication channels that have a specific, valid notification policy
  # setup for it, or the default communication channel for a user.  This,
  # of course, doesn't hold for registration, since no policy is expected
  # to intervene.  All registration notices go to the passed-in
  # communication channel.  That information is being handed to us from
  # the context of the notification policy being fired. 
  def self.find_all_for(user=nil, notification=nil, cc=nil, frequency='immediately')
    return [] unless user && notification
    return [cc] if cc and notification.registration?
    return [] unless user.registered?
    policy_matches_frequency = {}
    policy_for_channel = {}
    can_notify = {}
    NotificationPolicy.for(user).for(notification).each do |policy|
      policy_matches_frequency[policy.communication_channel_id] = true if policy.frequency == frequency
      policy_for_channel[policy.communication_channel_id] = true
      can_notify[policy.communication_channel_id] = false if policy.frequency == 'never'
    end
    all_channels = user.communication_channels.active
    communication_channels = all_channels.select{|cc| policy_matches_frequency[cc.id] }
    all_channels = all_channels.select{|cc| policy_for_channel[cc.id] }

    # The trick here is that if the user has ANY policies defined for this notification
    # then we shouldn't overwrite it with the default channel -- but we only want to
    # return the list of channels for immediate dispatch.
    communication_channels = [user.email_channel] if all_channels.empty? && notification.default_frequency == 'immediately'
    communication_channels.compact!

    # Remove ALL channels if one is 'never'?  No, I think we should just remove any paths that are set to 'never'
    # User can say NEVER email me, but SMS me right away.
    communication_channels.reject!{|cc| can_notify[cc] == false}
    communication_channels
  end
  
  def self.ids_with_pending_delayed_messages
    CommunicationChannel.connection.select_values(
      "SELECT distinct communication_channel_id
         FROM delayed_messages
        WHERE workflow_state = 'pending' AND send_at <= '#{Time.now.to_s(:db)}'")
  end
  
  def move_to_user(user, migrate=true)
    return unless user
    if self.pseudonym && self.pseudonym.unique_id == self.path
      self.pseudonym.move_to_user(user, migrate)
    else
      old_user_id = self.user_id
      self.user_id = user.id
      self.save!
      if old_user_id
        Pseudonym.update_all({:user_id => user.id}, {:user_id => old_user_id, :unique_id => self.path})
        User.update_all({:updated_at => Time.now.utc}, {:id => [old_user_id, user.id]})
      end
    end
  end
  
  def consider_building_pseudonym
    if self.build_pseudonym_on_confirm && self.active?
      self.build_pseudonym_on_confirm = false
      pseudonym = self.user.pseudonyms.build(:unique_id => self.path, :account => Account.default)
      existing_pseudonym = self.user.pseudonyms.active.select{|p| p.account_id == Account.default.id }.first
      if existing_pseudonym
        pseudonym.password_salt = existing_pseudonym.password_salt
        pseudonym.crypted_password = existing_pseudonym.crypted_password
      end
      pseudonym.save!
    end
    true
  end
  
  def consider_retiring
    self.retire if self.bounce_count >= 5
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'retired'
    self.save
  end
  
  workflow do
    state :unconfirmed do
      event :confirm, :transitions_to => :active do
        self.set_confirmation_code(true)
      end
      event :retire, :transitions_to => :retired
    end
    
    state :active do
      event :retire, :transitions_to => :retired
    end
    
    state :retired do
      event :re_activate, :transitions_to => :active do
        self.bounce_count = 0
      end
    end
  end

  # This is setup as a default in the database, but this overcomes misspellings.
  def assert_path_type
    pt = self.path_type
    self.path_type = TYPE_EMAIL unless pt == TYPE_EMAIL or pt == TYPE_SMS or pt == TYPE_CHAT or pt == TYPE_FACEBOOK or pt == TYPE_TWITTER
  end
  protected :assert_path_type
    
  def self.serialization_excludes; [:confirmation_code]; end
end
