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
  let(:response_data) do
    response_json[:data]
  end

  let_once(:account) { account_model }
  let_once(:admin) { account_admin_user(name: "A User", account:) }

  before do
    user_session(admin)
    account.enable_feature!(:lti_registrations_page)
  end

  describe "GET index" do
    context "without user session" do
      before { remove_user_session }

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

    it "sets Apps crumb" do
      get :index, params: { account_id: account.id }
      expect(assigns[:_crumbs].last).to include("Apps")
    end

    it "sets active tab" do
      get :index, params: { account_id: account.id }
      expect(assigns[:active_tab]).to eq("apps")
    end

    it "does not set temp_dr_url in ENV" do
      get :index, params: { account_id: account.id }
      expect(assigns.dig(:js_env, :dynamicRegistrationUrl)).to be_nil
    end

    context "with temp_dr_url" do
      let(:temp_dr_url) { "http://example.com" }

      before do
        allow(Setting).to receive(:get).and_call_original
        allow(Setting).to receive(:get).with("lti_discover_page_dyn_reg_url", anything).and_return(temp_dr_url)
      end

      it "sets temp_dr_url in ENV" do
        get :index, params: { account_id: account.id }
        expect(assigns.dig(:js_env, :dynamicRegistrationUrl)).to eq(temp_dr_url)
      end
    end
  end

  describe "GET list", type: :request do
    subject { get url }

    let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations" }

    context "correctness verifications" do
      before do
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
        it "is successful" do
          subject
          expect(response).to be_successful
        end

        it "returns the total count of registrations" do
          subject
          expect(response_json[:total]).to eq(4)
        end

        it "returns a list of registrations" do
          subject
          expect(response_data.length).to eq(4)
        end

        it "has the expected fields in the results" do
          subject

          expect(response_data.first)
            .to include({ account_id: an_instance_of(Integer), name: an_instance_of(String) })

          expect(response_data.first[:account_binding])
            .to include({ workflow_state: an_instance_of(String) })

          expect(response_data.first[:account_binding][:created_by])
            .to include({ id: an_instance_of(Integer) })
        end

        it "sorts the results by newest first by default" do
          lti_registration_model(account:, name: "created just now")
          lti_registration_model(account:, name: "created an hour ago", created_at: 1.hour.ago)

          subject
          expect(response_data.first["name"]).to eq("created just now")
          expect(response_data.last["name"]).to eq("created an hour ago")
        end

        context "when sorting by installed_by" do
          subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=installed_by" }

          before do
            # Other admin is "A User" -- registrations with an LRAB by B User should be last
            admin2 = account_admin_user(name: "B User", account:)
            lti_registration_model(name: "Created by B User", created_by: admin2, account:)
          end

          it "sorts by the lti_registration_account_binding.created_by" do
            subject
            expect(response_data.last["name"]).to eq("Created by B User")
          end

          context "with the dir=asc parameter" do
            subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=installed_by&dir=asc" }

            it "puts the results in ascending order" do
              subject
              expect(response_data.first["name"]).to eq("Created by B User")
            end
          end
        end

        context "when sorting by name" do
          subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=name" }

          before do
            lti_registration_model(account:, name: "AAA registration")
            lti_registration_model(account:, name: "ZZZ registration")
          end

          it "sorts by name" do
            subject
            expect(response_data.first["name"]).to eq("ZZZ registration")
            expect(response_data.last["name"]).to eq("AAA registration")
          end

          context "with the dir=asc parameter" do
            subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=name&dir=asc" }

            it "puts the results in ascending order" do
              subject
              expect(response_data.first["name"]).to eq("AAA registration")
              expect(response_data.last["name"]).to eq("ZZZ registration")
            end
          end
        end

        context "when sorting by a nil attribute" do
          subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=nickname" }

          it "treats nil like an empty value" do
            lti_registration_model(admin_nickname: "a nickname", account:)
            lti_registration_model(admin_nickname: nil, account:)
            subject
            expect(response_data.first["admin_nickname"]).to eq("a nickname")
          end
        end

        context "when sorting by a workflow_state" do
          subject { get "/api/v1/accounts/#{account.id}/lti_registrations?sort=on" }

          it "does not error if the account binding is nil" do
            reg = lti_registration_model(account:, name: "no account bindings")
            # expect it to have no account bindings, just in case we start automatically
            # creating a default one in the future.
            expect(reg.lti_registration_account_bindings).to eq([])
            subject
            expect(response_data.last["name"]).to eq("no account bindings")
          end
        end

        context "with a search query param matching no results" do
          let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations?query=searchterm" }

          it "finds no registrations" do
            subject
            expect(response_data.length).to eq(0)
          end
        end

        context "with a search query param matching some results" do
          # search for "registration no" which should find "Registration no. 1" etc.
          let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations?query=registration%20no" }

          it "finds matching registrations" do
            subject
            # searching "registration no" should find the three registrations titled
            # "Registration no. N"
            expect(response_data.length).to eq(3)
          end

          it "rejects registrations that do not match all terms" do
            # The name "registration" alone is not enough to match search terms "registration no"
            incomplete_match = lti_registration_model(account:, name: "registration")
            subject
            expect(response_data.pluck(:id)).not_to include(incomplete_match.id)
          end

          it "finds registrations with matching terms across different model attributes" do
            multi_attribute_match = lti_registration_model(account:, name: "registration", vendor: "no")
            subject
            expect(response_data.pluck(:id)).to include(multi_attribute_match.id)
          end

          it "includes the current search parameters in the Link header" do
            subject
            expect(response.headers["Link"]).to include("?query=registration+no")
          end

          context "query param validations" do
            it "returns a 422 if the page param isn't an integer" do
              get "/api/v1/accounts/#{account.id}/lti_registrations?page=bad"
              expect(response_json["errors"].first["message"]).to eq("page param should be an integer")
            end

            it "returns a 422 if the dir param isn't valid" do
              get "/api/v1/accounts/#{account.id}/lti_registrations?dir=bad"
              expect(response_json["errors"].first["message"]).to eq("dir param should be asc, desc, or empty")
            end

            it "returns a 422 if the sort param isn't valid" do
              get "/api/v1/accounts/#{account.id}/lti_registrations?sort=bad"
              expect(response_json["errors"].first["message"]).to eq("bad is not a valid field for sorting")
            end
          end
        end
      end

      context "without user session" do
        before { remove_user_session }

        it "returns 401" do
          subject
          expect(response).to be_unauthorized
        end
      end

      context "with non-admin user" do
        before { user_session(student_in_course(account:).user) }

        it "returns 401" do
          subject
          expect(response).to be_unauthorized
        end
      end

      context "with flag disabled" do
        before { account.disable_feature!(:lti_registrations_page) }

        it "returns 404" do
          subject
          expect(response).to be_not_found
        end
      end
    end

    context "pagination" do
      # Link header is a comma-separated list
      let(:link_header_values) { response.headers["Link"].split(",") }
      let(:current_pagination_link) { "http://www.example.com#{url}?page=#{expected_page_number}&per_page=15" }
      let(:expected_page_number) { raise "define expected_page_number in specific contexts" }

      context "with exactly 15 registrations present" do
        before do
          10.times do |number|
            registration = lti_registration_model(account:, name: "Registration no. #{number}")
            lti_registration_account_binding_model(registration:, account:, workflow_state: "on", created_by: admin)
          end

          # registration in another account
          5.times do
            enabled_site_admin_reg = lti_registration_model(account: Account.site_admin, name: "Site admin registration")
            lti_registration_account_binding_model(
              registration: enabled_site_admin_reg,
              account:,
              workflow_state: "on"
            )
          end
        end

        let(:expected_page_number) { 1 }

        it "puts results on one page and does not give a 'next' page in the Link header" do
          subject
          expect(response_data.length).to eq(15)

          # Expect the current pagination link to be given as rel=first, rel=last, and rel=current
          # in the header.
          %w[first last current].each do |link_rel|
            expect(link_header_values).to include("<#{current_pagination_link}>; rel=\"#{link_rel}\"")
          end

          # Should only be three items in the list (i.e. no "next").
          expect(link_header_values.length).to eq(3)
        end

        context "with per_page over max" do
          subject { get url + "?per_page=5" }

          before do
            stub_const("Api::MAX_PER_PAGE", 3)
          end

          it "returns max amount" do
            subject
            expect(response_data.length).to eq(3)
          end
        end

        context "with 20 registrations present" do
          # create 5 additional registrations on top of the existing 15
          before do
            5.times do |number|
              registration = lti_registration_model(account:, name: "Registration no. #{15 + number}")
              lti_registration_account_binding_model(registration:, account:, workflow_state: "on", created_by: admin)
            end
          end

          let(:expected_page_number) { 2 }

          it "gives a link to page 2 for the next, and last, page" do
            subject

            %w[next last].each do |link_rel|
              expect(link_header_values).to include("<#{current_pagination_link}>; rel=\"#{link_rel}\"")
            end
          end

          it "returns the total count" do
            subject
            expect(response_json[:total]).to eq(20)
          end

          it "returns five results on page 2 and says that is the last page" do
            get "#{url}?page=2"

            expect(response_data.length).to eq(5)

            %w[current last].each do |link_rel|
              expect(link_header_values).to include("<#{current_pagination_link}>; rel=\"#{link_rel}\"")
            end
          end
        end
      end
    end
  end

  describe "GET show", type: :request do
    subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}" }

    let_once(:registration) { lti_registration_model(account:) }
    let_once(:account_binding) { lti_registration_account_binding_model(registration:, account:) }

    before { account_binding }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "for nonexistent registration" do
      it "returns 404" do
        get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id + 1}"
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

  describe "PUT update", type: :request do
    subject { put "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}", params: { admin_nickname: } }

    let_once(:other_admin) { account_admin_user(account:) }
    let_once(:registration) { lti_registration_model(account:, created_by: other_admin, updated_by: other_admin) }
    let_once(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }
    let_once(:admin_nickname) { "New Name" }

    before { ims_registration }

    it "is successful" do
      subject
      expect(response).to be_successful
      expect(registration.reload.admin_nickname).to eq(admin_nickname)
      expect(registration.updated_by).to eq(admin)
    end

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "with non-dynamic registration" do
      before { ims_registration.update!(lti_registration: nil) }

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

  describe "DELETE destroy", type: :request do
    subject { delete "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}" }

    let_once(:registration) { lti_registration_model(account:) }
    let_once(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

    before { ims_registration }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "with non-dynamic registration" do
      before { ims_registration.update!(lti_registration: nil) }

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

  describe "POST bind", type: :request do
    subject { post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/bind", params: { workflow_state: } }

    let(:registration) { lti_registration_model(account:) }
    let(:workflow_state) { "off" }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "when model-level validations fail" do
      # for example, when the account is not a root account
      subject { post "/api/v1/accounts/#{child_account.id}/lti_registrations/#{registration.id}/bind", params: { workflow_state: } }

      let(:child_account) { account_model(parent_account: account) }
      let(:registration) { lti_registration_model(account: child_account) }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid workflow state" do
      let(:workflow_state) { "invalid" }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    context "without existing binding" do
      it "creates a new binding" do
        expect { subject }.to change { Lti::RegistrationAccountBinding.count }.by(1)
      end

      it "constructs the binding properly" do
        subject
        account_binding = Lti::RegistrationAccountBinding.last
        expect(account_binding.registration).to eq(registration)
        expect(account_binding.account).to eq(account)
        expect(account_binding.workflow_state).to eq(workflow_state)
        expect(account_binding.created_by).to eq(admin)
        expect(account_binding.updated_by).to eq(admin)
        expect(account_binding.root_account_id).to eq(account.id)
      end
    end

    context "with existing binding" do
      let(:account_binding) { lti_registration_account_binding_model(registration:, account:) }
      let(:initial_workflow_state) { "on" }
      let(:initial_updated_by) { user_model }

      before do
        account_binding.update!(workflow_state: initial_workflow_state, updated_by: initial_updated_by)
      end

      it "does not create a new binding" do
        expect { subject }.not_to change { Lti::RegistrationAccountBinding.count }
      end

      it "updates the existing binding" do
        expect { subject }.to change { account_binding.reload.workflow_state }.from(initial_workflow_state).to(workflow_state).and change { account_binding.updated_by }.from(initial_updated_by).to(admin)
      end
    end
  end
end
