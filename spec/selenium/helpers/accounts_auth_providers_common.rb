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

require_relative "../common"

module AuthenticationProvidersCommon
  def add_auth_type(auth_type)
    click_option("#add-authentication-provider select", auth_type)
    # public/javascripts/authentication_providers.js waits 100ms to focus
    # the first input; this can cause selenium to get focus-jacked and
    # put something in the wrong one :'(
    sleep 0.1
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
    ldap_form.find_element(:id, 'auth_host_ldap').send_keys('host.example.dev')
    ldap_form.find_element(:id, 'auth_port_ldap').send_keys('1')
    f("label[for=simple_tls_ldap]").click
    ldap_form.find_element(:id, 'auth_base_ldap').send_keys('base')
    ldap_form.find_element(:id, 'auth_filter_ldap').send_keys('filter')
    ldap_form.find_element(:id, 'auth_username_ldap').send_keys('username')
    ldap_form.find_element(:id, 'auth_password_ldap').send_keys('password')
    f("#new_ldap button[type='submit']").click
    wait_for_ajaximations
  end

  def clear_ldap_form
    config_id = Account.default.authentication_providers.active.last.id
    ldap_form = f("#edit_ldap#{config_id}")
    ldap_form.find_element(:id, 'auth_host_ldap').clear
    ldap_form.find_element(:id, 'auth_port_ldap').clear
    f("label[for=no_tls_#{config_id}]").click
    ldap_form.find_element(:id, 'auth_base_ldap').clear
    ldap_form.find_element(:id, 'auth_filter_ldap').clear
    ldap_form.find_element(:id, 'auth_username_ldap').clear
    ldap_form.find_element(:id, 'auth_password_ldap').send_keys('password2')
  end

  def add_saml_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('SAML')
    saml_form = f("#new_saml")
    set_value(f("#idp_entity_id_saml"), 'entity.example')
    set_value(f("#log_in_url_saml"), 'login.example')
    set_value(f("#log_out_url_saml"), 'logout.example')
    set_value(f("#certificate_fingerprint_saml"), 'abc123')
    f("#new_saml button[type='submit']").click
  end

  def start_saml_debug
    Account.default.authentication_providers.create!(auth_type: 'saml')
    get "/accounts/#{Account.default.id}/authentication_providers"
    start = f(".start_debugging")
    start.click
  end

  def add_cas_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('CAS')
    cas_form = f("#new_cas")
    cas_form.find_element(:id, 'auth_base_cas').send_keys('http://auth.base.dev')
    f("#new_cas button[type='submit']").click
    wait_for_ajaximations
  end

  def add_facebook_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Facebook')
    facebook_form = f("#new_facebook")
    set_value(f("#app_id_facebook"), '123')
    f("#new_facebook button[type='submit']").click
    wait_for_ajaximations
  end

  def add_github_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('GitHub')
    github_form = f("#new_github")
    set_value(f("#domain_github"), 'github.com')
    github_form.find_element(:id, 'client_id_github').send_keys('1234')
    f("#new_github button[type='submit']").click
    wait_for_ajaximations
  end

  def add_google_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Google')
    google_form = f("#new_google")
    google_form.find_element(:id, 'client_id_google').send_keys('1234')
    f("#new_google button[type='submit']").click
    wait_for_ajaximations
  end

  def add_linkedin_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('LinkedIn')
    linkedin_form = f("#new_linkedin")
    linkedin_form.find_element(:id, 'client_id_linkedin').send_keys('1234')
    f("#new_linkedin button[type='submit']").click
    wait_for_ajaximations
  end

  def add_microsoft_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Microsoft')
    microsoft_form = f('#new_microsoft')
    microsoft_form.find_element(:id, 'application_id_microsoft').send_keys('1234')
    f("#new_microsoft button[type='submit']").click
    wait_for_ajaximations
  end

  def add_openid_connect_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('OpenID Connect')
    openid_connect_form = f("#new_openid_connect")
    openid_connect_form.find_element(:id, 'client_id_openid_connect').send_keys('1234')
    set_value(f("#authorize_url_openid_connect"), 'http://authorize.url.dev')
    set_value(f("#token_url_openid_connect"), 'http://token.url.dev')
    set_value(f("#scope_openid_connect"), 'scope')
    replace_content(openid_connect_form.find_element(:id, 'login_attribute_openid_connect'), 'sub')
    f("#new_openid_connect button[type='submit']").click
    wait_for_ajaximations
  end

  def add_twitter_config
    get "/accounts/#{Account.default.id}/authentication_providers"
    add_auth_type('Twitter')
    twitter_form = f("#new_twitter")
    twitter_form.find_element(:id, 'consumer_key_twitter').send_keys('1234')
    f("#new_twitter button[type='submit']").click
    wait_for_ajaximations
  end
end
