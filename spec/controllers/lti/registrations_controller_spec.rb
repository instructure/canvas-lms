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
  let(:response_json) do
    body = response.parsed_body
    body.is_a?(Array) ? body.map(&:with_indifferent_access) : body.with_indifferent_access
  end

  describe "GET index" do
    let_once(:account) { account_model }
    let_once(:admin) { account_admin_user(account:) }

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

  describe "GET list", type: :request do
    subject { get "/api/v1/accounts/#{account.id}/lti_registrations" }

    let(:account) { account_model }
    let(:admin) { account_admin_user(account:) }

    before do
      account.enable_feature!(:lti_registrations_page)

      3.times do |number|
        registration = lti_registration_model(account:, name: "Registration no. #{number}")
        lti_registration_account_binding_model(registration:, account:, workflow_state: "on", created_by: admin)
      end

      other_account = account_model
      # registration in another account
      lti_registration_model(account: other_account, name: "Other account registration")

      enabled_site_admin_reg = lti_registration_model(account: Account.site_admin, name: "Site admin registration")
      lti_registration_account_binding_model(
        registration: enabled_site_admin_reg,
        account:,
        workflow_state: "on"
      )

      disabled_site_admin_reg = lti_registration_model(account: Account.site_admin, name: "Site admin registration 2")
      lti_registration_account_binding_model(
        registration: disabled_site_admin_reg,
        account:,
        workflow_state: "off"
      )

      # a registration account binding enabled for a different account
      lti_registration_account_binding_model(
        registration: disabled_site_admin_reg,
        account: other_account,
        workflow_state: "on"
      )

      # an lti registration with no account binding
      lti_registration_model(account: Account.site_admin, name: "Site admin registration with no binding")
    end

    context "with a user session" do
      before do
        user_session(admin)
        account.enable_feature!(:lti_registrations_page)
      end

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns a list of registrations" do
        subject
        expect(response_json.length).to eq(4)
      end

      it "has the expected fields in the results" do
        subject

        expect(response_json.first)
          .to include({ account_id: an_instance_of(Integer), name: an_instance_of(String) })

        expect(response_json.first[:account_binding])
          .to include({ workflow_state: an_instance_of(String) })

        expect(response_json.first[:account_binding][:created_by])
          .to include({ id: an_instance_of(Integer) })
      end

      it "sorts the results by newest first" do
        lti_registration_model(account:, name: "created just now")
        lti_registration_model(account:, name: "created an hour ago", created_at: 1.hour.ago)

        subject
        expect(response_json.first["name"]).to eq("created just now")
        expect(response_json.last["name"]).to eq("created an hour ago")
      end
    end

    context "without user session" do
      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before do
        user_session(student_in_course(account:).user)
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
  end

  describe "GET show" do
    subject { get :show, params: { account_id: account.id, id: registration.id }, format: :json }

    let_once(:account) { account_model }
    let_once(:admin) { account_admin_user(account:) }
    let_once(:registration) { lti_registration_model(account:) }
    let_once(:account_binding) { lti_registration_account_binding_model(registration:, account:) }

    before do
      user_session(admin)
      account.enable_feature!(:lti_registrations_page)
      account_binding
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

    context "for nonexistent registration" do
      it "returns 404" do
        get :show, params: { account_id: account.id, id: registration.id + 1 }, format: :json
        expect(response).to be_not_found
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "returns the registration" do
      subject
      expect(response_json).to include({
                                         id: registration.id,
                                       })
    end

    it "includes the account binding" do
      subject
      expect(response_json).to have_key(:account_binding)
    end

    it "includes the configuration" do
      subject
      expect(response_json).to have_key(:configuration)
    end
  end

  describe "PUT update" do
    subject { put :update, params: { account_id: account.id, id: registration.id, admin_nickname: }, format: :json }

    let_once(:account) { account_model }
    let_once(:other_admin) { account_admin_user(account:) }
    let_once(:admin) { account_admin_user(account:) }
    let_once(:registration) { lti_registration_model(account:, created_by: other_admin, updated_by: other_admin) }
    let_once(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }
    let_once(:admin_nickname) { "New Name" }

    before do
      ims_registration
      user_session(admin)
      account.enable_feature!(:lti_registrations_page)
    end

    it "is successful" do
      subject
      expect(response).to be_successful
      expect(registration.reload.admin_nickname).to eq(admin_nickname)
      expect(registration.updated_by).to eq(admin)
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

      it "does not modify the registration" do
        expect { subject }.not_to change { registration.reload.admin_nickname }
      end
    end

    context "with additional params" do
      let(:registration_params) { { admin_nickname:, created_by: admin } }

      it "only updates the nickname" do
        expect { subject }.not_to change { registration.reload.created_by }
      end
    end
  end

  describe "DELETE destroy" do
    subject { delete :destroy, params: { account_id: account.id, id: registration.id }, format: :json }

    let_once(:account) { account_model }
    let_once(:admin) { account_admin_user(account:) }
    let_once(:registration) { lti_registration_model(account:) }
    let_once(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

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
