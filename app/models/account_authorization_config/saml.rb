#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'saml2'

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
    [ :log_in_url,
      :log_out_url,
      :requested_authn_context,
      :certificate_fingerprint,
      :identifier_format,
      :login_attribute,
      :idp_entity_id,
      :parent_registration,
      :jit_provisioning,
      :metadata,
      :metadata_uri
    ].freeze
  end

  def self.deprecated_params
    [:change_password_url, :login_handle_name, :unknown_user_url].freeze
  end

  def self.recognized_federated_attributes
    # we allow any attribute
    nil
  end

  SENSITIVE_PARAMS = [:metadata].freeze

  before_validation :set_saml_defaults
  before_validation :download_metadata

  def auth_provider_filter
    [nil, self]
  end

  def entity_id
    self.class.saml_default_entity_id_for_account(self.account)
  end

  def set_saml_defaults
    self.requested_authn_context = nil if self.requested_authn_context.blank?
  end

  def download_metadata
    return unless metadata_uri.present?
    return unless metadata_uri_changed? || idp_entity_id_changed?
    # someone's trying to cheat; switch to our more efficient implementation
    self.metadata_uri = InCommon::URN if metadata_uri == InCommon.endpoint

    if metadata_uri == InCommon::URN
      unless idp_entity_id.present?
        errors.add(:idp_entity_id, :present)
        return
      end

      begin
        entity = InCommon.metadata[idp_entity_id]
        unless entity
          errors.add(:idp_entity_id, t("Entity %{entity_id} not found in InCommon Metadata", entity_id: idp_entity_id))
          return
        end
        populate_from_metadata(entity)
      rescue => e
        ::Canvas::Errors.capture_exception(:incommon, e)
        errors.add(:metadata_uri, e.message)
      end
      return
    end

    begin
      populate_from_metadata_url(metadata_uri)
    rescue => e
      ::Canvas::Errors.capture_exception(:saml_metadata_refresh, e)
      errors.add(:metadata_uri, e.message)
    end
  end

  def self.login_attributes
    {
        'NameID' => 'nameid',
        'eduPersonPrincipalName' => 'eduPersonPrincipalName',
        t(:saml_eppn_domain_stripped, "%{eppn} (domain stripped)", :eppn => "eduPersonPrincipalName") =>'eduPersonPrincipalName_stripped'
    }
  end

  def self.saml_default_entity_id_for_account(account)
    if !account.settings[:saml_entity_id]
      account.settings[:saml_entity_id] = "http://#{HostUrl.context_host(account)}/saml2"
      account.save!
    end
    account.settings[:saml_entity_id]
  end

  def login_attribute
    return 'nameid' unless read_attribute(:login_attribute)
    super
  end

  def populate_from_metadata(entity)
    idps = entity.identity_providers
    raise "Must provide exactly one IDPSSODescriptor; found #{idps.length}" unless idps.length == 1
    idp = idps.first
    self.idp_entity_id = entity.entity_id
    self.log_in_url = idp.single_sign_on_services.find { |ep| ep.binding == SAML2::Endpoint::Bindings::HTTP_REDIRECT }.try(:location)
    self.log_out_url = idp.single_logout_services.find { |ep| ep.binding == SAML2::Endpoint::Bindings::HTTP_REDIRECT }.try(:location)
    self.certificate_fingerprint = (idp.signing_keys.first || idp.keys.first).try(:fingerprint)
    self.identifier_format = (idp.name_id_formats & Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS).first
  end

  def populate_from_metadata_xml(xml)
    entity = SAML2::Entity.parse(xml)
    raise "Invalid schema" unless entity.valid_schema?
    if entity.is_a?(SAML2::Entity::Group) && idp_entity_id.present?
      entity = entity.find { |e| e.entity_id == idp_entity_id }
    end
    raise "Must be a single Entity" unless entity.is_a?(SAML2::Entity)
    populate_from_metadata(entity)
  end
  alias_method :metadata=, :populate_from_metadata_xml

  def populate_from_metadata_url(url)
    ::Canvas.timeout_protection("saml_metadata_fetch") do
      CanvasHttp.get(url) do |response|
        # raise error unless it's a 2xx
        response.value
        populate_from_metadata_xml(response.body)
      end
    end
  end

  def saml_settings(current_host=nil)
    return nil unless self.auth_type == 'saml'

    unless @saml_settings
      @saml_settings = self.class.onelogin_saml_settings_for_account(self.account, current_host)

      @saml_settings.idp_sso_target_url = self.log_in_url
      @saml_settings.idp_slo_target_url = self.log_out_url
      @saml_settings.idp_cert_fingerprint = (certificate_fingerprint || '').split.presence
      @saml_settings.name_identifier_format = self.identifier_format
      @saml_settings.requested_authn_context = self.requested_authn_context
      @saml_settings.logger = logger
    end

    @saml_settings
  end

  # construct a metadata doc to represent the IdP
  # TODO: eventually store the actual metadata we got from the IdP
  def idp_metadata
    @idp_metadata ||= begin
       entity = SAML2::Entity.new
       entity.entity_id = idp_entity_id

       idp = SAML2::IdentityProvider.new
       if log_out_url.present?
         idp.single_logout_services << SAML2::Endpoint.new(log_out_url,
                                                           SAML2::Endpoint::Bindings::HTTP_REDIRECT)
       end
       entity.roles << idp
       entity
    end
  end

  def self.sp_metadata(entity_id, hosts)
    app_config = ConfigFile.load('saml') || {}

    entity = SAML2::Entity.new
    entity.entity_id = entity_id

    contact = SAML2::Contact.new(SAML2::Contact::Type::TECHNICAL)
    contact.surname = app_config[:tech_contact_name] || 'Webmaster'
    contact.email_addresses = Array.wrap(app_config[:tech_contact_email])
    entity.contacts << contact

    sp = SAML2::ServiceProvider.new
    sp.single_logout_services << SAML2::Endpoint.new("#{HostUrl.protocol}://#{hosts.first}/login/saml/logout",
                                                     SAML2::Endpoint::Bindings::HTTP_REDIRECT)

    hosts.each_with_index do |host, i|
      sp.assertion_consumer_services << SAML2::Endpoint::Indexed.new("#{HostUrl.protocol}://#{host}/login/saml",
                          i,
                          i == 0)
    end

    encryption = app_config[:encryption]

    if encryption.is_a?(Hash) &&
      (cert_path = resolve_saml_key_path(encryption[:certificate]))

      cert = File.read(cert_path)
      sp.keys << SAML2::Key.new(cert, SAML2::Key::Type::ENCRYPTION, [SAML2::Key::EncryptionMethod.new])
      sp.keys << SAML2::Key.new(cert, SAML2::Key::Type::SIGNING)
    end

    entity.roles << sp
    entity
  end

  def self.sp_metadata_for_account(account, current_host = nil)
    sp_metadata(saml_default_entity_id_for_account(account),HostUrl.context_hosts(account, current_host))
  end

  def self.config
    ConfigFile.load('saml') || {}
  end

  def self.private_keys
    return [] unless (encryption = config[:encryption])
    ([encryption[:private_key]] + Array(encryption[:additional_private_keys])).map do |key|
      path = resolve_saml_key_path(key)
      next unless path
      [path, File.read(path)]
    end.compact.to_h
  end

  def self.onelogin_saml_settings_for_account(account, current_host=nil)
    app_config = ConfigFile.load('saml') || {}
    domains = HostUrl.context_hosts(account, current_host)

    settings = Onelogin::Saml::Settings.new
    settings.sp_slo_url = "#{HostUrl.protocol}://#{domains.first}/login/saml/logout"
    settings.assertion_consumer_service_url = domains.flat_map do |domain|
      [
        "#{HostUrl.protocol}://#{domain}/login/saml"
      ]
    end
    settings.tech_contact_name = app_config[:tech_contact_name] || 'Webmaster'
    settings.tech_contact_email = app_config[:tech_contact_email] || ''

    settings.issuer = saml_default_entity_id_for_account(account)

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
    session = controller.session

    logout_request = SAML2::LogoutRequest.initiate(idp_metadata.identity_providers.first,
      SAML2::NameID.new(entity_id),
      SAML2::NameID.new(session[:name_id],
                        session[:name_identifier_format],
                        name_qualifier: session[:name_qualifier],
                        sp_name_qualifier: session[:sp_name_qualifier]),
      session[:session_index]
    )

    # sign the response
    private_key_data = AccountAuthorizationConfig::SAML.private_keys.first&.last
    private_key = OpenSSL::PKey::RSA.new(private_key_data) if private_key_data
    result = SAML2::Bindings::HTTPRedirect.encode(logout_request, private_key: private_key)

    if debugging? && debug_get(:logged_in_user_id) == current_user.id
      debug_set(:logout_request_id, logout_request.id)
      debug_set(:logout_to_idp_url, result)
      debug_set(:logout_to_idp_xml, logout_request.to_s)
      debug_set(:debugging, t('debug.logout_redirect', "LogoutRequest sent to IdP"))
    end

    result
  end
end
