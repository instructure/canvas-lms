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

require_relative "../../lti_1_3_tool_configuration_spec_helper"
require_relative "../../lti_1_3_spec_helper"

RSpec.describe Lti::RegistrationsController do
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

      it "only queries for account bindings once" do
        # With LRABs being preloaded, it should not call either of these "find" methods
        expect(Lti::RegistrationAccountBinding).not_to receive(:find_in_site_admin)
        expect(Lti::RegistrationAccountBinding).not_to receive(:find_by)
        subject
      end

      context "with a Lti::IMS::Registration in the list" do
        let(:registration) { lti_registration_model(account:) }
        let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

        it "includes the ims_registration_id" do
          ims_registration
          subject
          expect(response_data.find { |r| r["id"] == ims_registration.lti_registration_id }["ims_registration_id"]).to eq(ims_registration.id)
        end
      end

      context "when developer key is deleted" do
        # introduces `tool_configuration`
        include_context "lti_1_3_tool_configuration_spec_helper"

        let(:developer_key) { dev_key_model_1_3(account:) }
        let(:registration) { developer_key.lti_registration }

        before do
          # enable key
          developer_key.developer_key_account_bindings.first.update! workflow_state: :on
          developer_key.destroy
        end

        it "should not include registration" do
          expect(registration.reload).to be_deleted
          subject
          expect(response_data.pluck(:id)).not_to include(registration.id)
        end
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

      context "with 'overlay' in include[] parameter" do
        let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations?include[]=overlay" }
        let(:overlay) { lti_overlay_model(account:, registration:) }
        let(:registration) { lti_registration_model(account:) }

        before do
          overlay
        end

        it "includes the overlay" do
          subject
          expect(response_data.first).to have_key("overlay")
        end

        it "only queries for overlays once" do
          expect(Lti::Overlay).not_to receive(:find_in_site_admin)
          expect(Lti::Overlay).not_to receive(:find_by)
          subject
        end
      end

      context "with 'overlay_versions' in include[] parameter" do
        let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations?include[]=overlay&include[]=overlay_versions" }
        let(:overlay) { lti_overlay_model(account:, registration:) }
        let(:registration) { lti_registration_model(account:) }
        let(:overlay_versions) do
          lti_overlay_versions_model(
            {
              lti_overlay: overlay,
              diff: [["+", "disabled_scopes[0]", "https://canvas.instructure.com/lti-ags/progress/scope/show"]],
            },
            6
          )
        end

        before do
          overlay_versions
        end

        it "does not include overlay_versions" do
          subject
          expect(response_data.first["overlay"]).not_to have_key("versions")
        end
      end

      context "with cross-shard SiteAdmin on registration" do
        specs_require_sharding

        subject { @shard2.activate { get url } }

        let(:site_admin_registration) { lti_registration_model(account: Account.site_admin, name: "Site admin registration", bound: true) }

        before do
          site_admin_registration
        end

        it "includes the site admin registration" do
          subject
          expect(response_data.pluck(:id)).to include(site_admin_registration.global_id)
        end
      end

      context "with cross-shard inherited on registration" do
        specs_require_sharding

        subject { @shard2.activate { get url } }

        let(:site_admin_registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin, name: "Site admin registration") } }
        let(:inherited_binding) { @shard2.activate { lti_registration_account_binding_model(registration: site_admin_registration, account:, workflow_state: "on") } }
        let(:account) { @shard2.activate { account_model } }
        let(:admin) { @shard2.activate { account_admin_user(name: "A User", account:) } }

        before do
          user_session(admin)
          account.enable_feature!(:lti_registrations_page)
          inherited_binding
        end

        it "includes the inherited registration" do
          subject
          expect(response_data.pluck(:id)).to include(site_admin_registration.global_id)
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

        it "returns 403" do
          subject
          expect(response).to be_forbidden
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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
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

    context "with 'overlaid_configuration' in include[] parameter" do
      subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}?include[]=overlaid_configuration" }

      it "includes the overlaid configuration" do
        subject
        expect(response_json).to have_key(:overlaid_configuration)
      end
    end

    context "with 'overlay' in include[] parameter" do
      subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}?include[]=overlay" }

      let(:overlay) { lti_overlay_model(account:, registration:) }

      before do
        overlay
      end

      it "includes the overlay" do
        subject
        expect(response_json).to have_key(:overlay)
      end
    end

    context "with 'overlay_versions' in include[] parameter" do
      subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}?include[]=overlay&include[]=overlay_versions" }

      let(:overlay) { lti_overlay_model(account:, registration:) }
      let(:overlay_versions) do
        lti_overlay_versions_model(
          {
            lti_overlay: overlay,
            diff: [["+", "disabled_scopes[0]", "https://canvas.instructure.com/lti-ags/progress/scope/show"]],
          },
          6
        )
      end

      before do
        overlay_versions
      end

      it "includes the overlay versions" do
        subject
        expect(response_json[:overlay]).to have_key(:versions)
        expect(response_json[:overlay][:versions].length).to eq(5)
      end
    end
  end

  describe "GET show_by_client_id", type: :request do
    subject { get "/api/v1/accounts/#{account.id}/lti_registration_by_client_id/#{developer_key.id}" }

    let(:developer_key) { dev_key_model_1_3(account:) }
    let(:registration) { developer_key.lti_registration }

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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "for nonexistent developer key" do
      it "returns 404" do
        get "/api/v1/accounts/#{account.id}/lti_registrations/#{developer_key.id + 1}"
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

    it "includes the configuration" do
      subject
      expect(response_json).to have_key(:configuration)
    end
  end

  describe "PUT update", type: :request do
    subject do
      put "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}",
          params:,
          as: :json
      response
    end

    # Includes settings and internal_configuration
    include_context "lti_1_3_spec_helper"

    let(:params) do
      {
        admin_nickname:,
        vendor:,
        configuration: internal_configuration,
        name:,
        workflow_state: "on"
      }
    end

    let(:other_admin) { account_admin_user(account:) }
    let(:registration) { developer_key.lti_registration }
    let(:admin_nickname) { "New Name" }
    let(:name) { "foo" }
    let(:vendor) { "vendor" }

    before { tool_configuration }

    it "is successful" do
      expect(subject).to be_successful
      expect(registration.reload.admin_nickname).to eq(admin_nickname)
      expect(registration.updated_by).to eq(admin)
    end

    it "updates the registration's attributes" do
      expect(subject).to be_successful

      registration.reload

      expect(registration.admin_nickname).to eq(admin_nickname)
      expect(registration.vendor).to eq(vendor)
      expect(registration.name).to eq(name)
    end

    it "updates the associated developer key" do
      expect(subject).to be_successful

      attributes = registration.developer_key.reload
                               .attributes
                               .with_indifferent_access
                               .slice(:name,
                                      :public_jwk,
                                      :public_jwk_url,
                                      :scopes,
                                      :redirect_uris,
                                      :icon_url)
                               .compact

      expect(attributes).to eq(
        {
          name:,
          icon_url: internal_configuration[:launch_settings][:icon_url],
          **internal_configuration.slice(:public_jwk, :public_jwk_url, :scopes, :redirect_uris)
        }.with_indifferent_access
      )
    end

    it "updates the associated tool configuration" do
      expect(subject).to be_successful

      expect(tool_configuration.reload.internal_lti_configuration.except(:public_jwk_url).with_indifferent_access)
        .to eq(internal_configuration.with_indifferent_access)
    end

    it "updates the associated registration account binding" do
      expect(subject).to be_successful

      expect(registration.account_binding_for(account).workflow_state).to eq("on")
    end

    it "returns the appropriate info" do
      expect(subject).to be_successful

      expect(response_json[:configuration].with_indifferent_access.except(:public_jwk_url))
        .to eq(internal_configuration.with_indifferent_access)
      expect(response_json[:account_binding]).to include({ workflow_state: "on" })
    end

    it "doesn't create an unnecessary overlay" do
      expect { subject }.not_to change { Lti::Overlay.count }
      expect(subject).to be_successful
    end

    context "attempting to update disallowed fields" do
      let(:params) do
        super().tap do |p|
          p[:configuration][:developer_key_id] = -1234
        end
      end

      it "ignores the disallowed fields" do
        expect(subject).to be_successful

        expect(tool_configuration.reload.developer_key_id).not_to eq(-1234)
      end
    end

    context "updating a Dynamic Registration" do
      let(:ims_registration) { lti_ims_registration_model(account:) }
      let(:registration) { ims_registration.lti_registration }
      let(:params) do
        {
          admin_nickname: "New Name",
          vendor: "vendor",
          overlay: { "name" => "overlay name" },
        }
      end

      it { is_expected.to be_successful }

      context "trying to update it's base configuration" do
        let(:params) do
          {
            configuration: internal_configuration,
          }
        end

        it { is_expected.to have_http_status(:unprocessable_entity) }
      end
    end

    context "sending an overlay" do
      let(:params) do
        super().tap do |p|
          p[:overlay] = { "name" => "overlay name" }
        end
      end

      it "creates an overlay" do
        expect { subject }.to change { Lti::Overlay.count }.by(1)
        expect(subject).to be_successful

        expect(registration.overlay_for(account).data.with_indifferent_access)
          .to eq(params[:overlay].with_indifferent_access)
      end

      context "but an overlay already exists" do
        before do
          Lti::Overlay.create!(registration:, account:, data: { "name" => "old name" }, updated_by: admin)
        end

        it "updates the existing overlay" do
          expect { subject }.not_to change { Lti::Overlay.count }

          expect(subject).to be_successful
          expect(registration.overlay_for(account).data.with_indifferent_access)
            .to eq(params[:overlay].with_indifferent_access)
        end

        it "returns the overlay versions" do
          expect(subject).to be_successful

          expect(response_json[:overlay]).to include({ versions: an_instance_of(Array) })
        end
      end

      context "an overlay exists in Site Admin but not for the current account" do
        let(:site_admin_user) { account_admin_user(account: Account.site_admin) }
        let(:site_admin_overlay) do
          Lti::Overlay.create!(registration:, account: Account.site_admin, data: { "name" => "site admin overlay" }, updated_by: site_admin_user)
        end

        before do
          site_admin_overlay
        end

        it { is_expected.to be_successful }

        it "doesn't change the site admin overlay" do
          expect { subject }.not_to change { site_admin_overlay.reload }
        end

        it "creates a new overlay for the current account" do
          expect { subject }.to change { Lti::Overlay.count }.by(1)

          expect(Lti::Overlay.find_by(registration:, account:).data.with_indifferent_access)
            .to eq(params[:overlay].with_indifferent_access)
        end
      end
    end

    context "with a legacy configuration" do
      let(:params) do
        super().tap do |p|
          p[:configuration] = registration.manual_configuration.settings.except(:public_jwk_url)
        end
      end

      it { is_expected.to be_successful }

      it "doesn't change the configuration" do
        expect { subject }.not_to change { tool_configuration.reload.internal_lti_configuration }
        expect(subject).to be_successful
      end
    end

    context "when updating only the nickname" do
      let(:params) { { admin_nickname: "A Great Partial Update" } }

      it "is successful" do
        expect { subject }.not_to change { tool_configuration.reload.internal_lti_configuration }
        expect(subject).to be_successful
        expect(registration.reload.admin_nickname).to eq(params[:admin_nickname])
      end
    end

    context "when updating only the overlay" do
      let(:params) do
        {
          overlay: {
            disabled_placements: ["course_navigation"],
          }
        }
      end

      it "is successful" do
        expect { subject }.not_to change { tool_configuration.reload.internal_lti_configuration }
        expect(subject).to be_successful

        expect(registration.overlay_for(account).data.with_indifferent_access)
          .to eq(params[:overlay].with_indifferent_access)
      end

      it "still tries to update all installed external tools" do
        expect_any_instance_of(DeveloperKey).to receive(:update_external_tools!).once

        subject
      end
    end

    context "when updating only the configuration" do
      let(:params) do
        {
          configuration: {
            **internal_configuration,
            title: "A Great Partial Update",
          }
        }
      end

      it "is successful" do
        expect(subject).to be_successful

        expect(tool_configuration.reload.internal_lti_configuration.with_indifferent_access.except(:public_jwk_url))
          .to eq(params[:configuration].with_indifferent_access)
      end
    end

    context "when updating only the workflow state" do
      let(:params) { { workflow_state: "off" } }

      it "is successful" do
        expect { subject }.not_to change { tool_configuration.reload.internal_lti_configuration }

        expect(subject).to be_successful
        expect(registration.account_binding_for(account).workflow_state).to eq(params[:workflow_state])
      end
    end

    context "when updating only the name" do
      let(:params) { { name: "A Great Partial Update" } }

      it "is successful" do
        expect { subject }.not_to change { tool_configuration.reload.internal_lti_configuration }

        expect(subject).to be_successful
        expect(registration.reload.name).to eq(params[:name])
      end
    end

    context "with an invalid configuration" do
      let(:params) do
        super().tap do |p|
          p[:configuration] = { "invalid" => "config" }
        end
      end

      it { is_expected.to have_http_status(:unprocessable_entity) }
    end

    context "with an invalid overlay" do
      let(:params) do
        super().tap do |p|
          p[:overlay] = { "disabled_scopes" => ["invalid"] }
        end
      end

      it { is_expected.to have_http_status(:unprocessable_entity) }
    end

    context "with overlay containing nil attribute" do
      let(:params) do
        super().tap do |p|
          p[:overlay] = { "domain" => nil }
        end
      end

      it "is successful" do
        expect(subject).to be_successful
        expect(registration.overlay_for(account).data[:domain]).to be_nil
      end
    end

    context "with configuration containing nil attribute" do
      let(:params) do
        super().tap do |p|
          p[:configuration] = { **internal_configuration, "domain" => nil }
        end
      end

      it "is successful" do
        expect(subject).to be_successful
        expect(tool_configuration.reload.domain).to be_nil
      end
    end

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        expect(subject).to be_unauthorized
      end
    end

    context "with non-admin user" do
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 403" do
        expect(subject).to be_forbidden
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        expect(subject).to be_not_found
      end
    end
  end

  describe "DELETE destroy", type: :request do
    subject { delete "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}" }

    let_once(:registration) { lti_registration_model(account:) }
    let_once(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }
    let_once(:account_binding) { lti_registration_account_binding_model(registration:, account:) }
    let_once(:overlay) { lti_overlay_model(account:, registration:) }

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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
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

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "deletes the registration" do
        subject
        expect(registration.reload).to be_deleted
      end
    end

    context "with registration for different account" do
      subject { delete "/api/v1/accounts/#{account.id}/lti_registrations/#{other_reg.id}" }

      let_once(:other_reg) { lti_registration_model(account: Account.site_admin) }
      let_once(:other_ims_registration) { lti_ims_registration_model(lti_registration: other_reg) }

      it "returns 400" do
        subject
        expect(response).to have_http_status(:bad_request)
      end

      it "does not delete the registration" do
        expect { subject }.not_to change { registration.reload.workflow_state }
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

    it "includes the account binding" do
      subject
      expect(response_json).to have_key(:account_binding)
    end

    it "includes the configuration" do
      subject
      expect(response_json).to have_key(:configuration)
    end

    it "includes the overlay" do
      subject
      expect(response_json).to have_key(:overlay)
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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
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

  describe "POST validate", type: :request do
    subject { post "/api/v1/accounts/#{account.id}/lti_registrations/configuration/validate", params: { url:, lti_configuration: }.compact, as: :json }

    let(:url) { nil }
    let(:lti_configuration) { nil }

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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    context "without any params" do
      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0)).to include("lti_configuration or url is required")
      end
    end

    context "with both params" do
      let(:url) { "http://example.com" }
      let(:lti_configuration) { { title: "Title" } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0)).to include("only one of lti_configuration or url")
      end
    end

    context "with invalid lti_configuration" do
      let(:lti_configuration) { { title: "Title" } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0)).to include("required")
      end
    end

    context "with valid lti_configuration" do
      # introduces `settings` (hard-coded JSON LtiConfiguration)
      include_context "lti_1_3_tool_configuration_spec_helper"

      let(:lti_configuration) { settings }

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "transforms the configuration" do
        subject
        expect(response_json["configuration"]).to eq internal_configuration.with_indifferent_access
      end

      it "adds a default redirect_uris to ensure the configuration is valid" do
        subject
        expect(response_json["configuration"]["redirect_uris"]).to eq internal_configuration[:redirect_uris]
      end

      context "with redirect_uris" do
        let(:lti_configuration) { settings.merge(redirect_uris:) }
        let(:redirect_uris) { ["http://example.com"] }

        it "is successful" do
          subject
          expect(response).to be_successful
        end

        it "includes redirect_uris" do
          subject
          expect(response_json["configuration"]["redirect_uris"]).to eq redirect_uris
        end

        context "with string redirect_uris" do
          let(:redirect_uris) { "http://example.com" }

          it "is successful" do
            subject
            expect(response).to be_successful
          end

          it "coerces redirect_uris to an array" do
            subject
            expect(response_json["configuration"]["redirect_uris"]).to eq [redirect_uris]
          end
        end
      end

      context "with null config values" do
        before do
          lti_configuration["extensions"][0]["tool_id"] = nil
        end

        it "is successful" do
          subject
          expect(response).to be_successful
        end
      end

      context "with null required values" do
        before do
          lti_configuration["title"] = nil
        end

        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "with url" do
      let(:url) { "http://example.com" }
      let(:result) { nil }

      before do
        allow(CanvasHttp).to receive(:get).with(url).and_return(result)
      end

      context "when url errors" do
        before do
          allow(CanvasHttp).to receive(:get).with(url).and_raise(CanvasHttp::Error)
        end

        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when url can't connect" do
        before do
          allow(CanvasHttp).to receive(:get).with(url).and_raise(SocketError)
        end

        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when url responds with non-200" do
        let(:result) { double(class: Net::HTTPBadRequest, code: 400) }

        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when url responds with non-JSON" do
        let(:result) { double(class: Net::HTTPSuccess, is_a?: true, body: "invalid json") }

        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when url responds with JSON" do
        let(:result) { double(class: Net::HTTPSuccess, is_a?: true, body: config.to_json) }

        context "when configuration is invalid" do
          let(:config) { { title: "Title" } }

          it "returns 422" do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_json.dig("errors", 0)).to include("required")
          end
        end

        context "when configuration is valid" do
          # introduces `settings` (hard-coded JSON LtiConfiguration)
          include_context "lti_1_3_tool_configuration_spec_helper"

          let(:config) { settings }

          it "is successful" do
            subject
            expect(response).to be_successful
          end

          it "transforms the configuration" do
            subject
            expect(response_json["configuration"]).to eq internal_configuration.with_indifferent_access
          end
        end
      end
    end
  end

  describe "POST create", type: :request do
    subject do
      post "/api/v1/accounts/#{account.id}/lti_registrations",
           params:,
           as: :json
      response
    end

    # Introduces internal_configuration and settings
    include_context "lti_1_3_tool_configuration_spec_helper"

    let(:params) do
      {
        name: "Test Tool",
        vendor: "Test Vendor",
        configuration: internal_configuration,
        admin_nickname: "Test Nickname"
      }
    end
    let(:account) { account_model }
    let(:admin) { account_admin_user(account:) }

    before do
      user_session(admin)
      account.enable_feature!(:lti_registrations_page)
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

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_page) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    it { is_expected.to be_successful }

    it "creates a new LTI registration" do
      expect { subject }.to change { Lti::Registration.count }.by(1)
    end

    it "creates a new Developer Key" do
      expect { subject }.to change { DeveloperKey.count }.by(1)
    end

    it "creates a new Tool Configuration" do
      expect { subject }.to change { Lti::ToolConfiguration.count }.by(1)

      expect(Lti::ToolConfiguration.last.internal_lti_configuration.with_indifferent_access)
        .to eq(internal_configuration.merge({ "public_jwk_url" => nil }).with_indifferent_access)
    end

    it "defaults to a nil unified_tool_id" do
      expect(subject).to be_successful

      expect(Lti::ToolConfiguration.last.unified_tool_id).to be_nil
    end

    it "returns the created registration" do
      subject
      expect(response).to be_successful
      expect(response_json[:name]).to eq("Test Tool")
      expect(response_json[:admin_nickname]).to eq("Test Nickname")
      expect(response_json[:configuration].with_indifferent_access.except(:public_jwk_url))
        .to eq(internal_configuration.with_indifferent_access)
      expect(response_json[:account_binding]).to be_present
    end

    it 'creates an account binding with a default state of "off"' do
      expect { subject }.to change { Lti::RegistrationAccountBinding.count }.by(1)

      expect(Lti::RegistrationAccountBinding.last.registration).to eq(Lti::Registration.last)
      expect(Lti::RegistrationAccountBinding.last.account).to eq(account)
      expect(Lti::RegistrationAccountBinding.last.workflow_state).to eq("off")
    end

    context "without nickname" do
      before do
        params.delete(:admin_nickname)
      end

      it "leaves nickname empty" do
        subject
        expect(response).to be_successful
        expect(response_json[:admin_nickname]).to be_nil
      end
    end

    context "setting the unified_tool_id" do
      let(:params) do
        super().tap do |p|
          p[:unified_tool_id] = "test_unified_tool_id"
        end
      end

      it "creates a new LTI registration with the unified_tool_id" do
        expect(subject).to be_successful

        expect(Lti::ToolConfiguration.last.unified_tool_id).to eq(params[:unified_tool_id])
      end
    end

    context "attempting to update disallowed fields" do
      let(:params) do
        super().tap do |p|
          p[:configuration][:developer_key_id] = -1234
        end
      end

      it "ignores the disallowed fields" do
        expect(subject).to be_successful

        expect(Lti::ToolConfiguration.last.developer_key_id).not_to eq(-1234)
      end
    end

    context "creating a registration in Site Admin" do
      let(:account) { Account.site_admin }

      it "defaults the key to being invisible" do
        expect { subject }.to change { DeveloperKey.count }.by(1)
        expect(subject).to be_successful

        expect(DeveloperKey.last.visible).to be(false)
      end

      it "doesn't associate the developer key with any account" do
        expect { subject }.to change { DeveloperKey.count }.by(1)
        expect(subject).to be_successful

        expect(DeveloperKey.last.account).to be_nil
      end
    end

    context "specifying a workflow state" do
      it "creates an account binding with the specified state" do
        params[:workflow_state] = "on"
        expect { subject }.to change { Lti::RegistrationAccountBinding.count }.by(1)

        expect(Lti::RegistrationAccountBinding.last.workflow_state).to eq("on")
      end

      it "returns 422 if the state is invalid" do
        params[:workflow_state] = "asdfasdfasdfasdf"
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid configuration" do
      let(:internal_configuration) { { title: "Invalid Tool" } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json[:errors].first).to include("required")
      end
    end

    context "without required parameters" do
      let(:params) { {} }

      it "returns 400" do
        subject
        expect(response).to have_http_status(:bad_request)
        expect(response_json[:errors].first["message"]).to include("configuration is missing")
      end
    end

    context "multiple redirect_uris listed" do
      let(:internal_configuration) do
        super().tap do |ic|
          ic[:redirect_uris] << "anotherredirecturi.com"
        end
      end

      it "is saved properly to the tool configuration" do
        expect { subject }.to change { Lti::ToolConfiguration.count }.by(1)

        expect(Lti::ToolConfiguration.last.redirect_uris).to eq internal_configuration[:redirect_uris]
      end
    end

    context "with overlay" do
      let(:params) do
        super().tap do |p|
          p[:overlay] = { title: "different title!" }
        end
      end

      it "creates a new LTI registration with overlay" do
        expect { subject }.to change { Lti::Overlay.count }.by(1)
        expect(response).to be_successful

        expect(Lti::Overlay.last.data).to eq({ "title" => "different title!" })
        expect(Lti::Registration.last.lti_overlays.last).to eq(Lti::Overlay.last)
      end

      it "returns the created overlay in the response" do
        expect(subject).to be_successful

        expect(response_json[:overlay][:data].with_indifferent_access)
          .to eq(params[:overlay].with_indifferent_access)
      end

      it "removes scopes from the dev key that are disabled in the overlay" do
        internal_configuration[:scopes] = TokenScopes::ALL_LTI_SCOPES.dup
        params[:overlay][:disabled_scopes] = [TokenScopes::LTI_AGS_SCORE_SCOPE]
        subject
        expect(response).to be_successful
        expect(DeveloperKey.last.scopes).to eq(TokenScopes::ALL_LTI_SCOPES - [TokenScopes::LTI_AGS_SCORE_SCOPE])
      end
    end

    context "with invalid overlay" do
      let(:params) do
        super().tap do |p|
          p[:overlay] = { "title" => 5 }
        end
      end

      it { is_expected.to have_http_status(:unprocessable_entity) }
    end

    context "using a legacy configuration" do
      let(:params) do
        super().tap do |p|
          p[:configuration] = settings
        end
      end

      it { is_expected.to be_successful }

      it "creates a new LTI registration" do
        expect { subject }.to change { Lti::Registration.count }.by(1)
      end

      it "creates a new Developer Key" do
        expect { subject }.to change { DeveloperKey.count }.by(1)
      end

      it "creates a new Tool Configuration" do
        expect { subject }.to change { Lti::ToolConfiguration.count }.by(1)

        expect(Lti::ToolConfiguration.last.internal_lti_configuration.with_indifferent_access)
          .to eq(internal_configuration.with_indifferent_access.merge(public_jwk_url: nil))
      end

      it "returns the created registration" do
        expect { subject }.to change { Lti::Registration.count }.by(1)

        expect(subject).to be_successful
        expect(response_json[:name]).to eq("Test Tool")
        expect(response_json[:admin_nickname]).to eq("Test Nickname")
      end
    end
  end
end
