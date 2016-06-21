#
# Copyright (C) 2015 Instructure, Inc.
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

require_relative '../../spec_helper'

describe Login::Oauth2Controller do
  let(:aac) { Account.default.authentication_providers.create!(auth_type: 'facebook') }
  before do
    aac
    Canvas::Plugin.find(:facebook).stubs(:settings).returns({})

    # replace on just this instance. this allows the tests to look directly at
    # response.location independent of any implementation plugins may add for
    # this method.
    def @controller.delegated_auth_redirect_uri(uri)
      uri
    end
  end

  describe "#new" do
    it "redirects to the provider" do
      get :new, auth_type: 'facebook'
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://www.facebook.com/dialog/oauth\?})
      expect(session[:oauth2_nonce]).to_not be_blank
    end

    it "wraps redirect in delegated_auth_redirect_uri" do
      # needs the `returns` or it returns nil and causes a 500
      @controller.expects(:delegated_auth_redirect_uri).once.returns('/')
      get :new, auth_type: 'facebook'
      expect(response).to be_redirect
    end
  end

  describe "#create" do
    it "checks the OAuth2 CSRF token" do
      session[:oauth2_nonce] = 'bob'
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'different')
      get :create, state: jwt
      # it could be a 422, or 0 if error handling isn't enabled properly in specs
      expect(response).to_not be_success
      expect(response).to_not be_redirect
    end

    it "rejects logins that take more than 10 minutes" do
      get :new, auth_type: 'facebook'
      expect(response).to be_redirect
      state = CGI.parse(URI.parse(response.location).query)['state'].first
      expect(state).to_not be_nil

      aac.any_instantiation.expects(:get_token).never
      Timecop.travel(15.minutes) do
        get :create, state: state
        expect(response).to redirect_to(login_url)
        expect(flash[:delegated_message]).to eq "It took too long to login. Please try again"
      end
    end

    it "does not destroy existing sessions if it's a bogus request" do
      session[:sentinel] = true

      get :create, state: ''
      expect(response).not_to be_success
      expect(session[:sentinel]).to eq true
    end

    it "works" do
      session[:oauth2_nonce] = 'bob'
      aac.any_instantiation.expects(:get_token).returns('token')
      aac.any_instantiation.expects(:unique_id).with('token').returns('user')
      user_with_pseudonym(username: 'user', active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!

      session[:sentinel] = true
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'bob')
      get :create, state: jwt
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      # ensure the session was reset
      expect(session[:sentinel]).to be_nil
    end

    it "redirects to login if no user found" do
      aac.any_instantiation.expects(:get_token).returns('token')
      aac.any_instantiation.expects(:unique_id).with('token').returns('user')

      session[:oauth2_nonce] = 'bob'
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'bob')

      get :create, state: jwt
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to_not be_blank
    end

    it "redirects to login if no user information returned" do
      aac.any_instantiation.expects(:get_token).returns('token')
      aac.any_instantiation.expects(:unique_id).with('token').returns(nil)

      session[:oauth2_nonce] = 'bob'
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'bob')

      get :create, state: jwt
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to_not be_blank
      expect(flash[:delegated_message]).to match(/no unique ID/)
    end

    it "(safely) displays an error message from the server" do
      get :create, error_description: 'failed<script></script>'
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to eq "failed"
    end

    it "provisions automatically when enabled" do
      aac.update_attribute(:jit_provisioning, true)
      aac.any_instantiation.expects(:get_token).returns('token')
      aac.any_instantiation.expects(:unique_id).with('token').returns('user')

      session[:oauth2_nonce] = 'bob'
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'bob')

      expect(Account.default.pseudonyms.active.by_unique_id('user')).to_not be_exists
      get :create, state: jwt
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      p = Account.default.pseudonyms.active.by_unique_id('user').first!
      expect(p.authentication_provider).to eq aac
    end
  end
end
