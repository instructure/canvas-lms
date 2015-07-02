#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

    it 'renders a 400 when there is no client_id' do
      get :auth
      assert_status(400)
      expect(response.body).to match /invalid client_id/
    end

    it 'renders 400 on a bad redirect_uri' do
      get :auth, :client_id => key.id
      assert_status(400)
      expect(response.body).to match /invalid redirect_uri/
    end

    it 'redirects to the login url' do
      get :auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI
      expect(response).to redirect_to(login_url)
    end

    it 'passes on canvas_login if provided' do
      get :auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI, :canvas_login => 1
      expect(response).to redirect_to(login_url(:canvas_login => 1))
    end

    context 'with a user logged in' do
      before :once do
        user_with_pseudonym(:active_all => 1, :password => 'qwerty')
      end

      before :each do
        user_session(@user)

        redis = stub('Redis')
        redis.stubs(:setex)
        Canvas.stubs(:redis => redis)
      end

      it 'should redirect to the confirm url if the user has no token' do
        get :auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it 'redirects to login_url with ?force_login=1' do
        get :auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI, :force_login => 1
        expect(response).to redirect_to(login_url(:force_login => 1))
      end

      it 'should redirect to login_url when oauth2 session is nil' do
        get :confirm
        expect(flash[:error]).to eq "Must submit new OAuth2 request"
        expect(response).to redirect_to(login_url)
      end

      it 'should redirect to the redirect uri if the user already has remember-me token' do
        @user.access_tokens.create!({:developer_key => key, :remember_access => true, :scopes => ['/auth/userinfo'], :purpose => nil})
        get :auth, :client_id => key.id, :redirect_uri => 'https://example.com', :scopes => '/auth/userinfo'
        expect(response).to be_redirect
        expect(response.location).to match(/https:\/\/example.com/)
      end

      it 'should not reuse userinfo tokens for other scopes' do
        @user.access_tokens.create!({:developer_key => key, :remember_access => true, :scopes => ['/auth/userinfo'], :purpose => nil})
        get :auth, :client_id => key.id, :redirect_uri => 'https://example.com'
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it 'should redirect to the redirect uri if the developer key is trusted' do
        key.trusted = true
        key.save!
        get :auth, :client_id => key.id, :redirect_uri => 'https://example.com', :scopes => '/auth/userinfo'
        expect(response).to be_redirect
        expect(response.location).to match(/https:\/\/example.com/)
      end
    end
  end

  describe 'GET token' do
    let_once(:key) { DeveloperKey.create! }
    let_once(:user) { User.create! }
    let(:valid_code) {"thecode"}
    let(:valid_code_redis_key) {"#{Canvas::Oauth::Token::REDIS_PREFIX}#{valid_code}"}
    let(:redis) do
      redis = stub('Redis')
      redis.stubs(:get)
      redis.stubs(:get).with(valid_code_redis_key).returns(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      redis.stubs(:del).with(valid_code_redis_key).returns(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      redis
    end

    it 'renders a 400 if theres no client_id' do
      get :token
      assert_status(400)
      expect(response.body).to match /invalid client_id/
    end

    it 'renders a 400 if the secret is invalid' do
      get :token, :client_id => key.id, :client_secret => key.api_key + "123"
      assert_status(400)
      expect(response.body).to match /invalid client_secret/
    end

    it 'renders a 400 if the provided code does not match a token' do
      Canvas.stubs(:redis => redis)
      get :token, :client_id => key.id, :client_secret => key.api_key, :code => "NotALegitCode"
      assert_status(400)
      expect(response.body).to match /invalid code/
    end

    it 'outputs the token json if everything checks out' do
      redis.expects(:del).with(valid_code_redis_key).at_least_once
      Canvas.stubs(:redis => redis)
      get :token, :client_id => key.id, :client_secret => key.api_key, :code => valid_code
      expect(response).to be_success
      expect(JSON.parse(response.body).keys.sort).to eq ['access_token', 'user']
    end

    it 'deletes existing tokens for the same key when replace_tokens=1' do
      old_token = user.access_tokens.create! :developer_key => key
      Canvas.stubs(:redis => redis)
      get :token, :client_id => key.id, :client_secret => key.api_key, :code => valid_code, :replace_tokens => '1'
      expect(response).to be_success
      expect(AccessToken.exists?(old_token.id)).to be(false)
    end

    it 'does not delete existing tokens without replace_tokens' do
      old_token = user.access_tokens.create! :developer_key => key
      Canvas.stubs(:redis => redis)
      get :token, :client_id => key.id, :client_secret => key.api_key, :code => valid_code
      expect(response).to be_success
      expect(AccessToken.exists?(old_token.id)).to be(true)
    end
  end

  describe 'POST accept' do
    let_once(:user) { User.create! }
    let_once(:key) { DeveloperKey.create! }
    let(:session_hash) { { :oauth2 => { :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI  } } }
    let(:oauth_accept) { post :accept, {}, session_hash }

    before { user_session user }

    it 'uses the global id of the user for generating the code' do
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => nil, :purpose => nil}).returns('code')
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(:code => 'code'))
    end

    it 'saves the requested scopes with the code' do
      scopes = 'userinfo'
      session_hash[:oauth2][:scopes] = scopes
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => scopes, :remember_access => nil, :purpose => nil}).returns('code')
      oauth_accept
    end

    it 'remembers the users access preference with the code' do
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => '1', :purpose => nil}).returns('code')
      post :accept, {:remember_access => '1'}, session_hash
    end

    it 'removes oauth session info after code generation' do
      Canvas::Oauth::Token.stubs(:generate_code_for => 'code')
      oauth_accept
      expect(controller.session[:oauth2]).to be_nil
    end

    it 'forwards the oauth state if it was provided' do
      session_hash[:oauth2][:state] = '1234567890'
      Canvas::Oauth::Token.stubs(:generate_code_for => 'code')
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(:code => 'code', :state => '1234567890'))
    end

  end
end
