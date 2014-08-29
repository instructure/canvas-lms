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
  # You should start thinking about communication channels
  # as independent of pseudonyms
  include Workflow

  attr_accessible :user, :path, :path_type, :build_pseudonym_on_confirm, :pseudonym

  belongs_to :pseudonym
  has_many :pseudonyms
  belongs_to :user
  has_many :notification_policies, :dependent => :destroy
  has_many :delayed_messages
  has_many :messages
  belongs_to :access_token

  EXPORTABLE_ATTRIBUTES = [
    :id, :path, :path_type, :position, :user_id, :pseudonym_id, :bounce_count, :workflow_state, :confirmation_code,
    :created_at, :updated_at, :build_pseudonym_on_confirm
  ]

  EXPORTABLE_ASSOCIATIONS = [:pseudonyms, :pseudonym, :user]

  before_save :assert_path_type, :set_confirmation_code
  before_save :consider_building_pseudonym
  validates_presence_of :path, :path_type, :user, :workflow_state
  validate :uniqueness_of_path
  validate :not_otp_communication_channel, :if => lambda { |cc| cc.path_type == TYPE_SMS && cc.retired? && !cc.new_record? }
  validates_presence_of :access_token_id, if: lambda { |cc| cc.path_type == TYPE_PUSH }

  acts_as_list :scope => :user

  has_a_broadcast_policy

  attr_reader :request_password
  attr_reader :send_confirmation

  # Constants for the different supported communication channels
  TYPE_EMAIL    = 'email'
  TYPE_SMS      = 'sms'
  TYPE_TWITTER  = 'twitter'
  TYPE_FACEBOOK = 'facebook'
  TYPE_PUSH     = 'push'

  RETIRE_THRESHOLD = 3

  def self.sms_carriers
    @sms_carriers ||= Canvas::ICU.collate_by((ConfigFile.load('sms', false) ||
        { 'AT&T' => 'txt.att.net',
          'Alltel' => 'message.alltel.com',
          'Boost' => 'myboostmobile.com',
          'C Spire' => 'cspire1.com',
          'Cingular' => 'cingularme.com',
          'CellularOne' => 'mobile.celloneusa.com',
          'Cricket' => 'sms.mycricket.com',
          'Nextel' => 'messaging.nextel.com',
          'Sprint PCS' => 'messaging.sprintpcs.com',
          'T-Mobile' => 'tmomail.net',
          'Verizon' => 'vtext.com',
          'Virgin Mobile' => 'vmobl.com' }), &:first)
  end

  def pseudonym
    user.pseudonyms.where(:unique_id => path).first if user
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

  def uniqueness_of_path
    return if path.nil?
    return if retired?
    return unless user_id
    scope = self.class.by_path(path).where(user_id: user_id, path_type: path_type, workflow_state: ['unconfirmed', 'active'])
    unless new_record?
      scope = scope.where("id<>?", id)
    end
    if scope.exists?
      self.errors.add(:path, :taken, :value => path)
    end
  end

  def not_otp_communication_channel
    self.errors.add(:workflow_state, "Can't remove a user's SMS that is used for one time passwords") if self.id == self.user.otp_communication_channel_id
  end

  def context
    pseudonym.try(:account)
  end

  # Public: Determine if this channel is the product of an SIS import.
  #
  # Returns a boolean.
  def imported?
    id.present? &&
      Pseudonym.where(:sis_communication_channel_id => self).exists?
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
    elsif self.path_type == TYPE_PUSH
      access_token.purpose ? "#{access_token.purpose} (#{access_token.developer_key.name})" : access_token.developer_key.name
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

  def send_otp!(code)
    m = self.messages.scoped.new
    m.to = self.path
    m.body = t :body, "Your Canvas verification code is %{verification_code}", :verification_code => code
    Mailer.create_message(m).deliver rescue nil # omg! just ignore delivery failures
  end

  # If you are creating a new communication_channel, do nothing, this just
  # works.  If you are resetting the confirmation_code, call @cc.
  # set_confirmation_code(true), or just save the record to leave the old
  # confirmation code in place. 
  def set_confirmation_code(reset=false)
    self.confirmation_code = nil if reset
    if self.path_type == TYPE_EMAIL or self.path_type.nil?
      self.confirmation_code ||= CanvasSlug.generate(nil, 25)
    else
      self.confirmation_code ||= CanvasSlug.generate
    end
    true
  end
  
  scope :for, lambda { |context|
    case context
    when User
      where(:user_id => context)
    when Notification
      includes(:notification_policies).where(:notification_policies => { :notification_id => context })
    else
      scoped
    end
  }

  def self.by_path_condition(path)
    if %{mysql mysql2}.include?(connection_pool.spec.config[:adapter])
      path
    else
      "LOWER(#{path})"
    end
  end
  scope :by_path, lambda { |path|
    where("#{by_path_condition("communication_channels.path")}=#{by_path_condition("?")}", path)
  }

  scope :email, -> { where(:path_type => TYPE_EMAIL) }
  scope :sms, -> { where(:path_type => TYPE_SMS) }

  scope :active, -> { where(:workflow_state => 'active') }
  scope :unretired, -> { where("communication_channels.workflow_state<>'retired'") }

  scope :for_notification_frequency, lambda { |notification, frequency|
    joins(:notification_policies).where(:notification_policies => { :notification_id => notification, :frequency => frequency })
  }

  # Get the list of communication channels that overrides an association's default order clause.
  # This returns an unretired and properly ordered already fetch array of CommunicationChannel objects ready for usage.
  def self.all_ordered_for_display(user)
    # Add communication channel for users that already had Twitter
    # integrated before we started offering it as a cc
    twitter_service = user.user_services.for_service(CommunicationChannel::TYPE_TWITTER).first
    twitter_service.assert_communication_channel if twitter_service

    rank_order = [TYPE_EMAIL, TYPE_SMS, TYPE_PUSH]
    # Add facebook and twitter (in that order) if the user's account is setup for them.
    rank_order << TYPE_FACEBOOK unless user.user_services.for_service(CommunicationChannel::TYPE_FACEBOOK).empty?
    rank_order << TYPE_TWITTER if twitter_service
    self.unretired.where('communication_channels.path_type IN (?)', rank_order).
      order("#{self.rank_sql(rank_order, 'communication_channels.path_type')} ASC, communication_channels.position asc").
      all
  end

  scope :include_policies, -> { includes(:notification_policies) }

  scope :in_state, lambda { |state| where(:workflow_state => state.to_s) }
  scope :of_type, lambda { |type| where(:path_type => type) }
  
  def can_notify?
    self.notification_policies.any? { |np| np.frequency == 'never' } ? false : true
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
        Pseudonym.where(:user_id => old_user_id, :unique_id => self.path).update_all(:user_id => user)
        User.where(:id => [old_user_id, user]).update_all(:updated_at => Time.now.utc)
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
      event :re_activate, :transitions_to => :active
    end
  end

  # This is setup as a default in the database, but this overcomes misspellings.
  def assert_path_type
    valid_types = [TYPE_EMAIL, TYPE_SMS, TYPE_FACEBOOK, TYPE_TWITTER, TYPE_PUSH]
    self.path_type = TYPE_EMAIL unless valid_types.include?(path_type)
    true
  end
  protected :assert_path_type
    
  def self.serialization_excludes; [:confirmation_code]; end

  def self.associated_shards(path)
    [Shard.default]
  end

  def merge_candidates(break_on_first_found = false)
    shards = self.class.associated_shards(self.path) if Enrollment.cross_shard_invitations?
    shards ||= [self.shard]
    scope = CommunicationChannel.active.by_path(self.path).of_type(self.path_type)
    merge_candidates = {}
    Shard.with_each_shard(shards) do
      scope = scope.shard(Shard.current)
      scope.where("user_id<>?", self.user_id).includes(:user).map(&:user).select do |u|
        result = merge_candidates.fetch(u.global_id) do
          merge_candidates[u.global_id] = (u.all_active_pseudonyms.length != 0)
        end
        return [u] if result && break_on_first_found
        result
      end
    end.uniq
  end

  def has_merge_candidates?
    !merge_candidates(true).empty?
  end

    def self.create_push(access_token, device_token)
      (scoped.shard_value || Shard.current).activate do
        connection.transaction do
          cc = new
          cc.path_type = CommunicationChannel::TYPE_PUSH
          cc.path = device_token
          cc.access_token = access_token
          cc.workflow_state = 'active'

          # save first, so we can put the global id in it
          cc.save!
          response = DeveloperKey.sns.client.create_platform_endpoint(
              platform_application_arn: access_token.developer_key.sns_arn,
              token: device_token,
              custom_user_data: cc.global_id.to_s
          )

          cc.internal_path = response.data[:endpoint_arn]
          cc.save!
          cc
        end
      end
    end

  def bouncing?
    self.bounce_count >= RETIRE_THRESHOLD
  end

  def self.bounce_for_path(path)
    Shard.with_each_shard(CommunicationChannel.associated_shards(path)) do
      CommunicationChannel.unretired.email.by_path(path).each do |channel|
        channel.update_attribute(:bounce_count, channel.bounce_count + 1)
      end
    end
  end
end
