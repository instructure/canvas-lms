# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe AdaChatPopupController do
  describe "GET #show" do
    context "when not logged in" do
      it "redirects to login" do
        get :show
        expect(response).to redirect_to("/login")
      end
    end

    context "when logged in" do
      before(:once) { user_factory(active_all: true) }
      before { user_session(@user) }

      context "when ada_chatbot feature is disabled" do
        it "returns 404" do
          get :show
          expect(response).to be_not_found
        end
      end

      context "when ada_chatbot feature is enabled" do
        before(:once) { Account.default.enable_feature!(:ada_chatbot) }

        it "returns 200" do
          get :show
          expect(response).to be_successful
        end

        it "sets X-Frame-Options to DENY" do
          get :show
          expect(response.headers["X-Frame-Options"]).to eq("DENY")
        end
      end
    end
  end
end
