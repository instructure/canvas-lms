require_relative '../common'
require_relative '../helpers/accounts_auth_configs_common'

describe 'account authentication' do
  include_context 'in-process server selenium tests'
  include AccountsAuthConfigsCommon

  before(:each) do
    course_with_admin_logged_in
  end

  describe 'sso settings' do

    it 'should save', priority: "1", test_id: 249778 do
      add_sso_config
      @account = Account.default
      expect(@account.login_handle_name).to eq 'login'
      expect(@account.change_password_url).to eq 'http://test.example.com'
      expect(@account.auth_discovery_url).to eq 'http://test.example.com'
    end

    it 'should update', priority: "1", test_id: 249779 do
      add_sso_config
      f("#sso_settings_login_handle_name").clear
      f("#sso_settings_change_password_url").clear
      f("#sso_settings_auth_discovery_url").clear
      f("#edit_sso_settings button[type='submit']").click

      @account = Account.default
      expect(@account.login_handle_name).to eq nil
      expect(@account.change_password_url).to eq nil
      expect(@account.auth_discovery_url).to eq nil
    end
  end

  describe 'identity provider' do

    context 'ldap' do
      it 'should allow creation of config', priority: "1", test_id: 250262 do
        add_ldap_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_host).to eq 'host.example.dev'
        expect(config.auth_port).to eq 1
        expect(config.auth_over_tls).to eq 'simple_tls'
        expect(config.auth_base).to eq 'base'
        expect(config.auth_filter).to eq 'filter'
        expect(config.auth_username).to eq 'username'
        expect(config.auth_decrypted_password).to eq 'password'

        expect(Account.default.authentication_providers.active.count).to eq 2
      end

      it 'should allow update of config', priority: "1", test_id: 250263 do
        add_ldap_config
        config_id = Account.default.authentication_providers.active.last.id
        ldap_form = f("#edit_ldap#{config_id}")
        ldap_form.find_element(:id, 'authentication_provider_auth_host').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_port').clear
        f("label[for=no_tls_#{config_id}]").click
        ldap_form.find_element(:id, 'authentication_provider_auth_base').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_filter').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_username').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_password').send_keys('newpassword')
        ldap_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_host).to eq ''
        expect(config.auth_port).to eq nil
        expect(config.auth_over_tls).to eq nil
        expect(config.auth_base).to eq ''
        expect(config.auth_filter).to eq ''
        expect(config.auth_username).to eq ''
        expect(config.auth_decrypted_password).to eq 'newpassword'
      end

      it 'should allow deletion of config', priority: "1", test_id: 250264 do
        add_ldap_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end
        expect(Account.default.authentication_providers.active.count).to eq 1
      end

      it 'should allow creation of multiple configs', priority: "2", test_id: 268056 do
        add_ldap_config(1)
        expect(error_displayed?).to be_falsey
        add_ldap_config(2)
        expect(error_displayed?).to be_falsey
      end

      it 'should allow deletion of multiple configs', priority: "2", test_id: 250265 do
        add_ldap_config(1)
        add_ldap_config(2)
        expect(Account.default.authentication_providers.active.count).to eq 3
        expect_new_page_load(true) do
          f('.delete_auth_link').click
          expect(alert_present?).to be_truthy
          accept_alert
        end
        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 4
      end
    end

    context 'saml' do
      it 'should allow creation of config', priority: "1", test_id: 250266 do
        add_saml_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.idp_entity_id).to eq 'entity.example.dev'
        expect(config.log_in_url).to eq 'login.example.dev'
        expect(config.log_out_url).to eq 'logout.example.dev'
        expect(config.certificate_fingerprint).to eq 'abc123'
        expect(config.login_attribute).to eq 'nameid'
        expect(config.identifier_format).to eq 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
        expect(config.requested_authn_context).to eq nil
        expect(config.parent_registration).to be_falsey
      end

      it 'should allow update of config', priority: "1", test_id: 250267 do
        add_saml_config
        config_id = Account.default.authentication_providers.active.last.id
        saml_form = f("#edit_saml#{config_id}")
        f("#authentication_provider_idp_entity_id").clear
        f("#authentication_provider_log_in_url").clear
        f("#authentication_provider_log_out_url").clear
        f("#authentication_provider_certificate_fingerprint").clear
        saml_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.idp_entity_id).to eq ''
        expect(config.log_in_url).to eq ''
        expect(config.log_out_url).to eq ''
        expect(config.certificate_fingerprint).to eq ''
        expect(config.login_attribute).to eq 'nameid'
        expect(config.identifier_format).to eq 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
        expect(config.requested_authn_context).to eq nil
        expect(config.parent_registration).to be_falsey
      end

      it 'should allow deletion of config', priority: "1", test_id: 250268 do
        add_saml_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end

      context 'debugging' do
        it 'should start debug info', priority: "1", test_id: 250269 do
          enable_cache do
            start_saml_debug
            wait_for_ajaximations

            debug_info = f("#saml_debug_info")
            expect(debug_info.text).to match('Waiting for attempted login')
          end
        end

        it 'should refresh debug info', priority: "1", test_id: 250270 do
          enable_cache do
            start_saml_debug
            wait_for_ajaximations

            aac = Account.default.authentication_providers.active.last
            aac.debugging_keys.each_with_index do |key, i|
              aac.debug_set(key, "testvalue#{i}")
            end

            refresh = f("#refresh_saml_debugging")
            refresh.click
            wait_for_ajaximations

            debug_info = f("#saml_debug_info")

            aac.debugging_keys.each_with_index do |_, i|
              expect(debug_info.text).to match("testvalue#{i}")
            end
          end
        end

        it 'should stop debug info', priority: "1", test_id: 250271 do
          enable_cache do
            start_saml_debug
            wait_for_ajaximations

            stop = f("#stop_saml_debugging")

            stop.click
            wait_for_ajaximations

            aac = Account.default.authentication_providers.active.last
            expect(aac.debugging?).to eq false

            aac.debugging_keys.each do |key|
              expect(aac.debug_get(key)).to eq nil
            end
          end
        end
      end

      context 'federated attributes' do
        let!(:ap) do
          Account.default.authentication_providers.create!(auth_type: 'saml')
        end

        it 'saves federated attributes' do
          get "/accounts/self/authentication_providers"
          click_option("select.canvas_attribute", "locale")
          f(".add_federated_attribute_button").click
          f("input[name='authentication_provider[federated_attributes][locale][attribute]']").send_keys("provider_locale")
          saml_form = f("#edit_saml#{ap.id}")
          expect_new_page_load do
            saml_form.find("button[type='submit']").click
          end

          ap.reload
          expect(ap.federated_attributes).to eq({ 'locale' => { 'attribute' => 'provider_locale',
                                                                 'provisioning_only' => false} })
          expect(f("input[name='authentication_provider[federated_attributes][locale][attribute]']")[:value]).to eq 'provider_locale'
        end

        it 'shows and saves provisioning only checkboxes' do
          get "/accounts/self/authentication_providers"
          click_option("select.canvas_attribute", "locale")
          f(".add_federated_attribute_button").click
          f("input[name='authentication_provider[federated_attributes][locale][attribute]']").send_keys("provider_locale")
          f('.jit_provisioning_checkbox').click
          provisioning_only = f("input[name='authentication_provider[federated_attributes][locale][provisioning_only]']")
          expect(provisioning_only).to be_displayed
          provisioning_only.click

          saml_form = f("#edit_saml#{ap.id}")
          expect_new_page_load do
            saml_form.find("button[type='submit']").click
          end

          ap.reload
          expect(ap.federated_attributes).to eq({ 'locale' => { 'attribute' => 'provider_locale',
                                                                'provisioning_only' => true} })
          expect(f("input[name='authentication_provider[federated_attributes][locale][attribute]']").attribute('value')).to eq 'provider_locale'
          expect(is_checked("input[name='authentication_provider[federated_attributes][locale][provisioning_only]']:visible")).to eq true
        end

        it 'hides provisioning only when jit provisioning is disabled' do
          ap.update_attribute(:federated_attributes, { 'locale' => 'provider_locale' })
          ap.update_attribute(:jit_provisioning, true)
          get "/accounts/self/authentication_providers"

          provisioning_only = "input[name='authentication_provider[federated_attributes][locale][provisioning_only]']"
          expect(f(provisioning_only)).to be_displayed
          f('.jit_provisioning_checkbox').click
          expect(f(provisioning_only)).not_to be_displayed
        end

        it 'clears provisioning only when toggling jit provisioning' do
          get "/accounts/self/authentication_providers"
          click_option("select.canvas_attribute", "locale")
          f(".add_federated_attribute_button").click
          f("input[name='authentication_provider[federated_attributes][locale][attribute]']").send_keys("provider_locale")
          f('.jit_provisioning_checkbox').click
          provisioning_only = "input[name='authentication_provider[federated_attributes][locale][provisioning_only]']"
          expect(f(provisioning_only)).to be_displayed
          f(provisioning_only).click
          expect(is_checked("input[name='authentication_provider[federated_attributes][locale][provisioning_only]']:visible")).to eq true
          f('.jit_provisioning_checkbox').click
          f('.jit_provisioning_checkbox').click
          expect(is_checked("input[name='authentication_provider[federated_attributes][locale][provisioning_only]']:visible")).to eq false
        end

        it 'hides the add attributes button when all are added' do
          get "/accounts/self/authentication_providers"
          AccountAuthorizationConfig::CANVAS_ALLOWED_FEDERATED_ATTRIBUTES.length.times do
            f(".add_federated_attribute_button").click
          end
          expect(f(".add_federated_attribute_button")).not_to be_displayed

          fj(".remove_federated_attribute:visible").click
          expect(f(".add_federated_attribute_button")).to be_displayed
          expect(ffj("select.canvas_attribute:visible option").length).to eq 1
        end

        it 'can remove all attributes' do
          ap.update_attribute(:federated_attributes, { 'locale' => 'provider_locale' })
          get "/accounts/self/authentication_providers"

          fj(".remove_federated_attribute:visible").click
          saml_form = f("#edit_saml#{ap.id}")
          expect_new_page_load do
            saml_form.find("button[type='submit']").click
          end

          expect(ap.reload.federated_attributes).to eq({})
        end

        it "doesn't include screenreader text when removing attributes" do
          ap.update_attribute(:federated_attributes, { 'locale' => 'provider_locale' })
          get "/accounts/self/authentication_providers"

          f(".add_federated_attribute_button").click
          # remove an attribute that was already on the page, and one that was dynamically added
          2.times do
            fj(".remove_federated_attribute:visible").click
          end
          available = ff("#edit_saml#{ap.id} .federated_attributes_select option")
          expect(available.any? { |attr| attr.text =~ /attribute/i }).to eq false
        end
      end
    end

    context 'cas' do
      it 'should allow creation of config', priority: "1", test_id: 250272 do
        add_cas_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_base).to eq 'http://auth.base.dev'
      end

      it 'should allow update of config', priority: "1", test_id: 250273 do
        add_cas_config
        config_id = Account.default.authentication_providers.active.last.id
        cas_form = f("#edit_cas#{config_id}")
        cas_form.find('#authentication_provider_auth_base').clear
        cas_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_base).to eq ''
      end

      it 'should allow deletion of config', priority: "1", test_id: 250274 do
        add_cas_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'facebook' do
      it 'should allow creation of config', priority: "2", test_id: 250275 do
        add_facebook_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '123'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250276 do
        add_facebook_config
        config_id = Account.default.authentication_providers.active.last.id
        facebook_form = f("#edit_facebook#{config_id}")
        f("#authentication_provider_app_id").clear
        facebook_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
      end

      it 'should allow deletion of config', priority: "2", test_id: 250277 do
        add_facebook_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'github' do
      it 'should allow creation of config', priority: "2", test_id: 250278 do
        add_github_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_host).to eq 'github.com'
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250279 do
        add_github_config
        config_id = Account.default.authentication_providers.active.last.id
        github_form = f("#edit_github#{config_id}")
        github_form.find_element(:id, 'authentication_provider_domain').clear
        github_form.find_element(:id, 'authentication_provider_client_id').clear
        github_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.auth_host).to eq ''
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250280 do
        add_github_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'google' do
      it 'should allow creation of config', priority: "2", test_id: 250281 do
        add_google_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2", test_id: 250282 do
        add_google_config
        config_id = Account.default.authentication_providers.active.last.id
        google_form = f("#edit_google#{config_id}")
        google_form.find_element(:id, 'authentication_provider_client_id').clear
        google_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250283 do
        add_google_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'linkedin' do
      it 'should allow creation of config', priority: "2", test_id: 250284 do
        add_linkedin_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250285 do
        add_linkedin_config
        config_id = Account.default.authentication_providers.active.last.id
        linkedin_form = f("#edit_linkedin#{config_id}")
        linkedin_form.find_element(:id, 'authentication_provider_client_id').clear
        linkedin_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250286 do
        add_linkedin_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'openid connect' do
      it 'should allow creation of config', priority: "2", test_id: 250287 do
        add_openid_connect_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '1234'
        expect(config.log_in_url).to eq 'http://authorize.url.dev'
        expect(config.auth_base).to eq 'http://token.url.dev'
        expect(config.requested_authn_context).to eq 'scope'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2", test_id: 250288 do
        add_openid_connect_config
        config_id = Account.default.authentication_providers.active.last.id
        openid_connect_form = f("#edit_openid_connect#{config_id}")
        openid_connect_form.find_element(:id, 'authentication_provider_client_id').clear
        f("#authentication_provider_authorize_url").clear
        f("#authentication_provider_token_url").clear
        f("#authentication_provider_scope").clear
        openid_connect_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
        expect(config.log_in_url).to eq ''
        expect(config.auth_base).to eq ''
        expect(config.requested_authn_context).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250289 do
        add_openid_connect_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'twitter' do
      it 'should allow creation of config', priority: "2", test_id: 250290 do
        add_twitter_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'user_id'
      end

      it 'should allow update of config', priority: "2", test_id: 250291 do
        add_twitter_config
        config_id = Account.default.authentication_providers.active.last.id
        twitter_form = f("#edit_twitter#{config_id}")
        twitter_form.find_element(:id, 'authentication_provider_consumer_key').clear
        twitter_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'user_id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250292 do
        add_twitter_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

    context 'microsoft' do
      it 'should allow creation of config', priority: "2" do
        expect(Account.default.authentication_providers.active.count).to eq 1
        add_microsoft_config
        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2" do
        add_microsoft_config
        config_id = Account.default.authentication_providers.active.last.id

        microsoft_form = f("#edit_microsoft#{config_id}")
        microsoft_form.find_element(:id, 'authentication_provider_application_id').clear
        microsoft_form.find("button[type='submit']").click

        keep_trying_until { expect(Account.default.authentication_providers.active.count).to eq 2 }
        config = Account.default.authentication_providers.active.last
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2" do
        add_microsoft_config
        config_id = Account.default.authentication_providers.active.last.id
        config = "#delete-aac-#{config_id}"
        expect_new_page_load(true) do
          f(config).click
        end

        expect(Account.default.authentication_providers.active.count).to eq 1
        expect(Account.default.authentication_providers.count).to eq 2
      end
    end

  end
end
