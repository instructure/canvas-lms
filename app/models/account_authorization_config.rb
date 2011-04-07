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

  attr_accessible :account, :auth_port, :auth_host, :auth_base, :auth_username, :auth_password, :auth_password_salt, :auth_type, :auth_over_tls, :log_in_url, :log_out_url, :identifier_format, :certificate_fingerprint, :entity_id, :change_password_url, :login_handle_name, :ldap_filter, :auth_filter

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
  
  def ldap_filter=(new_filter)
    self.auth_filter = new_filter
  end
  
  def auth_password=(password)
    return if password.nil? or password == ''
    self.auth_crypted_password, self.auth_password_salt = Canvas::Security.encrypt_password(password, 'instructure_auth')
  end
  
  def auth_decrypted_password
    return nil unless self.auth_password_salt && self.auth_crypted_password
    Canvas::Security.decrypt_password(self.auth_crypted_password, self.auth_password_salt, 'instructure_auth')
  end

  def saml_settings
    return nil unless self.auth_type == 'saml'
    app_config = Setting.from_config('saml')
    raise "This Canvas instance isn't configured for SAML" unless app_config

    unless @saml_settings
      domain = HostUrl.context_host(self.account)
      @saml_settings = Onelogin::Saml::Settings.new

      @saml_settings.issuer = self.entity_id || app_config[:entity_id]
      @saml_settings.idp_sso_target_url = self.log_in_url
      @saml_settings.idp_slo_target_url = self.log_out_url
      @saml_settings.idp_cert_fingerprint = self.certificate_fingerprint
      @saml_settings.name_identifier_format = self.identifier_format
      if ENV['RAILS_ENV'] == 'development'
        # if you set the domain to go to your local box in /etc/hosts you can test saml
        @saml_settings.assertion_consumer_service_url = "http://#{domain}:3000/saml_consume"
        @saml_settings.sp_slo_url = "http://#{domain}:3000/saml_logout"
      else
        @saml_settings.assertion_consumer_service_url = "https://#{domain}/saml_consume"
        @saml_settings.sp_slo_url = "https://#{domain}/saml_logout"
      end
      @saml_settings.tech_contact_name = app_config[:tech_contact_name] || 'Webmaster'
      @saml_settings.tech_contact_email = app_config[:tech_contact_email]
    end
    
    @saml_settings
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
    "Email"
  end
  
  def self.serialization_excludes; [:auth_crypted_password, :auth_password_salt]; end
end
