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

require 'onelogin/saml'

class AccountAuthorizationConfig < ActiveRecord::Base
  belongs_to :account

  attr_accessible :account, :auth_port, :auth_host, :auth_base, :auth_username,
                  :auth_password, :auth_password_salt, :auth_type, :auth_over_tls,
                  :log_in_url, :log_out_url, :identifier_format,
                  :certificate_fingerprint, :entity_id, :change_password_url,
                  :login_handle_name, :ldap_filter, :auth_filter

  before_validation :set_saml_entity_id, :if => Proc.new { |aac| aac.saml_authentication? }
  validates_presence_of :account_id
  validates_presence_of :entity_id, :if => Proc.new{|aac| aac.saml_authentication?}
  after_create :disable_open_registration_if_delegated

  def ldap_connection
    raise "Not an LDAP config" unless self.auth_type == 'ldap'
    require 'net/ldap'
    ldap = Net::LDAP.new(:encryption => (self.auth_over_tls ? :simple_tls : nil))
    ldap.host = self.auth_host
    ldap.port = self.auth_port
    ldap.base = self.auth_base
    ldap.auth self.auth_username, self.auth_decrypted_password
    ldap
  end
  
  def set_saml_entity_id
    self.entity_id ||= saml_default_entity_id
  end
  
  def sanitized_ldap_login(login)
    [ [ '\\', '\5c' ], [ '*', '\2a' ], [ '(', '\28' ], [ ')', '\29' ], [ "\00", '\00' ] ].each do |re|
      login.gsub!(re[0], re[1])
    end
    login
  end
  
  def ldap_filter(login = nil)
    filter = self.auth_filter
    filter.gsub!(/\{\{login\}\}/, sanitized_ldap_login(login)) if login
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

  def saml_settings(preferred_account_domain=nil)
    return nil unless self.auth_type == 'saml'

    unless @saml_settings
      @saml_settings = AccountAuthorizationConfig.saml_settings_for_account(self.account, preferred_account_domain)

      @saml_settings.idp_sso_target_url = self.log_in_url
      @saml_settings.idp_slo_target_url = self.log_out_url
      @saml_settings.idp_cert_fingerprint = self.certificate_fingerprint
      @saml_settings.name_identifier_format = self.identifier_format
    end
    
    @saml_settings
  end
  
  def self.saml_settings_for_account(account, preferred_account_domain=nil)
    app_config = Setting.from_config('saml') || {}
    domain = HostUrl.context_host(account, preferred_account_domain)
    
    settings = Onelogin::Saml::Settings.new
    if ENV['RAILS_ENV'] == 'development'
      # if you set the domain to go to your local box in /etc/hosts you can test saml
      settings.assertion_consumer_service_url = "http://#{domain}/saml_consume"
      settings.sp_slo_url = "http://#{domain}/saml_logout"
    else
      settings.assertion_consumer_service_url = "https://#{domain}/saml_consume"
      settings.sp_slo_url = "https://#{domain}/saml_logout"
    end
    settings.tech_contact_name = app_config[:tech_contact_name] || 'Webmaster'
    settings.tech_contact_email = app_config[:tech_contact_email] || ''
    
    if account.saml_authentication?
      settings.issuer = account.account_authorization_config.entity_id 
    else
      settings.issuer = saml_default_entity_id_for_account(account)
    end
    
    encryption = app_config[:encryption]
    if encryption.is_a?(Hash) && File.exists?(encryption[:xmlsec_binary])
      resolve_path = lambda { |path|
        if path.nil?
          nil
        elsif path[0, 1] == '/'
          path
        else
          File.join(Rails.root, 'config', path)
        end
      }

      private_key_path = resolve_path.call(encryption[:private_key])
      certificate_path = resolve_path.call(encryption[:certificate])

      if File.exists?(private_key_path) && File.exists?(certificate_path)
        settings.xmlsec1_path = encryption[:xmlsec_binary]
        settings.xmlsec_certificate = certificate_path
        settings.xmlsec_privatekey = private_key_path
      end
    end
    
    settings
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
    rescue Timeout::Error
      self.errors.add(
        :ldap_connection_test,
        t(:test_connection_timeout, "Timeout when connecting")
      )
    rescue
      self.errors.add(
        :ldap_connection_test,
        t(:test_connection_failed, "Failed to connect to host/port")
        )
    end
    false
  end

  def test_ldap_bind
    begin
      return self.ldap_connection.bind
    rescue
      self.errors.add(
        :ldap_bind_test,
        t(:test_bind_failed, "Failed to bind")
      )
      return false
    end
  end

  def test_ldap_search
    begin
      res = self.ldap_connection.search {|s| break s}
      return true if res
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
      @account.settings = { :open_registration => false }
      @account.save!
    end
  end
end
