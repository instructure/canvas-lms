class AccountAuthorizationConfigsPresenter
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper

  attr_reader :account

  def initialize(acc)
    @account = acc
  end

  def configs
    @configs ||= account.authentication_providers.active.to_a
  end

  def new_auth_types
    AccountAuthorizationConfig::VALID_AUTH_TYPES.map do |auth_type|
      klass = AccountAuthorizationConfig.find_sti_class(auth_type)
      next unless klass.enabled?
      next if klass.singleton? && configs.any? { |aac| aac.is_a?(klass) }
      klass
    end.compact
  end

  def needs_unknown_user_url?
    configs.any? { |c| c.is_a?(AccountAuthorizationConfig::Delegated) }
  end

  def login_url_options(aac)
    options = { controller: "login/#{aac.auth_type}", action: :new }
    if !aac.is_a?(AccountAuthorizationConfig::LDAP) &&
      configs.many? { |other| other.auth_type == aac.auth_type }
      options[:id] = aac
    end
    options
  end

  def auth?
    configs.any?
  end

  def ldap_config?
    ldap_configs.size > 0
  end

  def ldap_ips
    ldap_configs.map(&:ldap_ip).to_sentence
  end

  def ldap_configs
    configs.select{|c| c.is_a?(AccountAuthorizationConfig::LDAP) }
  end

  def saml_configs
    configs.select{|c| c.is_a?(AccountAuthorizationConfig::SAML) }
  end

  def cas_configs
    configs.select{|c| c.is_a?(AccountAuthorizationConfig::CAS) }
  end


  def sso_options
    new_auth_types.map do |auth_type|
      {
        name: auth_type.display_name,
        value: auth_type.sti_name
      }
    end
  end

  def position_options(config)
    position_options = (1..configs.length).map{|i| [i, i] }
    config.new_record? ? [["Last", nil]] + position_options : position_options
  end

  def ips_configured?
    !!ip_addresses_setting.presence
  end

  def ip_list
    return "" unless ips_configured?
    ip_addresses_setting.split(",").map(&:strip).join("\n")
  end

  def saml_identifiers
    return [] unless saml_enabled?
    Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS
  end

  def saml_debugging?
     !saml_configs.empty? && saml_configs.any?(&:debugging?)
  end

  def login_attribute_for(config)
    saml_login_attributes.invert[config.login_attribute]
  end

  def saml_authn_contexts(base = Onelogin::Saml::AuthnContexts::ALL_CONTEXTS)
    return [] unless saml_enabled?
    [["No Value", nil]] + base.sort
  end

  def saml_enabled?
    AccountAuthorizationConfig::SAML.enabled?
  end

  def login_placeholder
    AccountAuthorizationConfig.default_delegated_login_handle_name
  end

  def login_name
    account.login_handle_name_with_inference
  end

  def new_config(auth_type)
    account.authentication_providers.new(auth_type)
  end

  def parent_reg_selected
    account.parent_registration?
  end

  def available_federated_attributes(aac)
    AccountAuthorizationConfig::CANVAS_ALLOWED_FEDERATED_ATTRIBUTES - aac.federated_attributes.keys
  end

  def federated_provider_attribute(aac, canvas_attribute = nil, selected = nil)
    name = "authentication_provider[federated_attributes][#{canvas_attribute}][attribute]" if selected
    if aac.class.recognized_federated_attributes.nil?
      if selected
        text_field_tag(name, selected, id: name)
      else
        text_field_tag(nil)
      end
    else
      select_tag(name, options_for_select(aac.class.recognized_federated_attributes, selected), class: 'ic-Input', id: name)
    end
  end

  private
  def ip_addresses_setting
    Setting.get('account_authorization_config_ip_addresses', nil)
  end

end
