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

class AuthenticationProvider::SAML < AuthenticationProvider::Delegated
  def self.sti_name
    'saml'.freeze
  end

  def self.enabled?(_account = nil)
    @enabled
  end

  begin
    require 'onelogin/saml'
    @enabled = true
  rescue LoadError
    @enabled = false
  end

  def self.recognized_params
    [
      :log_in_url,
      :log_out_url,
      :requested_authn_context,
      :certificate_fingerprint,
      :identifier_format,
      :login_attribute,
      :idp_entity_id,
      :parent_registration,
      :jit_provisioning,
      :metadata,
      :metadata_uri,
      :sig_alg,
      :strip_domain_from_login_attribute
    ].freeze
  end

  def self.deprecated_params
    [:change_password_url, :login_handle_name, :unknown_user_url].freeze
  end

  def self.recognized_federated_attributes
    # we allow any attribute
    nil
  end

  def self.supports_debugging?
    true
  end

  def self.debugging_sections
    [nil,
     -> { t("AuthnRequest sent to IdP") },
     -> { t("AuthnResponse from IdP") },
     -> { t("LogoutRequest sent to IdP") },
     -> { t("LogoutResponse from IdP") },
    ]
  end

  def self.debugging_keys
    [{
      debugging: -> { t("Testing state") },
     }, {
      request_id: -> { t("Request ID") },
      to_idp_url: -> { t("LoginRequest encoded URL") },
      to_idp_xml: -> { t("LoginRequest XML sent to IdP") },
     }, {
      idp_in_response_to: -> { t("IdP InResponseTo") },
      idp_login_destination: -> { t("IdP LoginResponse destination") },
      fingerprint_from_idp: -> { t("IdP certificate fingerprint") },
      is_valid_login_response: -> { t("Canvas thinks response is valid") },
      login_response_validation_error: -> { t("Validation Error") },
      login_to_canvas_success: -> { t("User succesfully logged into Canvas") },
      canvas_login_fail_message: -> { t("Canvas Login failure message") },
      logged_in_user_id: -> { t("Logged in user id") },
      idp_response_encoded: -> { t("IdP LoginResponse encoded") },
      idp_response_xml_encrypted: -> { t("IdP LoginResponse encrypted") },
      idp_response_xml_decrypted: -> { t("IdP LoginResponse Decrypted") },
     }, {
      logout_request_id: -> { t("Logout request id") },
      logout_to_idp_url: -> { t("LogoutRequest encoded URL") },
      logout_to_idp_xml: -> { t("LogoutRequest XML sent to IdP") },
     }, {
      idp_logout_in_response_to: -> { t("IdP Logout InResponseTo") },
      idp_logout_destination: -> { t("IdP LogoutResponse Destination") },
      idp_logout_response_encoded: -> { t("IdP LogoutResponse encoded") },
      idp_logout_response_xml_encrypted: -> { t("IdP LogoutResponse XML") },
     }]
  end

  SENSITIVE_PARAMS = [:metadata].freeze

  before_validation :set_saml_defaults
  before_validation :download_metadata
  after_initialize do |ap|
    # default to the most secure signature we support, but only for new objects
    ap.sig_alg ||= 'RSA-SHA256' if ap.new_record?
  end

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
    return if metadata_uri.blank?
    return unless metadata_uri_changed? || idp_entity_id_changed?

    Federation.descendants.each do |federation|
      # someone's trying to cheat; switch to our more efficient implementation
      self.metadata_uri = federation::URN if metadata_uri == federation.endpoint

      next unless metadata_uri == federation::URN

      if idp_entity_id.blank?
        errors.add(:idp_entity_id, :present)
        return
      end

      begin
        entity = federation.metadata[idp_entity_id]
        unless entity
          errors.add(:idp_entity_id, t("Entity %{entity_id} not found in %{federation_name} Metadata",
                                       entity_id: idp_entity_id, federation_name: federation.class_name))
          return
        end
        populate_from_metadata(entity)
      rescue => e
        ::Canvas::Errors.capture_exception(:saml_federation, e)
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
        'NameID' => 'NameID',
        'eduPersonPrincipalName' => 'eduPersonPrincipalName',
    }
  end

  def self.saml_default_entity_id_for_account(account)
    unless account.settings[:saml_entity_id]
      account.settings[:saml_entity_id] = "http://#{HostUrl.context_host(account)}/saml2"
      account.save!
    end
    account.settings[:saml_entity_id]
  end

  def login_attribute
    return 'NameID' unless read_attribute(:login_attribute)
    result = super
    # backcompat
    return 'NameID' if result == 'nameid'
    return 'eduPersonPrincipalName' if result == 'eduPersonPrincipalName_stripped'
    result
  end

  def strip_domain_from_login_attribute?
    # backcompat
    return true if read_attribute(:login_attribute) == 'eduPersonPrincipalName_stripped'
    !!settings['strip_domain_from_login_attribute']
  end
  alias strip_domain_from_login_attribute strip_domain_from_login_attribute?

  def strip_domain_from_login_attribute=(value)
    settings['strip_domain_from_login_attribute'] = ::Canvas::Plugin.value_to_boolean(value)
  end

  def signing_certificates
    settings['signing_certificates'] ||= []
  end

  def sig_alg
    settings['sig_alg'].presence
  end

  def sig_alg=(value)
    value = value.presence
    value = SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA1 if value&.downcase == 'rsa-sha1'
    value = SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA256 if value&.downcase == 'rsa-sha256'
    # support using 'false' to disable
    value = nil if ::Canvas::Plugin.value_to_boolean(value, ignore_unrecognized: true) == false

    unless [nil,
            SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA1,
            SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA256].include?(value)
      errors.add("Unsupported signing algorithm #{value}")
      return
    end
    settings['sig_alg'] = value
  end

  def populate_from_metadata(entity)
    idps = entity.identity_providers
    raise "Must provide exactly one IDPSSODescriptor; found #{idps.length}" unless idps.length == 1
    idp = idps.first
    self.idp_entity_id = entity.entity_id
    self.log_in_url = idp.single_sign_on_services.find { |ep| ep.binding == SAML2::Bindings::HTTPRedirect::URN }.try(:location)
    self.log_out_url = idp.single_logout_services.find { |ep| ep.binding == SAML2::Bindings::HTTPRedirect::URN }.try(:location)
    self.certificate_fingerprint = idp.signing_keys.map(&:fingerprint).join(' ').presence || idp.keys.first&.fingerprint
    self.identifier_format = (idp.name_id_formats & Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS).first
    self.settings[:signing_certificates] = idp.signing_keys.map(&:x509)
    case idp.want_authn_requests_signed?
    when true
      # use ||= to not overwrite a specific algorithm that has otherwise been
      # chosen
      self.sig_alg ||= 'RSA-SHA1'
    when false
      self.sig_alg = nil
      # else nil
      # don't change the user settings
    end
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
  alias metadata= populate_from_metadata_xml

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
       idp.single_sign_on_services << SAML2::Endpoint.new(log_in_url,
                                                          SAML2::Bindings::HTTPRedirect::URN)
       if log_out_url.present?
         idp.single_logout_services << SAML2::Endpoint.new(log_out_url,
                                                           SAML2::Bindings::HTTPRedirect::URN)
       end
       idp.fingerprints = (certificate_fingerprint || '').split.presence
       entity.roles << idp
       entity
    end
  end

  def self.sp_metadata(entity_id, hosts)
    app_config = config

    entity = SAML2::Entity.new
    entity.entity_id = entity_id

    contact = SAML2::Contact.new(SAML2::Contact::Type::TECHNICAL)
    contact.surname = app_config[:tech_contact_name] || 'Webmaster'
    contact.email_addresses = Array.wrap(app_config[:tech_contact_email])
    entity.contacts << contact

    sp = SAML2::ServiceProvider.new
    sp.single_logout_services << SAML2::Endpoint.new("#{HostUrl.protocol}://#{hosts.first}/login/saml/logout",
                                                     SAML2::Bindings::HTTPRedirect::URN)

    hosts.each_with_index do |host, i|
      sp.assertion_consumer_services << SAML2::Endpoint::Indexed.new("#{HostUrl.protocol}://#{host}/login/saml",
                          i,
                          i == 0)
    end

    encryption = app_config[:encryption]

    if encryption.is_a?(Hash)
      Array.wrap(encryption[:certificate]).each do |path|
        cert_path = resolve_saml_key_path(path)
        next unless cert_path

        cert = File.read(cert_path)
        sp.keys << SAML2::Key.new(cert, SAML2::Key::Type::ENCRYPTION, [SAML2::Key::EncryptionMethod.new])
        sp.keys << SAML2::Key.new(cert, SAML2::Key::Type::SIGNING)
      end
    end
    sp.private_keys = private_keys.values.map { |key| OpenSSL::PKey::RSA.new(key) }

    entity.roles << sp
    entity
  end

  def generate_authn_request_redirect(host: nil,
                                      parent_registration: false,
                                      relay_state: nil)
    sp_metadata = self.class.sp_metadata_for_account(account, host).service_providers.first
    authn_request = SAML2::AuthnRequest.initiate(SAML2::NameID.new(entity_id),
                                                 idp_metadata.identity_providers.first,
                                                 service_provider: sp_metadata)
    authn_request.name_id_policy.format = identifier_format if identifier_format.present?
    if requested_authn_context.present?
      authn_request.requested_authn_context = SAML2::RequestedAuthnContext.new
      authn_request.requested_authn_context.class_ref = requested_authn_context
      authn_request.requested_authn_context.comparison = :exact
    end
    authn_request.force_authn = true if parent_registration
    private_key = self.class.private_key
    private_key = nil if sig_alg.nil?
    forward_url = SAML2::Bindings::HTTPRedirect.encode(authn_request,
                                                       private_key: private_key,
                                                       sig_alg: sig_alg,
                                                       relay_state: relay_state)

    if debugging? && debug_set(:request_id, authn_request.id, overwrite: false)
      debug_set(:to_idp_url, forward_url)
      debug_set(:to_idp_xml, authn_request.to_s)
      debug_set(:debugging, "Forwarding user to IdP for authentication")
    end

    forward_url
  end

  def self.sp_metadata_for_account(account, current_host = nil)
    entity = sp_metadata(saml_default_entity_id_for_account(account),HostUrl.context_hosts(account, current_host))
    prior_configs = Set.new
    account.authentication_providers.active.where(auth_type: 'saml').each do |ap|
      federated_attributes = ap.federated_attributes
      next if federated_attributes.empty?
      next if prior_configs.include?(federated_attributes)
      prior_configs << federated_attributes

      acs = SAML2::AttributeConsumingService.new(en: 'Canvas')
      acs.index = ap.id
      federated_attributes.each do |(_canvas_attribute_name, provider_attribute_config)|
        acs.requested_attributes << SAML2::RequestedAttribute.create(provider_attribute_config['attribute'])
      end
      entity.roles.last.attribute_consuming_services << acs
    end
    entity
  end

  def sp_metadata(current_host = nil)
    self.class.sp_metadata_for_account(account, current_host)
  end

  def self.config
    ConfigFile.load('saml') || {}
  end

  def self.private_key
    unless instance_variable_defined?(:@key)
      private_key_data = private_keys.first&.last
      @key = OpenSSL::PKey::RSA.new(private_key_data) if private_key_data
    end
    @key
  end

  def self.private_keys
    return {} unless (encryption = config[:encryption])
    ([encryption[:private_key]] + Array(encryption[:additional_private_keys])).map do |key|
      path = resolve_saml_key_path(key)
      next unless path
      [path, File.read(path)]
    end.compact.to_h
  end

  ::Canvas::Reloader.on_reload do
    remove_instance_variable(:@key) if instance_variable_defined?(:@key)
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
      settings.xmlsec_certificate = resolve_saml_key_path(Array.wrap(encryption[:certificate]).first)
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

  def user_logout_redirect(controller, current_user)
    session = controller.session

    idp = idp_metadata.identity_providers.first
    return super if idp.single_logout_services.empty?

    logout_request = SAML2::LogoutRequest.initiate(idp,
      SAML2::NameID.new(entity_id),
      SAML2::NameID.new(session[:name_id],
                        session[:name_identifier_format],
                        name_qualifier: session[:name_qualifier],
                        sp_name_qualifier: session[:sp_name_qualifier]),
      session[:session_index])

    # sign the response
    private_key = AuthenticationProvider::SAML.private_key
    private_key = nil if sig_alg.nil?
    result = SAML2::Bindings::HTTPRedirect.encode(logout_request,
                                                  private_key: private_key,
                                                  sig_alg: sig_alg)

    if debugging? && debug_get(:logged_in_user_id) == current_user.id
      debug_set(:logout_request_id, logout_request.id)
      debug_set(:logout_to_idp_url, result)
      debug_set(:logout_to_idp_xml, logout_request.to_s)
      debug_set(:debugging, t('debug.logout_redirect', "LogoutRequest sent to IdP"))
    end

    result
  end
end
