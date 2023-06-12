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

require_relative "../../spec_helper"

describe Login::OAuth2Controller do
  let(:aac) { Account.default.authentication_providers.create!(auth_type: "facebook") }

  before do
    aac
    allow(Canvas::Plugin.find(:facebook)).to receive(:settings).and_return({})
  end

  describe "#new" do
    it "redirects to the provider" do
      get :new, params: { auth_type: "facebook" }
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://www.facebook.com/dialog/oauth\?})
      expect(session[:oauth2_nonce]).to_not be_blank
    end
  end

  describe "#create" do
    it "checks the OAuth2 CSRF token" do
      session[:oauth2_nonce] = "bob"
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "different")
      get :create, params: { state: jwt }
      # it could be a 422, or 0 if error handling isn't enabled properly in specs
      expect(response).to_not be_successful
      expect(response).to_not be_redirect
    end

    it "rejects logins that take more than 10 minutes" do
      get :new, params: { auth_type: "facebook" }
      expect(response).to be_redirect
      state = CGI.parse(URI.parse(response.location).query)["state"].first
      expect(state).to_not be_nil

      expect_any_instantiation_of(aac).not_to receive(:get_token)
      Timecop.travel(15.minutes) do
        get :create, params: { state: }
        expect(response).to redirect_to(login_url)
        expect(flash[:delegated_message]).to eq "It took too long to login. Please try again"
      end
    end

    it "does not destroy existing sessions if it's a bogus request" do
      session[:sentinel] = true

      get :create, params: { state: "" }
      expect(response).not_to be_successful
      expect(session[:sentinel]).to be true
    end

    it "works" do
      session[:oauth2_nonce] = "bob"
      expect_any_instantiation_of(aac).to receive(:get_token).and_return("token")
      expect_any_instantiation_of(aac).to receive(:unique_id).with("token").and_return("user")
      expect_any_instantiation_of(aac).to receive(:provider_attributes).with("token").and_return({})
      user_with_pseudonym(username: "user", active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!

      session[:sentinel] = true
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")
      get :create, params: { state: jwt }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      # ensure the session was reset
      expect(session[:sentinel]).to be_nil
    end

    it "doesn't allow deleted users to login" do
      session[:oauth2_nonce] = "bob"
      expect_any_instantiation_of(aac).to receive(:get_token).and_return("token")
      expect_any_instantiation_of(aac).to receive(:unique_id).with("token").and_return("user")
      expect_any_instantiation_of(aac).to receive(:provider_attributes).with("token").and_return({})
      user_with_pseudonym(username: "user", active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!
      @user.update!(workflow_state: "deleted")

      session[:sentinel] = true
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")
      get :create, params: { state: jwt }
      expect(response).to redirect_to(login_url)
    end

    it "redirects to login if no user found" do
      expect_any_instantiation_of(aac).to receive(:get_token).and_return("token")
      expect_any_instantiation_of(aac).to receive(:unique_id).with("token").and_return("user")
      expect_any_instantiation_of(aac).to receive(:provider_attributes).with("token").and_return({})

      session[:oauth2_nonce] = "bob"
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")

      get :create, params: { state: jwt }
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to_not be_blank
    end

    it "redirects to login if no user information returned" do
      expect_any_instantiation_of(aac).to receive(:get_token).and_return("token")
      expect_any_instantiation_of(aac).to receive(:unique_id).with("token").and_return(nil)
      expect_any_instantiation_of(aac).to receive(:provider_attributes).with("token").and_return({})

      session[:oauth2_nonce] = "bob"
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")

      get :create, params: { state: jwt }
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to_not be_blank
      expect(flash[:delegated_message]).to match(/no unique ID/)
    end

    it "(safely) displays an error message from the server" do
      get :create, params: { error_description: "failed<script></script>" }
      expect(response).to redirect_to(login_url)
      expect(flash[:delegated_message]).to eq "failed"
    end

    it "provisions automatically when enabled" do
      aac.update_attribute(:jit_provisioning, true)
      expect_any_instantiation_of(aac).to receive(:get_token).and_return("token")
      expect_any_instantiation_of(aac).to receive(:unique_id).with("token").and_return("user")
      expect_any_instantiation_of(aac).to receive(:provider_attributes).with("token").and_return({})

      session[:oauth2_nonce] = "bob"
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")

      expect(Account.default.pseudonyms.active.by_unique_id("user")).to_not be_exists
      get :create, params: { state: jwt }
      expect(response).to redirect_to(dashboard_url(login_success: 1))
      p = Account.default.pseudonyms.active.by_unique_id("user").first!
      expect(p.authentication_provider).to eq aac
    end

    it "redirects to login any time an expired token is noticed" do
      session[:oauth2_nonce] = "bob"
      expect_any_instantiation_of(aac).to receive(:get_token).and_raise(Canvas::Security::TokenExpired)
      user_with_pseudonym(username: "user", active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!
      session[:sentinel] = true
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "bob")
      get :create, params: { state: jwt }
      expect(response).to redirect_to(login_url)
    end

    it "redirects to login any time an external timeout is noticed" do
      session[:oauth2_nonce] = "fred"
      expect_any_instantiation_of(aac).to receive(:get_token).and_raise(Canvas::TimeoutCutoff)
      user_with_pseudonym(username: "user", active_all: 1)
      @pseudonym.authentication_provider = aac
      @pseudonym.save!
      session[:sentinel] = true
      jwt = Canvas::Security.create_jwt(aac_id: aac.global_id, nonce: "fred")
      get :create, params: { state: jwt }
      expect(response).to redirect_to(login_url)
    end
  end
end
