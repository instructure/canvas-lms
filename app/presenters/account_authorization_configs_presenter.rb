class AccountAuthorizationConfigsPresenter
  attr_reader :account

  def initialize(acc)
    @account = acc
  end

  def configs
    account.account_authorization_configs.to_a
  end

  def auth_types
    AccountAuthorizationConfig::VALID_AUTH_TYPES
  end

  def needs_discovery_url?
    configs.count >= 2 &&
      configs.any?{|c| !c.is_a?(AccountAuthorizationConfig::LDAP) }
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

  def form_id(config)
    return "#{config.auth_type}_form" if config.new_record?
    'auth_form'
  end

  def form_class(config)
    return 'class="active"' unless config.new_record?
    ''
  end

  def sso_options
    options = [[:CAS, 'cas'], [:LDAP, 'ldap']]
    options << [:SAML, 'saml'] if saml_enabled?
    options
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

  def saml_login_attributes
    return {} unless saml_enabled?
    AccountAuthorizationConfig::SAML.login_attributes
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

  def canvas_auth_only?
    account.canvas_authentication? && !account.ldap_authentication?
  end

  def login_placeholder
    AccountAuthorizationConfig.default_delegated_login_handle_name
  end

  def login_name
    account.login_handle_name_with_inference
  end

  def new_config(auth_type)
    account.account_authorization_configs.new(auth_type)
  end

  private
  def ip_addresses_setting
    Setting.get('account_authorization_config_ip_addresses', nil)
  end

end
