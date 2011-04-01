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

class Pseudonym < ActiveRecord::Base
  include Workflow

  attr_accessible :user, :account, :password, :password_confirmation, :path, :path_type, :password_auto_generated, :unique_id
  
  belongs_to :account
  belongs_to :user
  has_many :communication_channels, :order => 'position'
  belongs_to :communication_channel
  has_many :group_memberships
  has_many :groups, :through => :group_memberships
  validates_length_of :sis_update_data, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :unique_id, :maximum => maximum_string_length
  before_validation :validate_unique_id
  before_destroy :retire_channels
  
  before_save :set_password_changed
  before_validation :infer_defaults
  before_save :assert_communication_channel
  before_save :set_update_account_associations_if_account_changed
  after_save :update_passwords_on_related_pseudonyms
  after_save :update_account_associations_if_account_changed
  has_a_broadcast_policy
  
  attr_accessor :path, :path_type
  
  acts_as_authentic do |config|
    config.validates_format_of_login_field_options = {:with => /\A\w[\w\.\+\-_@ =]+\z/}
    config.login_field :unique_id
    config.validations_scope = :account_id
    config.perishable_token_valid_for = 30.minutes
    config.validates_length_of_password_field_options = { :minimum => 6, :if => :require_password? }
  end

  def require_password?
    # Change from auth_logic: don't require a password just because new_record?
    # is true. just check if the pw has changed or cryped_password_field is
    # blank.
    password_changed? || send(crypted_password_field).blank?
  end

  acts_as_list :scope => :user_id
  
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
  
  def set_update_account_associations_if_account_changed
    @should_update_user_account_associations = self.account_id_changed?
    true
  end
  
  def update_account_associations_if_account_changed
    update_user_account_associations if @should_update_user_account_associations
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
  
  def self.custom_find_by_unique_id(unique_id)
    if connection.adapter_name.downcase == 'mysql'
      find_by_unique_id(unique_id)
    else
      first(:conditions => ["LOWER(#{quoted_table_name}.unique_id) = ?", unique_id.mb_chars.downcase])
    end
  end
  
  def update_user_account_associations
    self.user.send_later_if_production(:update_account_associations) if self.user
  end
  
  def set_password_changed
    @password_changed = self.password && self.password_confirmation == self.password
  end
  
  def password=(new_pass)
    self.password_auto_generated = false
    super(new_pass)
  end
  
  def communication_channel
    self.user.communication_channels.find_by_path(self.unique_id)
  end
  
  def confirmation_code
    (self.communication_channel || self.user.communication_channel).confirmation_code
  end
  
  def infer_defaults
    self.account ||= Account.default
    if !crypted_password || crypted_password == ""
      self.generate_temporary_password
    end
  end
  
  def update_passwords_on_related_pseudonyms
    return if @dont_update_passwords_on_related_pseudonyms || !self.user || self.password_auto_generated
  end
  
  def login_assertions_for_user
    if !self.persistence_token || self.persistence_token == ''
      # Some pseudonyms can end up without a persistence token if they were created
      # using the SIS, for example.
      self.persistence_token = AutoHandle.generate('pseudo', 15)
      self.save
    end
    
    user = self.user
    user.workflow_state = 'registered' unless user.registered?
    
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
  
  def works_for_account?(account)
    return false unless account
    self.account_id == account.id || (!account.require_account_pseudonym? && self.account.password_authentication?)
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
        self.errors.add(:unique_id, "\"#{self.unique_id}\" is not a valid email address")
        return false
      end
    end
    true
  end

  def assert_user(params={}, &block)
    self.user ||= User.create!({:name => self.path}.merge(params), &block)
    self.save
    self.user
  end

  workflow do
    state :active 
    state :deleted
  end
  
  alias_method :destroy!, :destroy
  def destroy(even_if_managed_password=false)
    raise "Cannot delete system-generated pseudonyms" if !even_if_managed_password && self.managed_password?
    self.deleted_unique_id = self.unique_id unless self.deleted?
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    self.unique_id = self.unique_id.to_s + "--" + AutoHandle.generate
    self.save
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
  
  def account_name
    return "Instructure" if self.account == Account.default
    self.account.name rescue "Canvas"
  end
  
  def chat
    user.chat if user
  end
  
  def chat=(c)
    return false unless user
    self.user.chat=(c)
    user.save!
    user.chat
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
    !!(self.sis_source_id && self.account && !self.account.password_authentication?)
  end
  
  def valid_arbitrary_credentials?(plaintext_password)
    return false if self.deleted?
    require 'net/ldap'
    account = self.account || Account.default
    if account && account.ldap_authentication?
      res = nil
      res = valid_ldap_credentials?(plaintext_password)
      res ||= valid_password?(plaintext_password)
    else
      valid_password?(plaintext_password)
    end
  end
  
  def generate_temporary_password
    pw = AutoHandle.generate('tmp-pw', 15)
    self.password = pw
    self.password_confirmation = pw
    self.password_auto_generated = true
    pw
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
      CommunicationChannel.update_all({:user_id => user.id}, {:path => self.unique_id, :user_id => old_user_id})
      User.update_all({:updated_at => Time.now}, {:id => [old_user_id, user.id]})
    end
    if User.find(old_user_id).pseudonyms.empty? && migrate
      old_user.move_to_user(user)
    end
  end
  
  def valid_ssha?(plaintext_password)
    return false unless plaintext_password && self.sis_ssha
    decoded = Base64::decode64(self.sis_ssha.sub(/\A\{SSHA\}/, ""))
    digest = decoded[0,20]
    salt = decoded[20,8]
    digested_password = Digest::SHA1.digest(plaintext_password + salt)
    digest == digested_password
  end
  
  def ldap_bind_result(password_plaintext)
    ldap = self.account.account_authorization_config.ldap_connection
    filter = self.account.account_authorization_config.ldap_filter(self.unique_id)
    ldap.bind_as(:base => ldap.base, :filter => filter, :password => password_plaintext)
  end
  
  def ldap_channel_to_possibly_merge(password_plaintext)
    return nil unless managed_password?
    res = @ldap_result ||= (self.ldap_bind_result(password_plaintext)[0] rescue nil)
    if res && res[:mail] && res[:mail][0]
      email = res[:mail][0]
      @ldap_result = res
      ccs = CommunicationChannel.find_all_by_path_and_path_type(email, "email") rescue []
      if cc = ccs.detect{|cc| cc.active? && cc.user_id == self.user_id }
        # If it's already owned by this user, just run the cleanup
        # to get rid of any straggling duplicates
        cc.touch if ccs.length > 1
      elsif cc = ccs.detect{|cc| cc.active? }
        # If it belongs to someone else, we should remind them about
        # merging the paths
        return ccs.detect{|cc| cc.active? }
      elsif ccs.any?{|cc| cc.user.pre_registered? || cc.user.creation_pending? }
        # If any one of the users is not registered, merge those users in
        # and claim the channel, thus stealing it out from beneath
        # the others
        first_cc = nil
        ccs.select{|cc| cc.user.pre_registered? || cc.user.creation_pending? }.each do |cc|
          first_cc ||= cc
          cc.user.move_to_user(self.user)
        end
        first_cc.confirm
      else
        # Else should mean it only exists in a deleted or unclaimed state, 
        # which means we can just create it
        CommunicationChannel.create({
          :path => email,
          :path_type => "email",
          :user => self.user,
          :pseudonym => self
        }) { |cc| cc.workflow_state = 'active' }
      end
    end
    nil
  rescue => e
    ErrorLogging.log_error(:default, {
      :message => "LDAP email conflict",
      :user => self.unique_id,
      :object => self.inspect.to_s,
      :email => (res[:email] rescue ''),
      :error_type => (e.inspect rescue ''),
      :exception_message => (e.message rescue ''),
      :failure_status => (e.to_s rescue ''),
      :backtrace => (e.backtrace rescue '')
    })
    nil
  end

  attr_reader :ldap_result
  def valid_ldap_credentials?(password_plaintext)
    # try to authenticate against the LDAP server
    res = ldap_bind_result(password_plaintext)
    if !res
      ErrorLogging.log_error(:ldap, {
        :message => "LDAP authentication failure",
        :user => self.unique_id,
        :object => self.inspect.to_s,
        :unique_id => self.unique_id
      })
    else
      @ldap_result = res[0]
    end
    !!res
  rescue => e
    ErrorLogging.log_error(:ldap, {
      :message => "LDAP authentication error",
      :user => self.unique_id,
      :object => self.inspect.to_s,
      :error_type => (e.inspect rescue ''),
      :unique_id => self.unique_id,
      :exception_message => (e.message rescue ''),
      :failure_status => (e.to_s rescue ''),
      :backtrace => (e.backtrace rescue '')
    })
    nil
  end
  
  # To get the communication_channel for free, call this with :path => 'somepath@example.com' 
  def assert_communication_channel(merge=false)
    if self.path
      cc = CommunicationChannel.create(:user => self.user, :path => self.path, :path_type => self.path_type || 'email')
      self.communication_channel_id ||= cc.id
    end
  end
  
  named_scope :account_unique_ids, lambda{|account, *unique_ids|
    {:conditions => {:account_id => account.id, :unique_id => unique_ids}, :order => :unique_id}
  }
  named_scope :active, lambda{
    {:conditions => ['pseudonyms.workflow_state IS NULL OR pseudonyms.workflow_state != ?', 'deleted'] }
  }

  def self.serialization_excludes; [:crypted_password, :password_salt, :reset_password_token, :persistence_token, :single_access_token, :perishable_token, :sis_ssha]; end
end
