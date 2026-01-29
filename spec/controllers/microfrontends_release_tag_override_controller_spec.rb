# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../spec_helper"

RSpec.describe MicrofrontendsReleaseTagOverrideController do
  let(:account) { Account.default }
  let(:user) { user_model }

  before do
    user_session(user)
  end

  describe "when feature is disabled" do
    before do
      Setting.set("allow_microfrontend_release_tag_override", "false")
    end

    describe "GET #create" do
      it "returns 404" do
        get :create, params: { override: { canvas_career_learner: "https://assets.instructure.com/test" } }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE #destroy" do
      it "returns 404" do
        delete :destroy
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "when feature is enabled" do
    before do
      Setting.set("allow_microfrontend_release_tag_override", "true")
    end

    describe "GET #create" do
      context "with valid parameters" do
        it "sets override in session and redirects to root" do
          get :create, params: { override: { canvas_career_learner: "https://assets.instructure.com/test" } }

          expect(session[:microfrontend_overrides]).to eq({ "canvas_career_learner" => "https://assets.instructure.com/test" })
          expect(response).to redirect_to(root_url)
        end

        it "handles multiple overrides" do
          get :create, params: {
            override: {
              canvas_career_learner: "https://assets.instructure.com/test1",
              canvas_career_learning_provider: "https://assets.instructure.com/test2"
            }
          }

          expect(session[:microfrontend_overrides]).to eq({
                                                            "canvas_career_learner" => "https://assets.instructure.com/test1",
                                                            "canvas_career_learning_provider" => "https://assets.instructure.com/test2"
                                                          })
          expect(response).to redirect_to(root_url)
        end

        it "ignores blank values" do
          get :create, params: {
            override: {
              canvas_career_learner: "https://assets.instructure.com/test",
              canvas_career_learning_provider: ""
            }
          }

          expect(session[:microfrontend_overrides]).to eq({ "canvas_career_learner" => "https://assets.instructure.com/test" })
          expect(response).to redirect_to(root_url)
        end
      end

      context "with invalid app name" do
        it "returns 422 with error message" do
          get :create, params: { override: { invalid_app: "https://assets.instructure.com/test" } }

          expect(response).to have_http_status(:unprocessable_content)
          json_response = response.parsed_body
          expect(json_response["error"]).to include("must be one of")
        end
      end

      context "with invalid URL host" do
        it "returns 422 with error message" do
          get :create, params: { override: { canvas_career_learner: "https://evil.com/test" } }

          expect(response).to have_http_status(:unprocessable_content)
          json_response = response.parsed_body
          expect(json_response["error"]).to include("must be one of")
        end
      end

      context "with malformed URL" do
        it "returns 422 with error message" do
          get :create, params: { override: { canvas_career_learner: "not a url" } }

          expect(response).to have_http_status(:unprocessable_content)
          json_response = response.parsed_body
          expect(json_response["error"]).to include("must be a valid URL")
        end
      end
    end

    describe "DELETE #destroy" do
      it "clears overrides from session and redirects to root" do
        session[:microfrontend_overrides] = { "canvas_career_learner" => "https://assets.instructure.com/test" }

        delete :destroy

        expect(session[:microfrontend_overrides]).to be_nil
        expect(response).to redirect_to(root_url)
      end

      it "redirects to referrer if present" do
        session[:microfrontend_overrides] = { "canvas_career_learner" => "https://assets.instructure.com/test" }
        request.env["HTTP_REFERER"] = "http://test.host/courses/1"

        delete :destroy

        expect(response).to redirect_to("http://test.host/courses/1")
      end
    end
  end
end
