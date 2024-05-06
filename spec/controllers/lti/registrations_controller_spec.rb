# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Lti::RegistrationsController do
  describe "GET index" do
    let(:account) { account_model }

    context "with flag disabled" do
      before do
        account.disable_feature!(:lti_registrations_page)
      end

      it "returns 404" do
        get :index, params: { account_id: account.id }
        expect(response).to be_not_found
      end
    end

    context "with flag enabled" do
      before do
        account.enable_feature!(:lti_registrations_page)
      end

      it "renders Extensions page" do
        get :index, params: { account_id: account.id }
        expect(response).to render_template(:index)
        expect(response).to be_successful
      end

      it "sets Extensions crumb" do
        get :index, params: { account_id: account.id }
        expect(assigns[:_crumbs].last).to include("Extensions")
      end

      it "sets active tab" do
        get :index, params: { account_id: account.id }
        expect(assigns[:active_tab]).to eq("extensions")
      end
    end
  end
end
