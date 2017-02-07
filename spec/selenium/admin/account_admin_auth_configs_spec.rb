require_relative '../common'
require_relative '../helpers/accounts_auth_configs_common'

describe 'account authentication' do
  include_context 'in-process server selenium tests'
  include AccountsAuthConfigsCommon

  before(:each) do
    course_with_admin_logged_in
  end

  describe 'sso settings' do

    let(:login_handle_name) { f('#sso_settings_login_handle_name') }
    let(:change_password_url) { f('#sso_settings_change_password_url') }
    let(:auth_discovery_url) { f('#sso_settings_auth_discovery_url') }

    it 'should save', priority: "1", test_id: 249778 do
      add_sso_config
      expect(login_handle_name).to have_value 'login'
      expect(change_password_url).to have_value 'http://test.example.com'
      expect(auth_discovery_url).to have_value 'http://test.example.com'
    end

    it 'should update', priority: "1", test_id: 249779 do
      add_sso_config
      login_handle_name.clear
      change_password_url.clear
      auth_discovery_url.clear
      f("#edit_sso_settings button[type='submit']").click
      expect(login_handle_name).not_to have_value 'login'
      expect(change_password_url).not_to have_value 'http://test.example.com'
      expect(auth_discovery_url).not_to have_value 'http://test.example.com'
    end
  end

  describe 'identity provider' do

    context 'ldap' do

      let!(:ldap_aac) { AccountAuthorizationConfig::LDAP }

      it 'should allow creation of config', priority: "1", test_id: 250262 do
        add_ldap_config
        keep_trying_until { expect(ldap_aac.active.count).to eq 1 }
        config = ldap_aac.active.last.reload
        expect(config.auth_host).to eq 'host.example.dev'
        expect(config.auth_port).to eq 1
        expect(config.auth_over_tls).to eq 'simple_tls'
        expect(config.auth_base).to eq 'base'
        expect(config.auth_filter).to eq 'filter'
        expect(config.auth_username).to eq 'username'
        expect(config.auth_decrypted_password).to eq 'password'
      end

      it 'should allow update of config', priority: "1", test_id: 250263 do
        add_ldap_config
        ldap_form = f("#edit_ldap#{ldap_aac.active.last.id}")
        ldap_form.find_element(:id, 'authentication_provider_auth_host').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_port').clear
        f("label[for=no_tls_#{ldap_aac.active.last.id}]").click
        ldap_form.find_element(:id, 'authentication_provider_auth_base').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_filter').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_username').clear
        ldap_form.find_element(:id, 'authentication_provider_auth_password').send_keys('newpassword')
        ldap_form.find("button[type='submit']").click
        wait_for_ajax_requests

        config = ldap_aac.active.last.reload
        expect(ldap_aac.active.count).to eq 1
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
        f("#delete-aac-#{ldap_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(ldap_aac.active.count).to eq 0
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
        keep_trying_until { expect(ldap_aac.active.count).to eq 2 }
        f('.delete_auth_link').click
        expect(alert_present?).to be_truthy
        accept_alert
        wait_for_ajax_requests

        expect(ldap_aac.active.count).to eq 0
        expect(ldap_aac.count).to eq 2
      end
    end

    context 'saml' do

      let!(:saml_aac) { AccountAuthorizationConfig::SAML }

      it 'should allow creation of config', priority: "1", test_id: 250266 do
        add_saml_config
        keep_trying_until { expect(saml_aac.active.count).to eq 1 }
        config = saml_aac.active.last.reload
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
        saml_form = f("#edit_saml#{saml_aac.active.last.id}")
        f("#authentication_provider_idp_entity_id").clear
        f("#authentication_provider_log_in_url").clear
        f("#authentication_provider_log_out_url").clear
        f("#authentication_provider_certificate_fingerprint").clear
        saml_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(saml_aac.active.count).to eq 1
        config = saml_aac.active.last.reload
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
        f("#delete-aac-#{saml_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(saml_aac.active.count).to eq 0
        expect(saml_aac.count).to eq 1
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

      let!(:cas_aac) { AccountAuthorizationConfig::CAS }

      it 'should allow creation of config', priority: "1", test_id: 250272 do
        add_cas_config
        keep_trying_until { expect(cas_aac.active.count).to eq 1 }
        config = cas_aac.active.last.reload
        expect(config.auth_base).to eq 'http://auth.base.dev'
      end

      it 'should allow update of config', priority: "1", test_id: 250273 do
        add_cas_config
        cas_form = f("#edit_cas#{cas_aac.active.last.id}")
        cas_form.find('#authentication_provider_auth_base').clear
        cas_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(cas_aac.active.count).to eq 1
        config = cas_aac.active.last.reload
        expect(config.auth_base).to eq ''
      end

      it 'should allow deletion of config', priority: "1", test_id: 250274 do
        add_cas_config
        f("#delete-aac-#{cas_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(cas_aac.active.count).to eq 0
        expect(cas_aac.count).to eq 1
      end
    end

    context 'facebook' do

      let!(:facebook_aac) { AccountAuthorizationConfig::Facebook }

      it 'should allow creation of config', priority: "2", test_id: 250275 do
        add_facebook_config
        keep_trying_until { expect(facebook_aac.active.count).to eq 1 }
        config = facebook_aac.active.last.reload
        expect(config.entity_id).to eq '123'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250276 do
        add_facebook_config
        config_id = facebook_aac.active.last.id
        facebook_form = f("#edit_facebook#{config_id}")
        f("#authentication_provider_app_id").clear
        facebook_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(facebook_aac.active.count).to eq 1
        config = facebook_aac.active.last.reload
        expect(config.entity_id).to eq ''
      end

      it 'should allow deletion of config', priority: "2", test_id: 250277 do
        add_facebook_config
        f("#delete-aac-#{facebook_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(facebook_aac.active.count).to eq 0
        expect(facebook_aac.count).to eq 1
      end
    end

    context 'github' do

      let!(:github_aac) { AccountAuthorizationConfig::GitHub }

      it 'should allow creation of config', priority: "2", test_id: 250278 do
        add_github_config
        keep_trying_until { expect(github_aac.active.count).to eq 1 }
        config = github_aac.active.last.reload
        expect(config.auth_host).to eq 'github.com'
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250279 do
        add_github_config
        github_form = f("#edit_github#{github_aac.active.last.id}")
        github_form.find_element(:id, 'authentication_provider_domain').clear
        github_form.find_element(:id, 'authentication_provider_client_id').clear
        github_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(github_aac.active.count).to eq 1
        config = github_aac.active.last.reload
        expect(config.auth_host).to eq ''
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250280 do
        add_github_config
        f("#delete-aac-#{github_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(github_aac.active.count).to eq 0
        expect(github_aac.count).to eq 1
      end
    end

    context 'google' do

      let!(:google_aac) { AccountAuthorizationConfig::Google }

      it 'should allow creation of config', priority: "2", test_id: 250281 do
        add_google_config
        keep_trying_until { expect(google_aac.active.count).to eq 1 }
        config = google_aac.active.last.reload
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2", test_id: 250282 do
        add_google_config
        google_form = f("#edit_google#{google_aac.active.last.id}")
        google_form.find_element(:id, 'authentication_provider_client_id').clear
        google_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(google_aac.active.count).to eq 1
        config = google_aac.active.last.reload
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250283 do
        add_google_config
        f("#delete-aac-#{google_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(google_aac.active.count).to eq 0
        expect(google_aac.count).to eq 1
      end
    end

    context 'linkedin' do

      let!(:linkedin_aac) { AccountAuthorizationConfig::LinkedIn }

      it 'should allow creation of config', priority: "2", test_id: 250284 do
        add_linkedin_config
        keep_trying_until { expect(linkedin_aac.active.count).to eq 1 }
        config = linkedin_aac.active.last.reload
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow update of config', priority: "2", test_id: 250285 do
        add_linkedin_config
        linkedin_form = f("#edit_linkedin#{linkedin_aac.active.last.id}")
        linkedin_form.find_element(:id, 'authentication_provider_client_id').clear
        linkedin_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(linkedin_aac.active.count).to eq 1
        config = linkedin_aac.active.last.reload
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250286 do
        add_linkedin_config
        f("#delete-aac-#{linkedin_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(linkedin_aac.active.count).to eq 0
        expect(linkedin_aac.count).to eq 1
      end
    end

    context 'openid connect' do

      let!(:openid_aac) { AccountAuthorizationConfig::OpenIDConnect }

      it 'should allow creation of config', priority: "2", test_id: 250287 do
        add_openid_connect_config
        keep_trying_until { expect(openid_aac.active.count).to eq 1 }
        config = openid_aac.active.last.reload
        expect(config.entity_id).to eq '1234'
        expect(config.log_in_url).to eq 'http://authorize.url.dev'
        expect(config.auth_base).to eq 'http://token.url.dev'
        expect(config.requested_authn_context).to eq 'scope'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2", test_id: 250288 do
        add_openid_connect_config
        openid_connect_form = f("#edit_openid_connect#{openid_aac.active.last.id}")
        openid_connect_form.find_element(:id, 'authentication_provider_client_id').clear
        f("#authentication_provider_authorize_url").clear
        f("#authentication_provider_token_url").clear
        f("#authentication_provider_scope").clear
        openid_connect_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(openid_aac.active.count).to eq 1
        config = openid_aac.active.last.reload
        expect(config.entity_id).to eq ''
        expect(config.log_in_url).to eq ''
        expect(config.auth_base).to eq ''
        expect(config.requested_authn_context).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250289 do
        add_openid_connect_config
        f("#delete-aac-#{openid_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(openid_aac.active.count).to eq 0
        expect(openid_aac.count).to eq 1
      end
    end

    context 'twitter' do

      let!(:twitter_aac) { AccountAuthorizationConfig::Twitter }

      it 'should allow creation of config', priority: "2", test_id: 250290 do
        add_twitter_config
        keep_trying_until { expect(twitter_aac.active.count).to eq 1 }
        config = twitter_aac.active.last.reload
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'user_id'
      end

      it 'should allow update of config', priority: "2", test_id: 250291 do
        add_twitter_config
        twitter_form = f("#edit_twitter#{twitter_aac.active.last.id}")
        twitter_form.find_element(:id, 'authentication_provider_consumer_key').clear
        twitter_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(twitter_aac.active.count).to eq 1
        config = twitter_aac.active.last.reload
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'user_id'
      end

      it 'should allow deletion of config', priority: "2", test_id: 250292 do
        add_twitter_config
        f("#delete-aac-#{twitter_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(twitter_aac.active.count).to eq 0
        expect(twitter_aac.count).to eq 1
      end
    end

    context 'microsoft' do

      let!(:microsoft_aac) { AccountAuthorizationConfig::Microsoft }

      it 'should allow creation of config', priority: "2" do
        expect(microsoft_aac.active.count).to eq 0
        add_microsoft_config
        keep_trying_until { expect(microsoft_aac.active.count).to eq 1 }
        config = microsoft_aac.active.last.reload
        expect(config.entity_id).to eq '1234'
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow update of config', priority: "2" do
        add_microsoft_config
        microsoft_form = f("#edit_microsoft#{microsoft_aac.active.last.id}")
        microsoft_form.find_element(:id, 'authentication_provider_application_id').clear
        microsoft_form.find("button[type='submit']").click
        wait_for_ajax_requests

        expect(microsoft_aac.active.count).to eq 1
        config = microsoft_aac.active.last.reload
        expect(config.entity_id).to eq ''
        expect(config.login_attribute).to eq 'sub'
      end

      it 'should allow deletion of config', priority: "2" do
        add_microsoft_config
        f("#delete-aac-#{microsoft_aac.active.last.id}").click
        accept_alert
        wait_for_ajax_requests

        expect(microsoft_aac.active.count).to eq 0
        expect(microsoft_aac.count).to eq 1
      end
    end

  end
end
