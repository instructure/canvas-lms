require_relative "../common"

module AccountsAuthConfigsCommon
  def add_auth_type(auth_type)
    f("#add-authentication-provider button").click
    ff("#add-authentication-provider a").each do |link|
      if link.text == auth_type
        link.click
      end
    end
  end

  def add_sso_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    sso_url = 'http://test.example.com'
    set_value(f("#sso_settings_login_handle_name"), 'login')
    set_value(f("#sso_settings_change_password_url"), sso_url)
    set_value(f("#sso_settings_auth_discovery_url"), sso_url)
    f("button[type='submit']").click
    wait_for_ajaximations
    Account.default.reload
  end

  def add_ldap_config(*)
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('LDAP')
    ldap_form = f("#new_ldap")
    ldap_form.find_element(:id, 'authentication_provider_auth_host').send_keys('host.example.dev')
    ldap_form.find_element(:id, 'authentication_provider_auth_port').send_keys('1')
    f("label[for=simple_tls_]").click
    ldap_form.find_element(:id, 'authentication_provider_auth_base').send_keys('base')
    ldap_form.find_element(:id, 'authentication_provider_auth_filter').send_keys('filter')
    ldap_form.find_element(:id, 'authentication_provider_auth_username').send_keys('username')
    ldap_form.find_element(:id, 'authentication_provider_auth_password').send_keys('password')
    f("#new_ldap button[type='submit']").click
    wait_for_ajaximations
  end

  def clear_ldap_form
    config_id = Account.default.authentication_providers.active.last.id
    ldap_form = f("#edit_ldap#{config_id}")
    ldap_form.find_element(:id, 'authentication_provider_auth_host').clear
    ldap_form.find_element(:id, 'authentication_provider_auth_port').clear
    f("label[for=no_tls_#{config_id}]").click
    ldap_form.find_element(:id, 'authentication_provider_auth_base').clear
    ldap_form.find_element(:id, 'authentication_provider_auth_filter').clear
    ldap_form.find_element(:id, 'authentication_provider_auth_username').clear
    ldap_form.find_element(:id, 'authentication_provider_auth_password').send_keys('password2')
  end

  def add_saml_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('SAML')
    saml_form = f("#new_saml")
    set_value(f("#authentication_provider_idp_entity_id"), 'entity.example.dev')
    set_value(f("#authentication_provider_log_in_url"), 'login.example.dev')
    set_value(f("#authentication_provider_log_out_url"), 'logout.example.dev')
    set_value(f("#authentication_provider_certificate_fingerprint"), 'abc123')
    f("#new_saml button[type='submit']").click
    wait_for_ajaximations
  end

  def start_saml_debug
    Account.default.authentication_providers.create!(auth_type: 'saml')
    get "/accounts/#{Account.default.id}/authentication_providers"
    start = f("#start_saml_debugging")
    start.click
  end

  def add_cas_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('CAS')
    cas_form = f("#new_cas")
    cas_form.find_element(:id, 'authentication_provider_auth_base').send_keys('http://auth.base.dev')
    f("#new_cas button[type='submit']").click
    wait_for_ajaximations
  end

  def add_facebook_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Facebook')
    facebook_form = f("#new_facebook")
    set_value(f("#authentication_provider_app_id"), '123')
    f("#new_facebook button[type='submit']").click
    wait_for_ajaximations
  end

  def add_github_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('GitHub')
    github_form = f("#new_github")
    set_value(f("#authentication_provider_domain"), 'github.com')
    github_form.find_element(:id, 'authentication_provider_client_id').send_keys('1234')
    f("#new_github button[type='submit']").click
    wait_for_ajaximations
  end

  def add_google_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Google')
    google_form = f("#new_google")
    google_form.find_element(:id, 'authentication_provider_client_id').send_keys('1234')
    f("#new_google button[type='submit']").click
    wait_for_ajaximations
  end

  def add_linkedin_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('LinkedIn')
    linkedin_form = f("#new_linkedin")
    linkedin_form.find_element(:id, 'authentication_provider_client_id').send_keys('1234')
    f("#new_linkedin button[type='submit']").click
    wait_for_ajaximations
  end

  def add_microsoft_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Microsoft')
    microsoft_form = f('#new_microsoft')
    microsoft_form.find_element(:id, 'authentication_provider_application_id').send_keys('1234')
    f("#new_microsoft button[type='submit']").click
    wait_for_ajaximations
  end

  def add_openid_connect_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('OpenID Connect')
    openid_connect_form = f("#new_openid_connect")
    openid_connect_form.find_element(:id, 'authentication_provider_client_id').send_keys('1234')
    set_value(f("#authentication_provider_authorize_url"), 'http://authorize.url.dev')
    set_value(f("#authentication_provider_token_url"), 'http://token.url.dev')
    set_value(f("#authentication_provider_scope"), 'scope')
    replace_content(openid_connect_form.find_element(:id, 'authentication_provider_login_attribute'), 'sub')
    f("#new_openid_connect button[type='submit']").click
    wait_for_ajaximations
  end

  def add_twitter_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Twitter')
    twitter_form = f("#new_twitter")
    twitter_form.find_element(:id, 'authentication_provider_consumer_key').send_keys('1234')
    f("#new_twitter button[type='submit']").click
    wait_for_ajaximations
  end
end
