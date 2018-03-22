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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Oauth2ProviderController do
  describe 'GET auth' do
    let_once(:key) { DeveloperKey.create! :redirect_uri => 'https://example.com' }

    it 'renders a 401 when there is no client_id' do
      get :auth
      assert_status(401)
      expect(response.body).to match /unknown client/
      expect(response['WWW-Authenticate']).to_not be_blank
    end

    it 'renders 400 on a bad redirect_uri' do
      get :auth, params: {:client_id => key.id}
      assert_status(400)
      expect(response.body).to match /redirect_uri does not match/
    end

    it 'redirects back with an error for invalid response_type' do
      get :auth,
          params: {client_id: key.id,
          redirect_uri: 'https://example.com/oauth/callback'}
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://example.com/oauth/callback\?error=unsupported_response_type})
    end

    it 'redirects to the login url' do
      get :auth,
          params: {client_id: key.id,
          redirect_uri: Canvas::Oauth::Provider::OAUTH2_OOB_URI,
          response_type: 'code'}
      expect(response).to redirect_to(login_url)
    end

    it 'passes on canvas_login if provided' do
      get :auth, params: {client_id: key.id,
          redirect_uri: Canvas::Oauth::Provider::OAUTH2_OOB_URI,
          canvas_login: 1,
          response_type: 'code'}
      expect(response).to redirect_to(login_url(:canvas_login => 1))
    end

    it 'should pass pseudonym_session[unique_id] to login to populate username textbox' do
      get :auth, params: {:client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI,
          "unique_id"=>"test", force_login: true, response_type: 'code'}
      expect(response).to redirect_to(login_url+'?force_login=true&pseudonym_session%5Bunique_id%5D=test')
    end


    context 'with a user logged in' do
      before :once do
        user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
      end

      before :each do
        user_session(@user)

        redis = double('Redis')
        allow(redis).to receive(:setex)
        allow(Canvas).to receive_messages(:redis => redis)
      end

      it 'should redirect to the confirm url if the user has no token' do
        get :auth,
            params: {client_id: key.id,
            redirect_uri: Canvas::Oauth::Provider::OAUTH2_OOB_URI,
            response_type: 'code'}
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it 'redirects to login_url with ?force_login=1' do
        get :auth,
            params: {client_id: key.id,
            redirect_uri: Canvas::Oauth::Provider::OAUTH2_OOB_URI,
            response_type: 'code',
            force_login: 1}
        expect(response).to redirect_to(login_url(:force_login => 1))
      end

      it 'should redirect to login_url when oauth2 session is nil' do
        get :confirm
        expect(flash[:error]).to eq "Must submit new OAuth2 request"
        expect(response).to redirect_to(login_url)
      end

      it 'should redirect to the redirect uri if the user already has remember-me token' do
        @user.access_tokens.create!({:developer_key => key, :remember_access => true, :scopes => ['/auth/userinfo'], :purpose => nil})
        get :auth,
            params: {client_id: key.id,
            redirect_uri: 'https://example.com',
            response_type: 'code',
            scope: '/auth/userinfo'}
        expect(response).to be_redirect
        expect(response.location).to match(/https:\/\/example.com/)
      end

      it 'it accepts the deprecated name of scopes for scope param' do
        @user.access_tokens.create!({:developer_key => key, :remember_access => true, :scopes => ['/auth/userinfo'], :purpose => nil})
        get :auth,
            params: {client_id: key.id,
            redirect_uri: 'https://example.com',
            response_type: 'code',
            scope: '/auth/userinfo'}
        expect(response).to be_redirect
        expect(response.location).to match(/https:\/\/example.com/)
      end

      it 'should not reuse userinfo tokens for other scopes' do
        @user.access_tokens.create!({:developer_key => key, :remember_access => true, :scopes => ['/auth/userinfo'], :purpose => nil})
        get :auth, params: {client_id: key.id,
            redirect_uri: 'https://example.com',
            response_type: 'code'}
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it 'should redirect to the redirect uri if the developer key is trusted' do
        key.trusted = true
        key.save!
        get :auth, params: {client_id: key.id,
            redirect_uri: 'https://example.com',
            response_type: 'code',
            scope: '/auth/userinfo'}
        expect(response).to be_redirect
        expect(response.location).to match(/https:\/\/example.com/)
      end

      context 'masquerading' do
        before :once do
          @real_user = @user
          @target_user = user_with_pseudonym(active_all: true, name: "Target")
          Account.default.account_users.create!(user: @real_user)
        end

        before :each do
          session[:become_user_id] = @target_user.id
        end

        it 'should generate a code for the real user if the developer key is trusted' do
          key.trusted = true
          key.save!
          expect(Canvas::Oauth::Token).to receive(:generate_code_for).with(@real_user.global_id, anything, anything)
          get :auth, params: {client_id: key.id,
              redirect_uri: 'https://example.com',
              response_type: 'code',
              scope: '/auth/userinfo'}
        end

        it 'should redirect to login_url with error flash when developer key is not trusted' do
          get :auth, params: {client_id: key.id,
              redirect_uri: 'https://example.com',
              response_type: 'code',
              scope: '/auth/userinfo'}
          expect(flash[:error]).to match(/can only be authorized for the currently logged-in user/)
          expect(response).to redirect_to(login_url(force_login: 1))
        end
      end
    end
  end

  describe 'POST token' do
    let_once(:key) { DeveloperKey.create! }
    let_once(:user) { User.create! }
    let(:valid_code) {"thecode"}
    let(:valid_code_redis_key) {"#{Canvas::Oauth::Token::REDIS_PREFIX}#{valid_code}"}
    let(:redis) do
      redis = double('Redis')
      allow(redis).to receive(:get)
      allow(redis).to receive(:get).with(valid_code_redis_key).and_return(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      allow(redis).to receive(:del).with(valid_code_redis_key).and_return(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      redis
    end

    it 'renders a 401 if theres no client_id' do
      post :token
      assert_status(401)
      expect(response.body).to match /unknown client/
    end

    it 'renders a 401 if the secret is invalid' do
      post :token, params: {:client_id => key.id, :client_secret => key.api_key + "123"}
      assert_status(401)
      expect(response.body).to match /invalid client/
    end

    it 'renders a 400 if a code is not provided for an authorization_code grant' do
      expected_error = Canvas::Oauth::RequestError::ERROR_MAP[:authorization_code_not_supplied]

      post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: 'authorization_code'}

      assert_status(400)

      response_hash = JSON.parse(response.body)
      expect(response_hash['error']).to eq expected_error[:error].to_s
      expect(response_hash['error_description']).to eq expected_error[:error_description]
    end

    it 'renders a 400 if the provided code does not match a token' do
      allow(Canvas).to receive_messages(:redis => redis)
      post :token, params: {:client_id => key.id, :client_secret => key.api_key, :code => "NotALegitCode"}
      assert_status(400)
      expect(response.body).to match /authorization_code not found/
    end

    it 'outputs the token json if everything checks out' do
      expect(redis).to receive(:del).with(valid_code_redis_key).at_least(:once)
      allow(Canvas).to receive_messages(:redis => redis)
      post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: 'authorization_code', code: valid_code}
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.keys.sort).to match_array(['access_token',  'refresh_token', 'user', 'expires_in', 'token_type'])
      expect(json['token_type']).to eq 'Bearer'
    end

    it 'renders a 400 if the provided code is for the wrong key' do
      allow(Canvas).to receive_messages(:redis => redis)
      key2 = DeveloperKey.create!
      post :token, params: {client_id: key2.id.to_s, client_secret: key2.api_key, grant_type: 'authorization_code', code: valid_code}
      assert_status(400)
      expect(response.body).to match(/incorrect client/)
    end

    it 'default grant_type to authorization_code if none is supplied and code is present' do
      expect(redis).to receive(:del).with(valid_code_redis_key).at_least(:once)
      allow(Canvas).to receive_messages(:redis => redis)
      post :token, params: {:client_id => key.id, :client_secret => key.api_key, :code => valid_code}
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.keys.sort).to match_array ['access_token', 'refresh_token', 'user', 'expires_in', 'token_type']
    end

    it 'deletes existing tokens for the same key when replace_tokens=1' do
      old_token = user.access_tokens.create! :developer_key => key
      allow(Canvas).to receive_messages(:redis => redis)
      post :token, params: {:client_id => key.id, :client_secret => key.api_key, :code => valid_code, :replace_tokens => '1'}
      expect(response).to be_success
      expect(AccessToken.not_deleted.exists?(old_token.id)).to be(false)
    end

    it 'does not delete existing tokens without replace_tokens' do
      old_token = user.access_tokens.create! :developer_key => key
      allow(Canvas).to receive_messages(:redis => redis)
      post :token, params: {:client_id => key.id, :client_secret => key.api_key, :code => valid_code}
      expect(response).to be_success
      expect(AccessToken.not_deleted.exists?(old_token.id)).to be(true)
    end

    context 'grant_type refresh_token' do
      it 'must specify grant_type' do
        post :token, params: {client_id: key.id, client_secret: key.api_key, refresh_token: "SAFASDFASDF"}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to eq "unsupported_grant_type"
      end

      it 'should not generate a new access_token with an invalid refresh_token' do
        old_token = user.access_tokens.create! :developer_key => key
        refresh_token = old_token.plaintext_refresh_token

        post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: "refresh_token", refresh_token: refresh_token + "ASDAS"}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to eq "invalid_request"
        expect(json['error_description']).to eq "refresh_token not found"
      end

      it 'should generate a new access_token' do
        old_token = user.access_tokens.create! :developer_key => key
        refresh_token = old_token.plaintext_refresh_token
        access_token = old_token.full_token

        post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: "refresh_token", refresh_token: refresh_token}
        json = JSON.parse(response.body)
        expect(json['access_token']).to_not eq access_token
      end

      it 'errors with a mismatched client id' do
        old_token = user.access_tokens.create! :developer_key => key
        refresh_token = old_token.plaintext_refresh_token
        key2 = DeveloperKey.create!

        post :token, params: {client_id: key2.id, client_secret: key2.api_key, grant_type: "refresh_token", refresh_token: refresh_token}
        assert_status(400)
        expect(response.body).to match(/incorrect client/)
      end

      it 'should be able to regenerate access_token multiple times' do
        old_token = user.access_tokens.create! :developer_key => key
        refresh_token = old_token.plaintext_refresh_token
        access_token = old_token.full_token

        post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: "refresh_token", refresh_token: refresh_token}
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json['access_token']).to_not eq access_token

        access_token = json['access_token']
        post :token, params: {client_id: key.id, client_secret: key.api_key, grant_type: "refresh_token", refresh_token: refresh_token}
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json['access_token']).to_not eq access_token
      end
    end

    context 'unsupported grant_type' do
      it 'returns a 400' do
        post :token, params: {:client_id => key.id, :client_secret => key.api_key, :grant_type => "client_credentials"}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to eq "unsupported_grant_type"
      end
    end
  end

  describe 'POST accept' do
    let_once(:user) { User.create! }
    let_once(:key) { DeveloperKey.create! }
    let(:session_hash) { { :oauth2 => { :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI  } } }
    let(:oauth_accept) { post :accept, session: session_hash }

    before { user_session user }

    it 'uses the global id of the user for generating the code' do
      expect(Canvas::Oauth::Token).to receive(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => nil, :purpose => nil}).and_return('code')
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(:code => 'code'))
    end

    it 'saves the requested scopes with the code' do
      scopes = 'userinfo'
      session_hash[:oauth2][:scopes] = scopes
      expect(Canvas::Oauth::Token).to receive(:generate_code_for).with(user.global_id, key.id, {:scopes => scopes, :remember_access => nil, :purpose => nil}).and_return('code')
      oauth_accept
    end

    it 'remembers the users access preference with the code' do
      expect(Canvas::Oauth::Token).to receive(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => '1', :purpose => nil}).and_return('code')
      post :accept, params: {:remember_access => '1'}, session: session_hash
    end

    it 'removes oauth session info after code generation' do
      allow(Canvas::Oauth::Token).to receive_messages(:generate_code_for => 'code')
      oauth_accept
      expect(controller.session[:oauth2]).to be_nil
    end

    it 'forwards the oauth state if it was provided' do
      session_hash[:oauth2][:state] = '1234567890'
      allow(Canvas::Oauth::Token).to receive_messages(:generate_code_for => 'code')
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(:code => 'code', :state => '1234567890'))
    end

  end
end
