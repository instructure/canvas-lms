# frozen_string_literal: true

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

require "rotp"

describe Login::CanvasController do
  before :once do
    user_with_pseudonym(username: "jtfrd@instructure.com", active_all: 1, password: "qwertyuiop")
  end

  describe "mobile layout decision" do
    let(:mobile_agents) do
      [
        "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
        "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; SCH-I800 Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Sprint APA9292KT Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
      ]
    end

    def confirm_mobile_layout
      mobile_agents.each do |agent|
        controller.js_env.clear
        request.env["HTTP_USER_AGENT"] = agent
        yield
        expect(response).to render_template(:mobile_login)
      end
    end

    it "renders normal layout if not iphone/ipod" do
      get "new"
      expect(response).to render_template(:new)
    end

    it "renders special iPhone/iPod layout if coming from one of those" do
      confirm_mobile_layout { get "new" }
    end

    it "renders special iPhone/iPod layout if coming from one of those and it's the wrong password'" do
      confirm_mobile_layout { post "create" }
    end

    it "renders a plain text error message on mobile, not the hash" do
      controller.js_env.clear
      request.env["HTTP_USER_AGENT"] = mobile_agents[0]
      post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "" } }
      expect(flash[:error]).to be_a(String)
    end
  end

  context "manage_robots_meta" do
    it "enables robot indexing by default" do
      get "new"
      expect(assigns[:allow_robot_indexing]).to be_truthy
    end

    it "allows robot indexing to be disabled" do
      Account.default.settings[:disable_login_search_indexing] = true
      Account.default.save!

      get "new"
      expect(assigns[:allow_robot_indexing]).to be_falsey
    end
  end

  it "shows sso buttons on load" do
    aac = Account.default.authentication_providers.create!(auth_type: "facebook")
    allow(Canvas::Plugin.find(:facebook)).to receive(:settings).and_return({})
    get "new"
    expect(assigns[:aacs_with_buttons]).to eq [aac]
  end

  it "still shows sso buttons on login error" do
    aac = Account.default.authentication_providers.create!(auth_type: "facebook")
    allow(Canvas::Plugin.find(:facebook)).to receive(:settings).and_return({})
    post "create"
    expect(assigns[:aacs_with_buttons]).to eq [aac]
  end

  it "re-renders if no user" do
    post "create"
    assert_status(400)
    expect(response).to render_template(:new)
  end

  it "re-renders if incorrect password" do
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "dvorak" } }
    assert_status(400)
    expect(response).to render_template(:new)
  end

  it "re-renders if no password given and render a hash for the error" do
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "" } }
    assert_status(400)
    expect(response).to render_template(:new)
    expect(flash[:error]).to be_a(Hash)
    expect(flash[:error][:html]).to match(/no password/i)
  end

  it "password auth should work" do
    session[:sentinel] = true
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
    # session reset
    expect(session[:sentinel]).to be_nil
  end

  it "doesn't allow suspended users" do
    @pseudonym.update!(workflow_state: "suspended")
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    assert_status(400)
    expect(response).to render_template(:new)
  end

  it "persists the auth provider if the feature flag is enabled" do
    Account.default.enable_feature!(:persist_inferred_authentication_providers)
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
    expect(assigns[:pseudonym_session].record.authentication_provider).to eq Account.default.canvas_authentication_provider

    # the auth provider got set on the pseudonym
    expect(@pseudonym.reload.authentication_provider).to eq Account.default.canvas_authentication_provider
  end

  it "sets, but does not persist, the auth provider if the feature flag is not enabled" do
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
    expect(assigns[:pseudonym_session].record.authentication_provider).to eq Account.default.canvas_authentication_provider

    # the auth provider did not get set on the pseudonym
    expect(@pseudonym.reload.authentication_provider).to be_nil
  end

  it "password auth should work for an explicit Canvas pseudonym" do
    @pseudonym.update_attribute(:authentication_provider, Account.default.canvas_authentication_provider)
    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "does not get tripped up by explicit and implicit pseudonyms" do
    pseudonym2 = @user.pseudonyms.create!(
      unique_id: "jtfrd@instructure.com",
      password: "qwertyuiop",
      password_confirmation: "qwertyuiop",
      authentication_provider: Account.default.canvas_authentication_provider
    )

    post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq pseudonym2
  end

  it "password auth should work with extra whitespace around unique id" do
    post "create", params: { pseudonym_session: { unique_id: " jtfrd@instructure.com ", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "re-renders if authenticity token is invalid and referer is not trusted" do
    expect(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
    session[:sentinel] = true
    post "create", params: { pseudonym_session: { unique_id: " jtfrd@instructure.com ", password: "qwertyuiop" },
                             authenticity_token: "42" }
    assert_status(400)
    expect(session[:sentinel]).to be true
    expect(response).to render_template(:new)
    expect(flash[:error]).to be_a(Hash)
    expect(flash[:error][:html]).to match(/invalid authenticity token/i)
  end

  it "re-renders if authenticity token is invalid and referer is trusted" do
    expect(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
    post "create", params: { pseudonym_session: { unique_id: " jtfrd@instructure.com ", password: "qwertyuiop" },
                             authenticity_token: "42" }
    assert_status(400)
    expect(response).to render_template(:new)
    expect(flash[:error]).to be_a(Hash)
    expect(flash[:error][:html]).to match(/invalid authenticity token/i)
  end

  it "logins if authenticity token is invalid and referer is trusted" do
    expect_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
    post "create", params: { pseudonym_session: { unique_id: " jtfrd@instructure.com ", password: "qwertyuiop" } }
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(login_success: 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "rejects canvas auth if Canvas auth is disabled" do
    Account.default.authentication_providers.create!(auth_type: "ldap")
    Account.default.canvas_authentication_provider.destroy
    get "new"
    assert_status(404)
  end

  context "ldap" do
    it "logs in a user with a identifier_format" do
      user_with_pseudonym(username: "12345", active_all: 1)
      @pseudonym.update_attribute(:sis_user_id, "12345")
      aac = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once
                                                                    .with("username", "password")
                                                                    .and_return([{ "uid" => ["12345"] }])
      Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
      expect_any_instantiation_of(aac).not_to receive(:ldap_bind_result)
      post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
      # the auth provider got set on the pseudonym
      expect(assigns[:pseudonym_session].record.authentication_provider).to eq aac
      expect(@pseudonym.reload.authentication_provider).to be_nil
    end

    it "works for a pseudonym explicitly linked to LDAP" do
      user_with_pseudonym(username: "12345", active_all: 1)
      aac = Account.default.authentication_providers.create!(auth_type: "ldap")
      expect_any_instantiation_of(@pseudonym).to receive(:valid_arbitrary_credentials?).and_return(true)
      @pseudonym.update_attribute(:authentication_provider, aac)
      post "create", params: { pseudonym_session: { unique_id: "12345", password: "password" } }
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    it "ignores a pseudonym explicitly linked to a different LDAP" do
      user_with_pseudonym(username: "12345", active_all: 1)
      aac = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
      aac2 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once
                                                                    .with("username", "password")
                                                                    .and_return([{ "uid" => ["12345"] }])
      expect_any_instantiation_of(aac2).to receive(:ldap_bind_result).once
                                                                     .with("username", "password")
                                                                     .and_return(nil)
      @pseudonym.update_attribute(:authentication_provider, aac2)
      post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
      assert_status(400)
    end

    it "only queries the LDAP server once, even with a differing identifier_format but a matching pseudonym" do
      user_with_pseudonym(username: "username", active_all: 1)
      aac = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once.with("username", "password").and_return(nil)
      post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
      assert_status(400)
      expect(response).to render_template(:new)
    end

    it "doesn't query the server at all if the enabled features don't require it, and there is no matching login" do
      ap = Account.default.authentication_providers.create!(auth_type: "ldap")
      expect_any_instantiation_of(ap).not_to receive(:ldap_bind_result)
      post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
      assert_status(400)
      expect(response).to render_template(:new)
    end

    it "provisions automatically when enabled" do
      ap = Account.default.authentication_providers.create!(auth_type: "ldap", jit_provisioning: true)
      expect_any_instantiation_of(ap).to receive(:ldap_bind_result).once
                                                                   .with("username", "password")
                                                                   .and_return([{ "uid" => ["12345"] }])
      unique_id = "username"
      expect(Account.default.pseudonyms.active.by_unique_id(unique_id)).to_not be_exists

      post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(login_success: 1))

      p = Account.default.pseudonyms.active.by_unique_id(unique_id).first!
      expect(p.authentication_provider).to eq ap
    end

    context "should properly set the session[:login_aac]" do
      it "when an ldap authentication provider was used with identifier_format" do
        user_with_pseudonym(username: "12345", active_all: 1)
        @pseudonym.update_attribute(:sis_user_id, "12345")
        aac1 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
        expect_any_instantiation_of(aac1).to receive(:ldap_bind_result).once
                                                                       .with("username", "password")
                                                                       .and_return(nil)
        aac2 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
        expect_any_instantiation_of(aac2).to receive(:ldap_bind_result).once
                                                                       .with("username", "password")
                                                                       .and_return([{ "uid" => ["12345"] }])

        post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
        expect(session[:login_aac]).to eq aac2.id
        expect(assigns[:pseudonym_session].record.authentication_provider).to eq aac2
      end

      it "when an ldap authentication provider was used without an identifier_format" do
        user_with_pseudonym(username: "username", active_all: 1)
        aac1 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: nil)
        expect_any_instantiation_of(aac1).to receive(:ldap_bind_result).once
                                                                       .with("username", "password")
                                                                       .and_return(nil)
        aac2 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: nil)
        expect_any_instantiation_of(aac2).to receive(:ldap_bind_result).once
                                                                       .with("username", "password")
                                                                       .and_return([{}])

        post "create", params: { pseudonym_session: { unique_id: "username", password: "password" } }
        expect(session[:login_aac]).to eq aac2.id
        expect(assigns[:pseudonym_session].record.authentication_provider).to eq aac2
      end

      it "when canvas authentication was used" do
        password = "correct-horse-battery-staple"
        user_with_pseudonym(username: "12345", active_all: 1, password:)
        aac1 = Account.default.authentication_providers.create!(auth_type: "ldap", identifier_format: "uid")
        expect_any_instantiation_of(aac1).to receive(:ldap_bind_result).once.and_return(nil)
        aac2 = Account.default.authentication_providers.find_by(auth_type: "canvas")

        post "create", params: { pseudonym_session: { unique_id: "12345", password: } }
        expect(session[:login_aac]).to eq aac2.id
      end
    end
  end

  context "trusted logins" do
    it "logins for a pseudonym from a different account" do
      account = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account.id])
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account:)
      Account.default.pseudonyms.create!(user: @user, unique_id: "someone")
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      expect(flash[:notice]).to be_present
    end

    it "sends users to their home domain if they have no associations with the current account" do
      account = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account.id])
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account:)
      allow(HostUrl).to receive(:context_host).with(Account.default, "test.host").and_return("account")
      allow(HostUrl).to receive(:context_host).with(account, "test.host").and_return("account2")
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(dashboard_url(host: "account2", cross_domain_login: "test.host"))
    end

    it "doesn't send admins elsewhere" do
      account = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account.id])
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account:)
      Account.default.account_users.create!(user: @user)
      allow(HostUrl).to receive(:context_host).with(Account.default, "test.host").and_return("account")
      allow(HostUrl).to receive(:context_host).with(account, "test.host").and_return("account2")
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      expect(flash[:notice]).to be_present
    end

    it "logins for a user with multiple identical pseudonyms" do
      account1 = Account.create!
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account: account1)
      Account.default.pseudonyms.create!(user: @user, unique_id: "someone")
      @pseudonym = @user.pseudonyms.create!(account: Account.site_admin,
                                            unique_id: "jt@instructure.com",
                                            password: "qwertyuiop",
                                            password_confirmation: "qwertyuiop")
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      # it should have preferred the site admin pseudonym
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    it "does not login for multiple users with identical pseudonyms" do
      account1 = Account.create!
      account2 = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account1.id, account2.id])
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account: account1)
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account: account2)
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).not_to be_successful
      expect(response).to render_template(:new)
    end

    it "logins a site admin user with other identical pseudonyms" do
      account1 = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account1.id, Account.site_admin.id])
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account: account1)
      user_with_pseudonym(username: "jt@instructure.com",
                          active_all: 1,
                          password: "qwertyuiop",
                          account: Account.site_admin)
      Account.default.pseudonyms.create!(user: @user, unique_id: "someone")
      post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      # it should have preferred the site admin pseudonym
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    context "sharding" do
      specs_require_sharding

      it "logins for a user from a different shard" do
        user_with_pseudonym(username: "jt@instructure.com",
                            active_all: 1,
                            password: "qwertyuiop",
                            account: Account.site_admin)
        Account.default.pseudonyms.create!(user: @user, unique_id: "someone")
        @shard1.activate do
          account = Account.create!
          allow(HostUrl).to receive(:default_domain_root_account).and_return(account)
          post "create", params: { pseudonym_session: { unique_id: "jt@instructure.com", password: "qwertyuiop" } }
          expect(response).to redirect_to(dashboard_url(login_success: 1))
          expect(assigns[:pseudonym_session].record).to eq @pseudonym
        end
      end
    end
  end

  context "merging" do
    it "redirects back to merge users" do
      communication_channel(@user, { username: "jt+1@instructure.com" })
      session[:confirm] = @cc.confirmation_code
      session[:expected_user_id] = @user.id
      post "create", params: { pseudonym_session: { unique_id: "jtfrd@instructure.com", password: "qwertyuiop" } }
      expect(response).to redirect_to(registration_confirmation_url(@cc.confirmation_code,
                                                                    login_success: 1,
                                                                    enrollment: nil,
                                                                    confirm: 1))
    end
  end

  context "otp" do
    it "does not ask for verification of unenrolled, optional user" do
      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!
      user_with_pseudonym(active_all: 1, password: "qwertyuiop")

      post :create, params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to dashboard_url(login_success: 1)
    end

    it "does not ask for verification if mfa is required but disabled for the provider" do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!
      user_with_pseudonym(active_all: 1, password: "qwertyuiop")
      @user.otp_secret_key = ROTP::Base32.random
      @user.save!
      auth_provider = Account.default.canvas_authentication_provider
      @pseudonym.update(authentication_provider: auth_provider)
      auth_provider.skip_internal_mfa = true
      auth_provider.save!

      post :create, params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to dashboard_url(login_success: 1)
    end
  end

  context "otp login cookie" do
    before :once do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      user_with_pseudonym(active_all: 1, password: "qwertyuiop")
      @user.otp_secret_key = ROTP::Base32.random
      @user.save!
    end

    before do
      allow_any_instance_of(ActionController::TestRequest).to receive(:remote_ip).and_return("127.0.0.1")
    end

    it "skips otp verification for a valid cookie" do
      cookies["canvas_otp_remember_me"] = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, "127.0.0.1")
      post "create", params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to dashboard_url(login_success: 1)
    end

    it "ignores a bogus cookie" do
      cookies["canvas_otp_remember_me"] = "bogus"
      post "create", params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to(otp_login_url)
    end

    it "ignores an expired cookie" do
      cookies["canvas_otp_remember_me"] = @user.otp_secret_key_remember_me_cookie(6.months.ago, nil, "127.0.0.1")
      post "create", params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to(otp_login_url)
    end

    it "ignores a cookie from an old secret_key" do
      cookies["canvas_otp_remember_me"] = @user.otp_secret_key_remember_me_cookie(6.months.ago, nil, "127.0.0.1")

      @user.otp_secret_key = ROTP::Base32.random
      @user.save!

      post "create", params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to(otp_login_url)
    end

    it "ignores a cookie for a different IP" do
      cookies["canvas_otp_remember_me"] = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, "127.0.0.2")
      post "create", params: { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } }
      expect(response).to redirect_to(otp_login_url)
    end
  end

  context "oauth" do
    before :once do
      user_with_pseudonym(active_all: 1, password: "qwertyuiop")
    end

    before do
      redis = double("Redis")
      allow(redis).to receive_messages(setex: nil, hget: nil, hmget: nil, del: nil, pipelined: nil)
      allow(Canvas::Security::LoginRegistry).to receive_messages(redis:)
    end

    let_once(:key) { DeveloperKey.create! redirect_uri: "https://example.com" }
    let(:params) { { pseudonym_session: { unique_id: @pseudonym.unique_id, password: "qwertyuiop" } } }

    it "redirects to the confirm url if the user has no token" do
      provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params:, session: { oauth2: provider.session_hash }
      expect(response).to redirect_to(oauth2_auth_confirm_url)
    end

    it "redirects to the redirect uri if the user already has remember-me token" do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil)
      provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, ["/auth/userinfo"], nil)

      post :create, params:, session: { oauth2: provider.session_hash }
      expect(response).to be_redirect
      expect(response.location).to match(%r{https://example.com})
    end

    it "redirects to the redirect uri with the provided state" do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil)
      provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, ["/auth/userinfo"], nil)

      post :create, params:, session: { oauth2: provider.session_hash.merge(state: "supersekrit") }
      expect(response).to be_redirect
      expect(response.location).to match(%r{https://example.com})
      expect(response.location).to match(/state=supersekrit/)
    end

    it "does not reuse userinfo tokens for other scopes" do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil)
      provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params:, session: { oauth2: provider.session_hash }
      expect(response).to redirect_to(oauth2_auth_confirm_url)
    end

    it "redirects to the redirect uri if the developer key is trusted" do
      key.trusted = true
      key.save!
      provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params:, session: { oauth2: provider.session_hash }
      expect(response).to be_redirect
      expect(response.location).to match(%r{https://example.com})
    end
  end
end
