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
    let(:admin) { account_admin_user(account:) }

    before do
      user_session(admin)
      account.enable_feature!(:lti_registrations_page)
    end

    context "without user session" do
      before do
        remove_user_session
      end

      it "redirects to login page" do
        get :index, params: { account_id: account.id }
        expect(response).to redirect_to(login_url)
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before do
        user_session(student)
      end

      it "redirects to homepage" do
        get :index, params: { account_id: account.id }
        expect(response).to be_redirect
      end
    end

    context "with flag disabled" do
      before do
        account.disable_feature!(:lti_registrations_page)
      end

      it "returns 404" do
        get :index, params: { account_id: account.id }
        expect(response).to be_not_found
      end
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

  describe "DELETE destroy" do
    subject { delete :destroy, params: { account_id: account.id, id: registration.id }, format: :json }

    let(:account) { account_model }
    let(:admin) { account_admin_user(account:) }
    let(:registration) { lti_registration_model(account:) }
    let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

    before do
      ims_registration
      user_session(admin)
      account.enable_feature!(:lti_registrations_page)
    end

    context "without user session" do
      before do
        remove_user_session
      end

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before do
        user_session(student)
      end

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with flag disabled" do
      before do
        account.disable_feature!(:lti_registrations_page)
      end

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "with non-dynamic registration" do
      before do
        ims_registration.update!(lti_registration: nil)
      end

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not delete the registration" do
        subject
        expect(registration.reload).not_to be_deleted
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "deletes the registration" do
      subject
      expect(registration.reload).to be_deleted
    end
  end
end
