# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe ReactContentRouterController, type: :request do
  before do
    Rails.application.routes.disable_clear_and_finalize = true
  end

  after do
    Rails.application.reload_routes!
  end

  describe "GET 'index'" do
    context "context is an account" do
      before(:once) do
        @account = Account.default
        @admin = account_admin_user(account: @account)
      end

      before do
        Rails.application.routes.draw do
          get "accounts/:account_id/foo", to: "react_content_router#index"
        end
      end

      it "returns a 200 for a valid request" do
        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/foo"
        expect(response).to have_http_status(:ok)
      end

      it "returns a response body containing the main content div for a valid request" do
        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/foo"
        expect(response.body).to match(/<div id="content"/)
      end

      it "returns a response body containing the account navigation menu" do
        user_session(@admin)
        get "/accounts/" + @account.id.to_s + "/foo"
        expect(response.body).to match(/<nav role="navigation" aria-label="Admin Navigation Menu">/)
      end

      it "returns a redirect response if the user is not logged in" do
        get "/accounts/" + @account.id.to_s + "/foo"
        expect(response).to have_http_status(:found) # :found means a 302 redirect
      end
    end

    context "context is a course" do
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        Rails.application.routes.draw do
          get "courses/:course_id/foo", to: "react_content_router#index"
        end
      end

      it "returns a 200 for a valid request" do
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/foo"
        expect(response).to have_http_status(:ok)
      end

      it "returns a response body containing the main content div for a valid request" do
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/foo"
        expect(response.body).to match(/<div id="content"/)
      end

      it "returns a response body containing the account navigation menu" do
        user_session(@teacher)
        get "/courses/" + @course.id.to_s + "/foo"
        expect(response.body).to match(/<nav role="navigation" aria-label="Courses Navigation Menu">/)
      end

      it "returns a redirect response if the user is not logged in" do
        get "/courses/" + @course.id.to_s + "/foo"
        expect(response).to have_http_status(:found) # :found means a 302 redirect
      end
    end

    context "no context" do
      before(:once) do
        @admin = account_admin_user(account: @account)
      end

      before do
        Rails.application.routes.draw do
          get "foo", to: "react_content_router#index"
        end
      end

      it "returns a resource not found response, for a route alias that has no context" do
        user_session(@admin)
        get "/foo"
        expect(response).to have_http_status(:not_found)
      end

      it "returns a resource not found response if the user is not logged in, for a route alias that has no context" do
        get "/foo"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
