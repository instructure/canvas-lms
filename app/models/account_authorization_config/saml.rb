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

class AccountAuthorizationConfig::SAML < AccountAuthorizationConfig::Delegated
  def self.sti_name
    'saml'.freeze
  end

  def self.enabled?
    @enabled
  end

  begin
    require 'onelogin/saml'
    @enabled = true
  rescue LoadError
    @enabled = false
  end

  def self.recognized_params
    [ :log_in_url, :log_out_url, :requested_authn_context,
      :certificate_fingerprint, :identifier_format,
      :login_attribute, :idp_entity_id, :parent_registration ].freeze
  end

  def self.deprecated_params
    [:change_password_url, :login_handle_name, :unknown_user_url].freeze
  end

  before_validation :set_saml_defaults
  validates_presence_of :entity_id

  def auth_provider_filter
    [nil, self]
  end

  def set_saml_defaults
    self.entity_id ||= saml_default_entity_id
    self.requested_authn_context = nil if self.requested_authn_context.blank?
  end

  def self.login_attributes
    {
        'NameID' => 'nameid',
        'eduPersonPrincipalName' => 'eduPersonPrincipalName',
        t(:saml_eppn_domain_stripped, "%{eppn} (domain stripped)", :eppn => "eduPersonPrincipalName") =>'eduPersonPrincipalName_stripped'
    }
  end

  def self.saml_default_entity_id_for_account(account)
    "http://#{HostUrl.context_host(account)}/saml2"
  end

  def saml_default_entity_id
    self.class.saml_default_entity_id_for_account(self.account)
  end

  def login_attribute
    return 'nameid' unless read_attribute(:login_attribute)
    super
  end

  def saml_settings(current_host=nil)
    return nil unless self.auth_type == 'saml'

    unless @saml_settings
      @saml_settings = self.class.saml_settings_for_account(self.account, current_host)

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
    settings.sp_slo_url = "#{HostUrl.protocol}://#{domains.first}/login/saml/logout"
    settings.assertion_consumer_service_url = domains.flat_map do |domain|
      [
        "#{HostUrl.protocol}://#{domain}/saml_consume",
        "#{HostUrl.protocol}://#{domain}/login/saml"
      ]
    end
    settings.tech_contact_name = app_config[:tech_contact_name] || 'Webmaster'
    settings.tech_contact_email = app_config[:tech_contact_email] || ''

    settings.issuer = account.authentication_providers.active.where(auth_type: 'saml').first.try(:entity_id)
    settings.issuer ||= saml_default_entity_id_for_account(account)

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
    Setting.get('aac_debug_expire_minutes', 30).to_i.minutes
  end

  def user_logout_redirect(controller, current_user)
    settings = saml_settings(controller.request.host_with_port)
    session = controller.session

    saml_request = Onelogin::Saml::LogoutRequest.generate(
      session[:name_qualifier],
      session[:name_id],
      session[:session_index],
      settings
    )

    if debugging? && debug_get(:logged_in_user_id) == current_user.id
      debug_set(:logout_request_id, saml_request.id)
      debug_set(:logout_to_idp_url, saml_request.forward_url)
      debug_set(:logout_to_idp_xml, saml_request.xml)
      debug_set(:debugging, t('debug.logout_redirect', "LogoutRequest sent to IdP"))
    end

    saml_request.forward_url
  end
end
