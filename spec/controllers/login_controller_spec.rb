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

require_relative "../apis/api_spec_helper"

describe LoginController do
  describe "#new" do
    it "redirects to dashboard if already logged in" do
      user_session(user_with_pseudonym(active: true))
      get "new"
      expect(response).to redirect_to(dashboard_url)
    end

    it "sets merge params correctly in the session" do
      user_with_pseudonym(active: true)
      @cc = @user.communication_channels.create!(path: "jt+1@instructure.com")
      get "new", params: { confirm: @cc.confirmation_code, expected_user_id: @user.id }
      expect(response).to be_redirect
      expect(session[:confirm]).to eq @cc.confirmation_code
      expect(session[:expected_user_id]).to eq @user.id
    end

    it "respects auth_discovery_url" do
      Account.default.auth_discovery_url = "https://google.com/"
      Account.default.save!

      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect(InstStatsd::Statsd).to receive(:distributed_increment)
        .with("auth.new.discovery_redirect.v2", tags: { auth_type: nil, target_auth_type: nil, domain: "test.host" })

      get "new"
      expect(response).to redirect_to("https://google.com/")
    end

    it "passes delegated message on to discovery url" do
      Account.default.auth_discovery_url = "https://google.com/"
      Account.default.save!

      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[:delegated_message] = "hi"
      allow(controller).to receive(:flash).and_return(flash_hash)
      get "new"
      expect(response).to redirect_to("https://google.com/?message=hi")
    end

    it "handles legacy canvas_login=1 param" do
      account_with_cas(account: Account.default)

      get "new", params: { canvas_login: "1" }
      expect(response).to redirect_to(canvas_login_url)
    end

    it "handles legacy SAML AAC-specific :id" do
      # it should ignore an auth_discovery_url
      Account.default.auth_discovery_url = "https://google.com/"
      Account.default.save!

      account_with_saml(account: Account.default)
      aac = Account.default.authentication_providers.first
      get "new", params: { id: aac }
      expect(response).to redirect_to(saml_login_url(aac))
    end

    it "redirects to Canvas auth by default" do
      get "new"
      expect(response).to redirect_to(canvas_login_url)
    end

    it "redirects to CAS if it's the default" do
      account_with_cas(account: Account.default)

      get "new"
      expect(response).to redirect_to(controller.url_for(controller: "login/cas", action: :new))
    end

    it "redirects to Facebook if it's the default" do
      Account.default.authentication_providers.create!(auth_type: "facebook")
      Account.default.authentication_providers.first.move_to_bottom

      get "new"
      expect(response).to redirect_to(facebook_login_url)
    end

    it "redirects based on authentication_provider param" do
      Account.default.authentication_providers.create!(auth_type: "facebook")
      account_with_cas(account: Account.default)

      get "new", params: { authentication_provider: "cas" }
      expect(response).to redirect_to(controller.url_for(controller: "login/cas", action: :new))
    end

    it "redirects based on authentication_provider id param" do
      ap2 = Account.default.authentication_providers.create!(auth_type: "cas")
      account_with_cas(account: Account.default)

      get "new", params: { authentication_provider: ap2.id }
      expect(response).to redirect_to(controller.url_for(controller: "login/cas", action: :new, id: ap2.id))
    end

    it "passes pseudonym_session[unique_id] to redirect to populate username textbox" do
      get "new", params: { "pseudonym_session" => { "unique_id" => "test" } }
      expect(response).to redirect_to(
        controller.url_for(controller: "login/canvas", action: :new) + "?login_hint=test"
      )
    end

    it "passes login_hint to redirect to populate username textbox" do
      get "new", params: { "login_hint" => "test" }
      expect(response).to redirect_to(
        controller.url_for(controller: "login/canvas", action: :new) + "?login_hint=test"
      )
    end

    it "passes pseudonym_session[unique_id] to redirect from current username" do
      user_with_pseudonym(username: "test2", active: 1)
      user_session(@user, @pseudonym)
      get "new", params: { "pseudonym_session" => { "unique_id" => "test" }, :force_login => 1 }
      expect(response).to redirect_to(
        controller.url_for(controller: "login/canvas", action: :new) + "?login_hint=test2"
      )
    end

    context "given an html request" do
      before { get :new, format: :html }

      it "response with an html content type" do
        expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html})
      end
    end

    context "given a pdf request" do
      before { get :new, format: :pdf }

      it "response with an html content type" do
        expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html})
      end
    end
  end

  describe "#session_token" do
    it "doesn't explode on a bad input url" do
      user_session(user_with_pseudonym(active: true))
      request.headers.merge!({ "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" })
      get "session_token", format: :json, params: { return_to: "not-a url" }
      expect(response.status.to_i).to eq(400)
    end

    describe "when user needs to accept terms of service" do
      it "returns a payload with requires_terms_acceptance of true" do
        user_session user_with_pseudonym(active: true)
        request.headers.merge!({ "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" })
        allow_any_instance_of(Account).to receive(:require_acceptance_of_terms?).and_return(true)

        get "session_token", format: :json
        expect(response.parsed_body["requires_terms_acceptance"]).to be(true)
      end
    end

    describe "when user does not need to accept terms of service" do
      it "returns a payload with requires_terms_acceptance of false" do
        user_session user_with_pseudonym(active: true)
        request.headers.merge!({ "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" })
        allow_any_instance_of(Account).to receive(:require_acceptance_of_terms?).and_return(false)

        get "session_token", format: :json
        expect(response.parsed_body["requires_terms_acceptance"]).to be(false)
      end
    end

    it "rejects javascript scheme" do
      user_session user_with_pseudonym(active: true)
      request.headers.merge!({ "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" })
      allow_any_instance_of(Account).to receive(:require_acceptance_of_terms?).and_return(false)

      get "session_token", format: :json, params: { return_to: "javascript://localhost/" }
      expect(response).to have_http_status :forbidden
    end
  end

  describe "#logout" do
    it "doesn't logout if the authenticity token is invalid" do
      skip("investigate cause for failures beginning 05/05/21 FOO-1950")
      enable_forgery_protection do
        delete "destroy"
        # it could be a 422, or 0 if error handling isn't enabled properly in specs
        expect(response).to_not be_successful
        expect(response).to_not be_redirect
      end
    end

    it "logs out" do
      delete "destroy"
      expect(response).to redirect_to(login_url)
    end

    it "follows SAML logout redirect to IdP" do
      account_with_saml(account: Account.default, saml_log_out_url: "https://www.google.com/")
      session[:login_aac] = Account.default.authentication_providers.first.id
      delete "destroy"
      expect(response).to have_http_status :found
      expect(response.location).to match(%r{^https://www.google.com/\?SAMLRequest=})
    end

    it "follows CAS logout redirect to CAS server" do
      account_with_cas(account: Account.default)
      session[:login_aac] = Account.default.authentication_providers.first.id
      delete "destroy"
      expect(response).to have_http_status :found
      expect(response.location).to match(%r{localhost/cas/})
    end

    it "returns you to Canvas login if you logged in via Canvas, but something else is the primary provider" do
      account_with_saml(account: Account.default, saml_log_out_url: "https://www.google.com/")
      session[:login_aac] = Account.default.canvas_authentication_provider.id
      delete "destroy"
      expect(response).to have_http_status :found
      expect(response.location).to match(%r{/login/canvas$})
    end
  end

  describe "#logout_landing" do
    it "redirects to /login if not logged in" do
      get "logout_landing"
      expect(response).to redirect_to(login_url)
    end

    it "renders logout landing if just logged out" do
      flash[:logged_out] = true
      get "logout_landing"
      expect(response).to redirect_to(login_url)
    end

    it "renders if you are logged in" do
      user_session(user_factory)
      get "logout_landing"
      expect(response).to be_successful
      expect(response).to render_template(:logout_confirm)
    end
  end
end
