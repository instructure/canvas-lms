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
  end

  describe "#new" do
    it "redirects to the provider" do
      get :new, auth_type: 'facebook'
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://www.facebook.com/dialog/oauth\?})
      expect(session[:oauth2_nonce]).to_not be_blank
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

    it "works" do
      session[:oauth2_nonce] = 'bob'
      aac.any_instantiation.expects(:get_token).returns('token')
      aac.any_instantiation.expects(:unique_id).with('token').returns('user')
      user_with_pseudonym(username: 'user', active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!

      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: 'bob')
      get :create, state: jwt
      expect(response).to redirect_to(dashboard_url(login_success: 1))
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
  end
end
