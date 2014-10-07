#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class Pseudonym < ActiveRecord::Base
  include Workflow

  attr_accessible :user, :account, :password, :password_confirmation, :path, :path_type, :password_auto_generated, :unique_id

  has_many :session_persistence_tokens
  belongs_to :account
  belongs_to :user
  has_many :communication_channels, :order => 'position'
  belongs_to :communication_channel
  belongs_to :sis_communication_channel, :class_name => 'CommunicationChannel'
  MAX_UNIQUE_ID_LENGTH = 100

  CAS_TICKET_EXPIRED = 'expired'

  EXPORTABLE_ATTRIBUTES = [
    :id, :user_id, :account_id, :workflow_state, :unique_id, :login_count, :failed_login_count, :last_request_at, :last_login_at, :current_login_at, :last_login_ip,
    :current_login_ip, :position, :created_at, :updated_at, :deleted_at, :sis_batch_id, :sis_user_id, :sis_ssha, :communication_channel_id, :login_path_to_ignore, :sis_communication_channel_id
  ]

  EXPORTABLE_ASSOCIATIONS = [:account, :user, :communication_channels, :communication_channel, :sis_communication_channel]

  validates_length_of :unique_id, :maximum => MAX_UNIQUE_ID_LENGTH
  validates_length_of :sis_user_id, :maximum => maximum_string_length, :allow_blank => true
  validates_presence_of :account_id
  # allows us to validate the user and pseudonym together, before saving either
  validates_each :user_id do |record, attr, value|
    record.errors.add(attr, "blank?") unless value || record.user
  end
  before_validation :validate_unique_id
  before_destroy :retire_channels

  before_save :set_password_changed
  before_validation :infer_defaults, :verify_unique_sis_user_id
  after_save :update_passwords_on_related_pseudonyms
  after_save :update_account_associations_if_account_changed
  has_a_broadcast_policy

  alias_method :context, :account

  include StickySisFields
  are_sis_sticky :unique_id

  validates_each :password, {:if => :require_password?}, &Canvas::PasswordPolicy.method("validate")
  acts_as_authentic do |config|
    config.validates_format_of_login_field_options = {:with => /\A\w[\w\.\+\-_'@ =]*\z/}
    config.login_field :unique_id
    config.validations_scope = [:account_id, :workflow_state]
    config.perishable_token_valid_for = 30.minutes
    config.validates_length_of_login_field_options = {:within => 1..MAX_UNIQUE_ID_LENGTH}
    config.validates_uniqueness_of_login_field_options = { :case_sensitive => false, :scope => [:account_id, :workflow_state], :if => lambda { |p| (p.unique_id_changed? || p.workflow_state_changed?) && p.active? } }
    config.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  attr_writer :require_password
  def require_password?
    # Change from auth_logic: don't require a password just because new_record?
    # is true. just check if the pw has changed or crypted_password_field is
    # blank.
    password_changed? || (send(crypted_password_field).blank? && sis_ssha.blank?) || @require_password
  end

  acts_as_list :scope => :user

  set_broadcast_policy do |p|
    p.dispatch :confirm_registration
    p.to { self.communication_channel || self.user.communication_channel }
    p.whenever { |record|
      @send_confirmation
    }

    p.dispatch :pseudonym_registration
    p.to { self.communication_channel || self.user.communication_channel }
    p.whenever { |record|
      @send_registration_notification
    }
  end
  
  def update_account_associations_if_account_changed
    return unless self.user && !User.skip_updating_account_associations?
    if self.id_was.nil?
      return if %w{creation_pending deleted}.include?(self.user.workflow_state)
      self.user.update_account_associations(:incremental => true, :precalculated_associations => {self.account_id => 0})
    elsif self.account_id_changed?
      self.user.update_account_associations_later
    end
  end

  def root_account_id
    account.root_account_id || account.id
  end

  def send_registration_notification!
    @send_registration_notification = true
    self.save!
    @send_registration_notification = false
  end
  
  def send_confirmation!
    @send_confirmation = true
    self.save!
    @send_confirmation = false
  end

  scope :by_unique_id, lambda { |unique_id|
    where("#{to_lower_column(:unique_id)}=#{to_lower_column('?')}", unique_id)
  }

  def self.to_lower_column(column)
    if %w{mysql mysql2}.include?(connection_pool.spec.config[:adapter])
      column
    else
      "LOWER(#{column})"
    end
  end

  def self.custom_find_by_unique_id(unique_id)
    self.active.by_unique_id(unique_id).first if unique_id
  end
  
  def set_password_changed
    @password_changed = self.password && self.password_confirmation == self.password
  end
  
  def password=(new_pass)
    self.password_auto_generated = false
    super(new_pass)
  end
  
  def communication_channel
    self.user.communication_channels.by_path(self.unique_id).first
  end
  
  def confirmation_code
    (self.communication_channel || self.user.communication_channel).confirmation_code
  end
  
  def infer_defaults
    self.account ||= Account.default
    if (!crypted_password || crypted_password == "") && !@require_password
      self.generate_temporary_password
    end
    self.sis_user_id = nil if self.sis_user_id.blank?
  end
  
  def update_passwords_on_related_pseudonyms
    return if @dont_update_passwords_on_related_pseudonyms || !self.user || self.password_auto_generated
  end
  
  def login_assertions_for_user
    if !self.persistence_token || self.persistence_token == ''
      # Some pseudonyms can end up without a persistence token if they were created
      # using the SIS, for example.
      self.persistence_token = CanvasSlug.generate('pseudo', 15)
      self.save
    end
    
    user = self.user
    user.workflow_state = 'registered' unless user.registered?

    add_ldap_channel
    
    # Assert a time zone for the user if none provided
    if user && !user.time_zone
      user.time_zone = self.account.default_time_zone rescue Account.default.default_time_zone
      user.time_zone ||= Time.zone
    end
    user.save if user.workflow_state_changed? || user.time_zone_changed?
    user
  end
  
  def authentication_type
    :email_login
  end

  def works_for_account?(account, allow_implicit = false)
    true
  end

  def save_without_updating_passwords_on_related_pseudonyms
    @dont_update_passwords_on_related_pseudonyms = true
    self.save
    @dont_update_passwords_on_related_pseudonyms = false
  end

  def <=>(other)
    self.position <=> other.position
  end

  def retire_channels
    communication_channels.each{|cc| cc.update_attribute(:workflow_state, 'retired') }
  end

  def validate_unique_id
    if (!self.account || self.account.email_pseudonyms) && !self.deleted?
      unless self.unique_id.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)
        self.errors.add(:unique_id, "not_email")
        return false
      end
    end
    true
  end

  def verify_unique_sis_user_id
    return true unless self.sis_user_id
    existing_pseudo = Pseudonym.where(account_id: self.account_id, sis_user_id: self.sis_user_id.to_s).first
    return true if !existing_pseudo || existing_pseudo.id == self.id
    self.errors.add(:sis_user_id, t('#errors.sis_id_in_use', "SIS ID \"%{sis_id}\" is already in use", :sis_id => self.sis_user_id))
    false
  end

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy(even_if_managed_password=false)
    raise "Cannot delete system-generated pseudonyms" if !even_if_managed_password && self.managed_password?
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    result = self.save
    self.user.try(:update_account_associations) if result
    result
  end

  def never_logged_in?
    !self.login_count || self.login_count == 0
  end

  def login
    self.unique_id
  end

  def login=(val)
    self.unique_id = val
  end

  def login_changed?
    self.unique_id_changed?
  end

  def user_code
    self.user.uuid rescue nil
  end

  def email
    user.email if user
  end

  def email_channel
    self.communication_channel if self.communication_channel && self.communication_channel.path_type == 'email'
  end

  def email=(e)
    return false unless user
    self.user.email=(e)
    user.save!
    user.email
  end

  def sms
    user.sms if user
  end
  
  def sms=(s)
    return false unless user
    self.user.sms=(s)
    user.save!
    user.sms
  end
  
  def managed_password?
    !!(self.sis_user_id && self.account && !self.account.password_authentication?)
  end

  def system_created?
    !!(self.sis_user_id && self.account)
  end
  
  def valid_arbitrary_credentials?(plaintext_password)
    return false if self.deleted?
    return false if plaintext_password.blank?
    require 'net/ldap'
    account = self.account || Account.default
    res = false
    res ||= valid_ldap_credentials?(plaintext_password) if account && account.ldap_authentication?
    if account.canvas_authentication?
      # Only check SIS if they haven't changed their password
      res ||= valid_ssha?(plaintext_password) if password_auto_generated?
      res ||= valid_password?(plaintext_password)
    end
    res
  end

  def generate_temporary_password
    self.reset_password
    self.password_auto_generated = true
    self.password
  end

  def move_to_user(user, migrate=true)
    return unless user
    return true if self.user_id == user.id
    old_user = self.user
    old_user_id = self.user_id
    self.user = user
    unless self.crypted_password
      self.generate_temporary_password
    end
    self.save
    if old_user_id
      CommunicationChannel.where(:path => self.unique_id, :user_id => old_user_id).update_all(:user_id => user)
      User.where(:id => [old_user_id, user]).update_all(:update_at => Time.now.utc)
    end
    if User.find(old_user_id).pseudonyms.empty? && migrate
      UserMerge.from(old_user).into(user)
    end
  end

  def valid_ssha?(plaintext_password)
    return false if plaintext_password.blank? || self.sis_ssha.blank?
    decoded = Base64::decode64(self.sis_ssha.sub(/\A\{SSHA\}/, ""))
    digest = decoded[0,40]
    salt = decoded[40..-1]
    return false unless digest && salt
    digested_password = Digest::SHA1.digest(plaintext_password + salt).unpack('H*').first
    digest == digested_password
  end

  def ldap_bind_result(password_plaintext)
    self.account.account_authorization_configs.each do |config|
      res = config.ldap_bind_result(self.unique_id, password_plaintext)
      return res if res
    end
    return nil
  end

  def add_ldap_channel
    return nil unless managed_password?
    res = @ldap_result
    if res && res[:mail] && res[:mail][0]
      email = res[:mail][0]
      cc = self.user.communication_channels.email.by_path(email).first
      cc ||= self.user.communication_channels.build(:path => email)
      cc.workflow_state = 'active'
      cc.user = self.user
      cc.save if cc.changed?
      self.communication_channel = cc
      self.save_without_session_maintenance if self.changed?
    end
  end

  attr_reader :ldap_result
  def valid_ldap_credentials?(password_plaintext)
    return false if password_plaintext.blank?
    # try to authenticate against the LDAP server
    res = ldap_bind_result(password_plaintext)
    if res
      @ldap_result = res[0]
    end
    !!res
  rescue => e
    ErrorReport.log_exception(:ldap, e, {
      :message => "LDAP authentication error",
      :object => self.inspect.to_s,
      :unique_id => self.unique_id,
    })
    nil
  end

  scope :active, -> { where(workflow_state: 'active') }

  def self.serialization_excludes; [:crypted_password, :password_salt, :reset_password_token, :persistence_token, :single_access_token, :perishable_token, :sis_ssha]; end

  def self.associated_shards(unique_id_or_sis_user_id)
    [Shard.default]
  end

  def self.find_all_by_arbitrary_credentials(credentials, account_ids, remote_ip)
    return [] if credentials[:unique_id].blank? ||
                 credentials[:password].blank?
    too_many_attempts = false
    associated_shards = associated_shards(credentials[:unique_id])
    pseudonyms = Shard.partition_by_shard(account_ids) do |account_ids|
      next if GlobalLookups.enabled? && !associated_shards.include?(Shard.current)
      active.
        by_unique_id(credentials[:unique_id]).
        where(:account_id => account_ids).
        includes(:user).
        select { |p|
          valid = p.valid_arbitrary_credentials?(credentials[:password])
          too_many_attempts = true if p.audit_login(remote_ip, valid) == :too_many_attempts
          valid
        }
    end
    return :too_many_attempts if too_many_attempts
    pseudonyms
  end

  def self.authenticate(credentials, account_ids, remote_ip = nil)
    pseudonyms = find_all_by_arbitrary_credentials(credentials, account_ids, remote_ip)
    return :too_many_attempts if pseudonyms == :too_many_attempts
    site_admin = pseudonyms.find { |p| p.account_id == Account.site_admin.id }
    # only log them in if these credentials match a single user OR if it matched site admin
    if pseudonyms.map(&:user).uniq.length == 1 || site_admin
      # prefer a pseudonym from Site Admin if possible, otherwise just choose one
      site_admin || pseudonyms.first
    end
  end

  def audit_login(remote_ip, valid_password)
    return :too_many_attempts unless Canvas::Security.allow_login_attempt?(self, remote_ip)

    if valid_password
      Canvas::Security.successful_login!(self, remote_ip)
    else
      Canvas::Security.failed_login!(self, remote_ip)
    end
    nil
  end

  def claim_cas_ticket(ticket)
    return unless Canvas.redis_enabled?

    redis_key = "cas_session:#{ticket}"
    ttl = 1.day

    # Refresh the keys ttl if it exists.
    unless Canvas.redis.expire(redis_key, ttl)
      # If it does not exist we need to create it.
      Canvas.redis.set(redis_key, global_id, ex: ttl, nx: true)
    end
  end

  def cas_ticket_expired?(ticket)
    return unless Canvas.redis_enabled?
    Canvas.redis.get("cas_session:#{ticket}") != global_id.to_s
  end

  def self.expire_cas_ticket(ticket)
    return unless Canvas.redis_enabled?
    redis_key = "cas_session:#{ticket}"

    if id = Canvas.redis.getset(redis_key, Pseudonym::CAS_TICKET_EXPIRED)
      Canvas.redis.expire(redis_key, 1.day)

      Pseudonym.where(id: id).exists? if id != Pseudonym::CAS_TICKET_EXPIRED
    end
  end
end
