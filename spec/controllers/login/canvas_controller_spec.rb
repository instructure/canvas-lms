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

require_relative '../../sharding_spec_helper'
require 'rotp'

describe Login::CanvasController do
  before :once do
    user_with_pseudonym(:username => 'jtfrd@instructure.com', :active_all => 1, :password => 'qwertyuiop')
  end

  describe 'mobile layout decision' do
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
        request.env['HTTP_USER_AGENT'] = agent
        yield
        expect(response).to render_template(:mobile_login)
      end
    end

    it "should render normal layout if not iphone/ipod" do
      get 'new'
      expect(response).to render_template(:new)
    end

    it "should render special iPhone/iPod layout if coming from one of those" do
      confirm_mobile_layout { get 'new' }
    end

    it "should render special iPhone/iPod layout if coming from one of those and it's the wrong password'" do
      confirm_mobile_layout { post 'create' }
    end

  end

  it "should show sso buttons on load" do
    aac = Account.default.authentication_providers.create!(auth_type: 'facebook')
    allow(Canvas::Plugin.find(:facebook)).to receive(:settings).and_return({})
    get 'new'
    expect(assigns[:aacs_with_buttons]).to eq [aac]
  end

  it "should still show sso buttons on login error" do
    aac = Account.default.authentication_providers.create!(auth_type: 'facebook')
    allow(Canvas::Plugin.find(:facebook)).to receive(:settings).and_return({})
    post 'create'
    expect(assigns[:aacs_with_buttons]).to eq [aac]
  end

  it "should re-render if no user" do
    post 'create'
    assert_status(400)
    expect(response).to render_template(:new)
  end

  it "should re-render if incorrect password" do
    post 'create', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'dvorak'}}
    assert_status(400)
    expect(response).to render_template(:new)
  end

  it "should re-render if no password given" do
    post 'create', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => ''}}
    assert_status(400)
    expect(response).to render_template(:new)
    expect(flash[:error]).to match(/no password/i)
  end

  it "password auth should work" do
    session[:sentinel] = true
    post 'create', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwertyuiop'}}
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
    # session reset
    expect(session[:sentinel]).to be_nil
  end

  it "password auth should work for an explicit Canvas pseudonym" do
    @pseudonym.update_attribute(:authentication_provider, Account.default.canvas_authentication_provider)
    post 'create', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwertyuiop'}}
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "password auth should work with extra whitespace around unique id " do
    post 'create', params: {:pseudonym_session => { :unique_id => ' jtfrd@instructure.com ', :password => 'qwertyuiop'}}
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "should re-render if authenticity token is invalid and referer is not trusted" do
    expect(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
    session[:sentinel] = true
    post 'create', params: {:pseudonym_session => { :unique_id => ' jtfrd@instructure.com ', :password => 'qwertyuiop' },
         :authenticity_token => '42'}
    assert_status(400)
    expect(session[:sentinel]).to eq true
    expect(response).to render_template(:new)
    expect(flash[:error]).to match(/invalid authenticity token/i)
  end

  it "should re-render if authenticity token is invalid and referer is trusted" do
    expect(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
    post 'create', params: {:pseudonym_session => { :unique_id => ' jtfrd@instructure.com ', :password => 'qwertyuiop' },
         :authenticity_token => '42'}
    assert_status(400)
    expect(response).to render_template(:new)
    expect(flash[:error]).to match(/invalid authenticity token/i)
  end

  it "should login if authenticity token is invalid and referer is trusted" do
    expect_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
    post 'create', params: {:pseudonym_session => { :unique_id => ' jtfrd@instructure.com ', :password => 'qwertyuiop' }}
    expect(response).to be_redirect
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(assigns[:pseudonym_session].record).to eq @pseudonym
  end

  it "rejects canvas auth if Canvas auth is disabled" do
    aac = Account.default.authentication_providers.create!(:auth_type => 'ldap')
    Account.default.canvas_authentication_provider.destroy
    get 'new'
    assert_status(404)
  end

  context "ldap" do
    it "should log in a user with a identifier_format" do
      user_with_pseudonym(:username => '12345', :active_all => 1)
      @pseudonym.update_attribute(:sis_user_id, '12345')
      aac = Account.default.authentication_providers.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once.
          with('username', 'password').
          and_return([{ 'uid' => ['12345'] }])
      Account.default.authentication_providers.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).never
      post 'create', params: {:pseudonym_session => { :unique_id => 'username', :password => 'password'}}
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    it "works for a pseudonym explicitly linked to LDAP" do
      user_with_pseudonym(:username => '12345', :active_all => 1)
      aac = Account.default.authentication_providers.create!(auth_type: 'ldap')
      expect_any_instantiation_of(@pseudonym).to receive(:valid_arbitrary_credentials?).and_return(true)
      @pseudonym.update_attribute(:authentication_provider, aac)
      post 'create', params: {:pseudonym_session => { :unique_id => '12345', :password => 'password'}}
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    it "ignores a pseudonym explicitly linked to a different LDAP" do
      user_with_pseudonym(:username => '12345', :active_all => 1)
      aac = Account.default.authentication_providers.create!(auth_type: 'ldap', identifier_format: 'uid')
      aac2 = Account.default.authentication_providers.create!(auth_type: 'ldap', identifier_format: 'uid')
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once.
        with('username', 'password').
        and_return([{ 'uid' => ['12345'] }])
      expect_any_instantiation_of(aac2).to receive(:ldap_bind_result).once.
        with('username', 'password').
        and_return(nil)
      @pseudonym.update_attribute(:authentication_provider, aac2)
      post 'create', params: {:pseudonym_session => { :unique_id => 'username', :password => 'password'}}
      assert_status(400)
    end

    it "should only query the LDAP server once, even with a differing identifier_format but a matching pseudonym" do
      user_with_pseudonym(:username => 'username', :active_all => 1)
      aac = Account.default.authentication_providers.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      expect_any_instantiation_of(aac).to receive(:ldap_bind_result).once.with('username', 'password').and_return(nil)
      post 'create', params: {:pseudonym_session => { :unique_id => 'username', :password => 'password'}}
      assert_status(400)
      expect(response).to render_template(:new)
    end

    it "doesn't query the server at all if the enabled features don't require it, and there is no matching login" do
      ap = Account.default.authentication_providers.create!(auth_type: 'ldap')
      expect_any_instantiation_of(ap).to receive(:ldap_bind_result).never
      post 'create', params: {:pseudonym_session => { :unique_id => 'username', :password => 'password'}}
      assert_status(400)
      expect(response).to render_template(:new)
    end

    it "provisions automatically when enabled" do
      ap = Account.default.authentication_providers.create!(auth_type: 'ldap', jit_provisioning: true)
      expect_any_instantiation_of(ap).to receive(:ldap_bind_result).once.
          with('username', 'password').
          and_return([{ 'uid' => ['12345'] }])
      unique_id = 'username'
      expect(Account.default.pseudonyms.active.by_unique_id(unique_id)).to_not be_exists

      post 'create', params: {:pseudonym_session => { :unique_id => 'username', :password => 'password'}}
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url(:login_success => 1))

      p = Account.default.pseudonyms.active.by_unique_id(unique_id).first!
      expect(p.authentication_provider).to eq ap
    end
  end

  context "trusted logins" do
    it "should login for a pseudonym from a different account" do
      account = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account.id])
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: account)
      post 'create', params: {:pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwertyuiop'}}
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      expect(flash[:notice]).to be_present
    end

    it "should login for a user with multiple identical pseudonyms" do
      account1 = Account.create!
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: account1)
      @pseudonym = @user.pseudonyms.create!(account: Account.site_admin,
                                            unique_id: 'jt@instructure.com',
                                            password: 'qwertyuiop',
                                            password_confirmation: 'qwertyuiop')
      post 'create', params: {:pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwertyuiop'}}
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      # it should have preferred the site admin pseudonym
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    it "should not login for multiple users with identical pseudonyms" do
      account1 = Account.create!
      account2 = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account1.id, account2.id])
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: account1)
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: account2)
      post 'create', params: {:pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwertyuiop'}}
      expect(response).not_to be_successful
      expect(response).to render_template(:new)
    end

    it "should login a site admin user with other identical pseudonyms" do
      account1 = Account.create!
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account1.id, Account.site_admin.id])
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: account1)
      user_with_pseudonym(username: 'jt@instructure.com',
                          active_all: 1,
                          password: 'qwertyuiop',
                          account: Account.site_admin)
      post 'create', params: {:pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwertyuiop'}}
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      # it should have preferred the site admin pseudonym
      expect(assigns[:pseudonym_session].record).to eq @pseudonym
    end

    context "sharding" do
      specs_require_sharding

      it "should login for a user from a different shard" do
        user_with_pseudonym(username: 'jt@instructure.com',
                            active_all: 1,
                            password: 'qwertyuiop',
                            account: Account.site_admin)
        @shard1.activate do
          account = Account.create!
          allow(HostUrl).to receive(:default_domain_root_account).and_return(account)
          post 'create', params: {:pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwertyuiop' }}
          expect(response).to redirect_to(dashboard_url(:login_success => 1))
          expect(assigns[:pseudonym_session].record).to eq @pseudonym
        end
      end
    end
  end

  context "merging" do
    it "should redirect back to merge users" do
      @cc = @user.communication_channels.create!(:path => 'jt+1@instructure.com')
      session[:confirm] = @cc.confirmation_code
      session[:expected_user_id] = @user.id
      post 'create', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwertyuiop' }}
      expect(response).to redirect_to(registration_confirmation_url(@cc.confirmation_code,
                                                                    login_success: 1,
                                                                    enrollment: nil,
                                                                    confirm: 1))
    end
  end

  context "otp" do
    it "should not ask for verification of unenrolled, optional user" do
      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!
      user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')

      post :create, params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to dashboard_url(:login_success => 1)
    end
  end

  context "otp login cookie" do
    before :once do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.save!
    end

    before :each do
      allow_any_instance_of(ActionController::TestRequest).to receive(:remote_ip).and_return('myip')
    end

    it "should skip otp verification for a valid cookie" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, 'myip')
      post 'create', params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to dashboard_url(:login_success => 1)
    end

    it "should ignore a bogus cookie" do
      cookies['canvas_otp_remember_me'] = 'bogus'
      post 'create', params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to(otp_login_url)
    end

    it "should ignore an expired cookie" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(6.months.ago, nil, 'myip')
      post 'create', params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to(otp_login_url)
    end

    it "should ignore a cookie from an old secret_key" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(6.months.ago, nil, 'myip')

      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.save!

      post 'create', params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to(otp_login_url)
    end

    it "should ignore a cookie for a different IP" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, 'otherip')
      post 'create', params: {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }}
      expect(response).to redirect_to(otp_login_url)
    end
  end

  context "oauth" do
    before :once do
      user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
    end

    before :each do
      redis = double('Redis')
      allow(redis).to receive(:setex)
      allow(redis).to receive(:hmget)
      allow(redis).to receive(:del)
      allow(Canvas).to receive_messages(:redis => redis)
    end

    let_once(:key) { DeveloperKey.create! :redirect_uri => 'https://example.com' }
    let(:params) { {:pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' } } }

    it 'should redirect to the confirm url if the user has no token' do
      provider = Canvas::Oauth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params: params, session: {:oauth2 => provider.session_hash}
      expect(response).to redirect_to(oauth2_auth_confirm_url)
    end

    it 'should redirect to the redirect uri if the user already has remember-me token' do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ['/auth/userinfo'], purpose: nil)
      provider = Canvas::Oauth::Provider.new(key.id, key.redirect_uri, ['/auth/userinfo'], nil)

      post :create, params: params, session: {:oauth2 => provider.session_hash}
      expect(response).to be_redirect
      expect(response.location).to match(/https:\/\/example.com/)
    end

    it 'should redirect to the redirect uri with the provided state' do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ['/auth/userinfo'], purpose: nil)
      provider = Canvas::Oauth::Provider.new(key.id, key.redirect_uri, ['/auth/userinfo'], nil)

      post :create, params: params, session: {:oauth2 => provider.session_hash.merge(state: "supersekrit")}
      expect(response).to be_redirect
      expect(response.location).to match(/https:\/\/example.com/)
      expect(response.location).to match(/state=supersekrit/)
    end

    it 'should not reuse userinfo tokens for other scopes' do
      @user.access_tokens.create!(developer_key: key, remember_access: true, scopes: ['/auth/userinfo'], purpose: nil)
      provider = Canvas::Oauth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params: params, session: {:oauth2 => provider.session_hash}
      expect(response).to redirect_to(oauth2_auth_confirm_url)
    end

    it 'should redirect to the redirect uri if the developer key is trusted' do
      key.trusted = true
      key.save!
      provider = Canvas::Oauth::Provider.new(key.id, key.redirect_uri, [], nil)

      post :create, params: params, session: {:oauth2 => provider.session_hash}
      expect(response).to be_redirect
      expect(response.location).to match(/https:\/\/example.com/)
    end
  end
end
