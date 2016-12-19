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

  serialize :last_bounce_details
  serialize :last_transient_bounce_details

  belongs_to :pseudonym
  has_many :pseudonyms
  belongs_to :user
  has_many :notification_policies, :dependent => :destroy
  has_many :delayed_messages, :dependent => :destroy
  has_many :messages

  before_save :assert_path_type, :set_confirmation_code
  before_save :consider_building_pseudonym
  validates_presence_of :path, :path_type, :user, :workflow_state
  validate :uniqueness_of_path
  validate :not_otp_communication_channel, :if => lambda { |cc| cc.path_type == TYPE_SMS && cc.retired? && !cc.new_record? }
  after_commit :check_if_bouncing_changed

  acts_as_list :scope => :user

  has_a_broadcast_policy

  attr_reader :request_password
  attr_reader :send_confirmation

  # Constants for the different supported communication channels
  TYPE_EMAIL    = 'email'
  TYPE_SMS      = 'sms'
  TYPE_TWITTER  = 'twitter'
  TYPE_PUSH     = 'push'
  TYPE_YO       = 'yo'

  RETIRE_THRESHOLD = 1

  def self.country_codes
    # [country code, name, true if email should be used instead of Twilio]
    [
      ['54',   I18n.t('Argentina (+54)'),              false],
      ['61',   I18n.t('Australia (+61)'),              false],
      ['43',   I18n.t('Austria (+43)'),                false],
      ['32',   I18n.t('Belgium (+32)'),                false],
      ['591',  I18n.t('Bolivia (+591)'),               false],
      ['55',   I18n.t('Brazil (+55)'),                 false],
      ['1',    I18n.t('Canada (+1)'),                  false],
      ['56',   I18n.t('Chile (+56)'),                  false],
      ['57',   I18n.t('Colombia (+57)'),               false],
      ['506',  I18n.t('Costa Rica (+506)'),            false],
      ['45',   I18n.t('Denmark (+45)'),                false],
      ['593',  I18n.t('Ecuador (+593)'),               false],
      ['358',  I18n.t('Finland (+358)'),               false],
      ['33',   I18n.t('France (+33)'),                 false],
      ['49',   I18n.t('Germany (+49)'),                false],
      ['504',  I18n.t('Honduras (+504)'),              false],
      ['852',  I18n.t('Hong Kong (+852)'),             false],
      ['91',   I18n.t('India (+91)'),                  false],
      ['353',  I18n.t('Ireland (+353)'),               false],
      ['972',  I18n.t('Israel (+972)'),                false],
      ['39',   I18n.t('Italy (+39)'),                  false],
      ['81',   I18n.t('Japan (+81)'),                  false],
      ['352',  I18n.t('Luxembourg (+352)'),            false],
      ['60',   I18n.t('Malaysia (+60)'),               false],
      ['52',   I18n.t('Mexico (+52)'),                 false],
      ['31',   I18n.t('Netherlands (+31)'),            false],
      ['64',   I18n.t('New Zealand (+64)'),            false],
      ['47',   I18n.t('Norway (+47)'),                 false],
      ['507',  I18n.t('Panama (+507)'),                false],
      ['595',  I18n.t('Paraguay (+595)'),              false],
      ['51',   I18n.t('Peru (+51)'),                   false],
      ['63',   I18n.t('Philippines (+63)'),            false],
      ['48',   I18n.t('Poland (+48)'),                 false],
      ['974',  I18n.t('Qatar (+974)'),                 false],
      ['966',  I18n.t('Saudi Arabia (+966)'),          false],
      ['65',   I18n.t('Singapore (+65)'),              false],
      ['82',   I18n.t('South Korea (+82)'),            false],
      ['34',   I18n.t('Spain (+34)'),                  false],
      ['46',   I18n.t('Sweden (+46)'),                 false],
      ['41',   I18n.t('Switzerland (+41)'),            false],
      ['971',  I18n.t('United Arab Emirates (+971)'),  false],
      ['44',   I18n.t('United Kingdom (+44)'),         false],
      ['1',    I18n.t('United States (+1)'),           true ],
      ['598',  I18n.t('Uruguay (+598)'),               false]
    ].sort_by{ |a| Canvas::ICU.collation_key(a[1]) }
  end

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

  set_policy do
    given { |user| self.user.grants_right?(user, :manage_user_details) }
    can :force_confirm

    given { |user| Account.site_admin.grants_right?(user, :read_messages) }
    can :reset_bounce_count
    can :read_bounce_details
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

  # Public: Build the url where this record can be confirmed.
  #
  #
  # Returns a string.
  def confirmation_url
    return "" unless path_type == TYPE_EMAIL
    "#{HostUrl.protocol}://#{HostUrl.context_host(context)}/register/#{confirmation_code}"
  end

  def context
    pseudonym&.account || user.pseudonym&.account
  end

  # Public: Determine if this channel is the product of an SIS import.
  #
  # Returns a boolean.
  def imported?
    id.present? &&
      Pseudonym.where(:sis_communication_channel_id => self).exists?
  end

  # Return the 'path' for simple communication channel types like email and sms. For
  # Yo and Twitter, return the user's configured user_name for the service.
  def path_description
    if self.path_type == TYPE_TWITTER
      res = self.user.user_services.for_service(TYPE_TWITTER).first.service_user_name rescue nil
      res ||= t :default_twitter_handle, 'Twitter Handle'
      res
    elsif self.path_type == TYPE_YO
      res = self.user.user_services.for_service(TYPE_YO).first.service_user_name rescue nil
      res ||= t :default_yo_name, 'Yo Name'
      res
    elsif self.path_type == TYPE_PUSH
      t 'For All Devices'
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
    m = self.messages.temp_record
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
      eager_load(:notification_policies).where(:notification_policies => { :notification_id => context })
    else
      all
    end
  }

  def self.by_path_condition(path)
    Arel::Nodes::NamedFunction.new('lower', [Arel::Nodes.build_quoted(path)])
  end

  scope :by_path, ->(path) { where(by_path_condition(arel_table[:path]).eq(by_path_condition(path))) }
  scope :path_like, ->(path) { where(by_path_condition(arel_table[:path]).matches(by_path_condition(path))) }

  scope :email, -> { where(path_type: TYPE_EMAIL) }
  scope :sms, -> { where(path_type: TYPE_SMS) }

  scope :active, -> { where(workflow_state: 'active') }
  scope :unretired, -> { where.not(workflow_state: 'retired') }

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
    # Add twitter and yo (in that order) if the user's account is setup for them.
    rank_order << TYPE_TWITTER if twitter_service
    rank_order << TYPE_YO unless user.user_services.for_service(CommunicationChannel::TYPE_YO).empty?
    self.unretired.where('communication_channels.path_type IN (?)', rank_order).
      order("#{self.rank_sql(rank_order, 'communication_channels.path_type')} ASC, communication_channels.position asc").to_a
  end

  scope :include_policies, -> { preload(:notification_policies) }

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
        User.where(:id => [old_user_id, user]).touch_all
      end
    end
  end

  def consider_building_pseudonym
    if self.build_pseudonym_on_confirm && self.active?
      self.build_pseudonym_on_confirm = false
      pseudonym = self.user.pseudonyms.build(:unique_id => self.path, :account => Account.default)
      existing_pseudonym = self.user.pseudonyms.active.find{|p| p.account_id == Account.default.id }
      if existing_pseudonym
        pseudonym.password_salt = existing_pseudonym.password_salt
        pseudonym.crypted_password = existing_pseudonym.crypted_password
      end
      pseudonym.save!
    end
    true
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'retired'
    self.save
  end

  workflow do
    state :unconfirmed do
      event :confirm, :transitions_to => :active do
        self.set_confirmation_code
      end
      event :retire, :transitions_to => :retired
    end

    state :active do
      event :retire, :transitions_to => :retired
    end

    state :retired do
      event :re_activate, :transitions_to => :active do
        # Reset bounce count when we're being reactivated
        reset_bounce_count!
      end
    end
  end

  # This is setup as a default in the database, but this overcomes misspellings.
  def assert_path_type
    valid_types = [TYPE_EMAIL, TYPE_SMS, TYPE_TWITTER, TYPE_PUSH, TYPE_YO]
    self.path_type = TYPE_EMAIL unless valid_types.include?(path_type)
    true
  end
  protected :assert_path_type

  def self.serialization_excludes; [:confirmation_code]; end

  def self.associated_shards(path)
    [Shard.default]
  end

  def merge_candidates(break_on_first_found = false)
    return [] if path_type == 'push'
    shards = self.class.associated_shards(self.path) if Enrollment.cross_shard_invitations?
    shards ||= [self.shard]
    scope = CommunicationChannel.active.by_path(self.path).of_type(self.path_type)
    merge_candidates = {}
    Shard.with_each_shard(shards) do
      scope = scope.shard(Shard.current)
      scope.where("user_id<>?", self.user_id).preload(:user).map(&:user).select do |u|
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

  def bouncing?
    self.bounce_count >= RETIRE_THRESHOLD
  end

  def was_bouncing?
    old_bounce_count = self.previous_changes[:bounce_count].try(:first)
    old_bounce_count ||= self.bounce_count
    old_bounce_count >= RETIRE_THRESHOLD
  end

  def reset_bounce_count!
    self.bounce_count = 0
    self.save!
  end

  def was_retired?
    old_workflow_state = self.previous_changes[:workflow_state].try(:first)
    old_workflow_state ||= self.workflow_state
    old_workflow_state.to_s == 'retired'
  end

  def check_if_bouncing_changed
    if retired?
      self.user.update_bouncing_channel_message!(self) if !was_retired? && was_bouncing?
    else
      if (was_retired? && bouncing?) || (was_bouncing? != bouncing?)
        self.user.update_bouncing_channel_message!(self)
      end
    end
  end
  private :check_if_bouncing_changed

  def self.bounce_for_path(path:, timestamp:, details:, permanent_bounce:, suppression_bounce:)
    Shard.with_each_shard(CommunicationChannel.associated_shards(path)) do
      CommunicationChannel.unretired.email.by_path(path).each do |channel|
        channel.bounce_count = channel.bounce_count + 1 if permanent_bounce

        if suppression_bounce
          channel.last_suppression_bounce_at = timestamp
        elsif permanent_bounce
          channel.last_bounce_at = timestamp
          channel.last_bounce_details = details
        else
          channel.last_transient_bounce_at = timestamp
          channel.last_transient_bounce_details = details
        end

        channel.save!
      end
    end
  end

  def last_bounce_summary
    last_bounce_details.try(:[], 'bouncedRecipients').try(:[], 0).try(:[], 'diagnosticCode')
  end

  def last_transient_bounce_summary
    last_transient_bounce_details.try(:[], 'bouncedRecipients').try(:[], 0).try(:[], 'diagnosticCode')
  end

  def self.find_by_confirmation_code(code)
    where(confirmation_code: code).first

  end
end
