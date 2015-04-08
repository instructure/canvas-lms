#
# Copyright (C) 2013 Instructure, Inc.
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

require 'net-ldap'
require 'net_ldap_extensions'

class AccountAuthorizationConfig < ActiveRecord::Base
  cattr_accessor :saml_enabled
  begin
    require 'onelogin/saml'
    self.saml_enabled = true
  rescue LoadError
    self.saml_enabled = false
  end

  belongs_to :account
  acts_as_list :scope => :account

  attr_accessible :account, :auth_port, :auth_host, :auth_base, :auth_username,
    :auth_password, :auth_password_salt, :auth_type, :auth_over_tls,
    :log_in_url, :log_out_url, :identifier_format,
    :certificate_fingerprint, :entity_id, :change_password_url,
    :login_handle_name, :ldap_filter, :auth_filter, :requested_authn_context,
    :login_attribute, :idp_entity_id, :unknown_user_url

  before_validation :set_saml_defaults, :if => Proc.new { |aac| aac.saml_authentication? }

  VALID_AUTH_TYPES = %w[cas ldap saml]
  validates_inclusion_of :auth_type, in: VALID_AUTH_TYPES, message: "invalid auth_type, must be one of #{VALID_AUTH_TYPES.join(',')}"
  validates_presence_of :account_id
  validates_presence_of :entity_id, :if => Proc.new{|aac| aac.saml_authentication?}
  validate :validate_multiple_auth_configs

  after_create :disable_open_registration_if_delegated
  after_destroy :enable_canvas_authentication
  # if the config changes, clear out last_timeout_failure so another attempt can be made immediately
  before_save :clear_last_timeout_failure

  def self.recognized_params(auth_type)
    case auth_type
    when 'cas'
      [ :auth_type, :auth_base, :log_in_url, :login_handle_name, :unknown_user_url ]
    when 'ldap'
      [ :auth_type, :auth_host, :auth_port, :auth_over_tls, :auth_base,
        :auth_filter, :auth_username, :auth_password, :change_password_url,
        :identifier_format, :login_handle_name, :position ]
    when 'saml'
      [ :auth_type, :log_in_url, :log_out_url, :change_password_url, :requested_authn_context,
        :certificate_fingerprint, :identifier_format, :login_handle_name,
        :login_attribute, :idp_entity_id, :position, :unknown_user_url ]
    else
      []
    end
  end

  def self.auth_over_tls_setting(value)
    case value
    when nil, '', false, 'false', 'f', 0, '0'
      nil
    when true, 'true', 't', 1, '1', 'simple_tls', :simple_tls
      'simple_tls'
    when 'start_tls', :start_tls
      'start_tls'
    else
      raise ArgumentError("invalid auth_over_tls setting: #{value}")
    end
  end

  def auth_over_tls
    self.class.auth_over_tls_setting(read_attribute(:auth_over_tls))
  end

  def ldap_connection
    raise "Not an LDAP config" unless self.auth_type == 'ldap'
    require 'net/ldap'
    ldap = Net::LDAP.new(:encryption => self.auth_over_tls.try(:to_sym))
    ldap.host = self.auth_host
    ldap.port = self.auth_port
    ldap.base = self.auth_base
    ldap.auth self.auth_username, self.auth_decrypted_password
    ldap
  end

  def set_saml_defaults
    self.entity_id ||= saml_default_entity_id
    self.requested_authn_context = nil if self.requested_authn_context.blank?
  end

  def self.saml_login_attributes
    {
      'NameID' => 'nameid',
      'eduPersonPrincipalName' => 'eduPersonPrincipalName',
      t(:saml_eppn_domain_stripped, "%{eppn} (domain stripped)", :eppn => "eduPersonPrincipalName") =>'eduPersonPrincipalName_stripped'
    }
  end

  def sanitized_ldap_login(login)
    [ [ '\\', '\5c' ], [ '*', '\2a' ], [ '(', '\28' ], [ ')', '\29' ], [ "\00", '\00' ] ].each do |re|
      login.gsub!(re[0], re[1])
    end
    login
  end

  def ldap_filter(login = nil)
    filter = self.auth_filter
    filter = filter.gsub(/\{\{login\}\}/, sanitized_ldap_login(login)) if login
    filter
  end

  def change_password_url
    read_attribute(:change_password_url).blank? ? nil : read_attribute(:change_password_url)
  end

  def ldap_filter=(new_filter)
    self.auth_filter = new_filter
  end

  def ldap_ip
    begin
      return Socket::getaddrinfo(self.auth_host, 'http', nil, Socket::SOCK_STREAM)[0][3]
    rescue SocketError
      return nil
    end
  end

  def auth_password=(password)
    return if password.nil? or password == ''
    self.auth_crypted_password, self.auth_password_salt = Canvas::Security.encrypt_password(password, 'instructure_auth')
  end

  def auth_decrypted_password
    return nil unless self.auth_password_salt && self.auth_crypted_password
    Canvas::Security.decrypt_password(self.auth_crypted_password, self.auth_password_salt, 'instructure_auth')
  end

  def self.saml_default_entity_id_for_account(account)
    "http://#{HostUrl.context_host(account)}/saml2"
  end

  def saml_default_entity_id
    AccountAuthorizationConfig.saml_default_entity_id_for_account(self.account)
  end

  def login_attribute
    return 'nameid' unless read_attribute(:login_attribute)
    super
  end

  def saml_settings(current_host=nil)
    return nil unless self.auth_type == 'saml'

    unless @saml_settings
      @saml_settings = AccountAuthorizationConfig.saml_settings_for_account(self.account, current_host)

      @saml_settings.idp_sso_target_url = self.log_in_url
      @saml_settings.idp_slo_target_url = self.log_out_url
      @saml_settings.idp_cert_fingerprint = self.certificate_fingerprint
      @saml_settings.name_identifier_format = self.identifier_format
      @saml_settings.requested_authn_context = self.requested_authn_context
      @saml_settings.logger = logger
    end

    @saml_settings
  end

  def self.saml_settings_for_account(account, current_host=nil)
    app_config = ConfigFile.load('saml') || {}
    domains = HostUrl.context_hosts(account, current_host)

    settings = Onelogin::Saml::Settings.new
    settings.sp_slo_url = "#{HostUrl.protocol}://#{domains.first}/saml_logout"
    settings.assertion_consumer_service_url = domains.map { |domain| "#{HostUrl.protocol}://#{domain}/saml_consume" }
    settings.tech_contact_name = app_config[:tech_contact_name] || 'Webmaster'
    settings.tech_contact_email = app_config[:tech_contact_email] || ''

    if account.saml_authentication?
      settings.issuer = account.account_authorization_config.entity_id
    else
      settings.issuer = saml_default_entity_id_for_account(account)
    end

    encryption = app_config[:encryption]
    if encryption.is_a?(Hash)
      settings.xmlsec_certificate = resolve_saml_key_path(encryption[:certificate])
      settings.xmlsec_privatekey = resolve_saml_key_path(encryption[:private_key])

      settings.xmlsec_additional_privatekeys = Array(encryption[:additional_private_keys]).map { |apk| resolve_saml_key_path(apk) }.compact
    end

    settings
  end

  def self.resolve_saml_key_path(path)
    return nil unless path

    path = Pathname(path)

    if path.relative?
      path = Rails.root.join 'config', path
    end

    path.exist? ? path.to_s : nil
  end

  def email_identifier?
    if self.saml_authentication?
      return self.identifier_format == Onelogin::Saml::NameIdentifiers::EMAIL
    end

    false
  end

  def password_authentication?
    !['cas', 'ldap', 'saml'].member?(self.auth_type)
  end

  def delegated_authentication?
    ['cas', 'saml'].member?(self.auth_type)
  end

  def cas_authentication?
    self.auth_type == 'cas'
  end

  def ldap_authentication?
    self.auth_type == 'ldap'
  end

  def saml_authentication?
    self.auth_type == 'saml'
  end

  def self.default_login_handle_name
    t(:default_login_handle_name, "Email")
  end

  def self.default_delegated_login_handle_name
    t(:default_delegated_login_handle_name, "Login")
  end

  def self.serialization_excludes; [:auth_crypted_password, :auth_password_salt]; end

  def test_ldap_connection
    begin
      timeout(5) do
        TCPSocket.open(self.auth_host, self.auth_port)
      end
      return true
    rescue SocketError
      self.errors.add(:ldap_connection_test, t(:test_host_unknown, "Unknown host: %{host}", :host => self.auth_host))
    rescue Timeout::Error
      self.errors.add(:ldap_connection_test, t(:test_connection_timeout, "Timeout when connecting"))
    rescue => e
      self.errors.add(:ldap_connection_test, e.message)
    end
    false
  end

  def test_ldap_bind
    begin
      conn = self.ldap_connection
      unless res = conn.bind
        error = conn.get_operation_result
        self.errors.add(:ldap_bind_test, "Error #{error.code}: #{error.message}")
      end
      return res
    rescue => e
      self.errors.add(:ldap_bind_test, t(:test_bind_failed, "Failed to bind with the following error: %{error}", :error => e.message))
      return false
    end
  end

  def test_ldap_search
    begin
      conn = self.ldap_connection
      filter = self.ldap_filter("canvas_ldap_test_user")
      Net::LDAP::Filter.construct(filter)
      unless res = conn.search {|s| break s}
        error = conn.get_operation_result
        self.errors.add(:ldap_search_test, "Error #{error.code}: #{error.message}")
      end
      return res.present?
    rescue
      self.errors.add(
        :ldap_search_test,
        t(:test_search_failed, "Search failed with the following error: %{error}", :error => $!)
      )
      return false
    end
  end

  def test_ldap_login(username, password)
    ldap = self.ldap_connection
    filter = self.ldap_filter(username)
    begin
      res = ldap.bind_as(:base => ldap.base, :filter => filter, :password => password)
      return true if res
      self.errors.add(
        :ldap_login_test,
        t(:test_login_auth_failed, "Authentication failed")
      )
    rescue Net::LDAP::LdapError
      self.errors.add(
        :ldap_login_test,
        t(:test_login_auth_exception, "Exception on login: %{error}", :error => $!)
      )
    end
    false
  end

  def disable_open_registration_if_delegated
    if self.delegated_authentication? && self.account.open_registration?
      self.account.settings = { :open_registration => false, :self_registration => false }
      self.account.save!
    end
  end

  def enable_canvas_authentication
    if self.account.settings[:canvas_authentication] == false
      self.account.settings[:canvas_authentication] = true
      self.account.save!
    end
  end

  def debugging?
    !!Rails.cache.fetch(debug_key(:debugging))
  end

  def debugging_keys
    [:debugging, :request_id, :to_idp_url, :to_idp_xml, :idp_response_encoded,
     :idp_in_response_to, :fingerprint_from_idp, :idp_response_xml_encrypted,
     :idp_response_xml_decrypted, :idp_login_destination, :is_valid_login_response,
     :login_response_validation_error, :login_to_canvas_success, :canvas_login_fail_message,
     :logged_in_user_id, :logout_request_id, :logout_to_idp_url, :logout_to_idp_xml,
     :idp_logout_response_encoded, :idp_logout_in_response_to,
     :idp_logout_response_xml_encrypted, :idp_logout_destination]
  end

  def finish_debugging
    debugging_keys.each { |key| Rails.cache.delete(debug_key(key)) }
  end

  def start_debugging
    finish_debugging # clear old data
    debug_set(:debugging, t('debug.wait_for_login', "Waiting for attempted login"))
  end

  def debug_get(key)
    Rails.cache.fetch(debug_key(key))
  end

  def debug_set(key, value)
    Rails.cache.write(debug_key(key), value, :expires_in => debug_expire)
  end

  def debug_key(key)
    ['aac_debugging', self.id, key.to_s].cache_key
  end

  def debug_expire
    Setting.get('aac_debug_expire_minutes', 30).minutes
  end

  def self.ldap_failure_wait_time
    Setting.get('ldap_failure_wait_time', 1.minute.to_s).to_i
  end

  def ldap_bind_result(unique_id, password_plaintext)
    return nil if password_plaintext.blank?

    default_timeout = Setting.get('ldap_timelimit', 5.seconds.to_s).to_f

    Canvas.timeout_protection("ldap:#{self.global_id}",
                              raise_on_timeout: true,
                              fallback_timeout_length: default_timeout) do
                                ldap = self.ldap_connection
                                filter = self.ldap_filter(unique_id)
                                ldap.bind_as(:base => ldap.base, :filter => filter, :password => password_plaintext)
                              end
  rescue => e
    ErrorReport.log_exception(:ldap, e, :account => self.account)
    if e.is_a?(Timeout::Error)
      self.update_attribute(:last_timeout_failure, Time.now)
    end
    return nil
  end

  def clear_last_timeout_failure
    unless self.last_timeout_failure_changed?
      self.last_timeout_failure = nil
    end
  end

  def validate_multiple_auth_configs
    return true unless account
    other_configs = account.account_authorization_configs - [self]
    if other_configs.any? { |other| other.auth_type != self.auth_type }
      errors.add(:auth_type, :mixing_authentication_types)
    elsif !other_configs.empty? && self.cas_authentication?
      errors.add(:auth_type, :multiple_cas_configs)
    end
  end
end
