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

RSpec.describe Lti::DeploymentsController do
  # Introduces internal_lti_configuration and canvas_lti_configuration
  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:response_json) do
    response.parsed_body
  end

  let(:account) { account_model }
  let(:registration) { Lti::CreateRegistrationService.call(**create_registration_params) }
  let(:create_registration_params) do
    {
      account:,
      created_by: admin,
      registration_params:,
      configuration_params:,
    }
  end
  let(:registration_params) do
    {
      name: "Test Tool",
      admin_nickname: "Test Tool nickname",
      description: "A great little description for this tool",
      vendor: "Test Vendor",
    }
  end
  let(:configuration_params) do
    internal_lti_configuration
  end

  let(:admin) { account_admin_user(name: "A User", account:) }

  before(:once) do
    account.enable_feature!(:lti_registrations_next)
  end

  before do
    user_session(admin)
    registration
  end

  describe "GET list", type: :request do
    subject { get url }

    let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments" }

    context "correctness verifications" do
      before do
        3.times do
          registration.new_external_tool(account)
        end
      end

      context "when using 'self' for the account_id parameter" do
        let(:url) { "/api/v1/accounts/self/lti_registrations/#{registration.id}/deployments" }

        it "is successful" do
          expect_any_instance_of(Lti::DeploymentsController)
            .to receive(:api_find)
            .with(Account.active, "self")
            .once
            .and_return(account)
          subject
          expect(response_json.length).to eq(4) # deployment is auto-created on registration
        end
      end

      context "when paginated" do
        let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments?per_page=2" }

        it "returns the correct number of deployments" do
          subject
          expect(response_json.length).to eq(2)
        end

        it "returns the correct pagination headers" do
          subject
          expect(response.headers["Link"]).to include('rel="next"')
        end
      end

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns a list of deployments" do
        subject
        expect(response_json.length).to eq(4) # deployment is auto-created on registration
      end

      it "has the expected fields in the results" do
        subject

        expect(response_json.first)
          .to include(
            {
              id: an_instance_of(Integer),
              context_name: an_instance_of(String),
              deployment_id: an_instance_of(String)
            }
          )
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
        before { account.disable_feature!(:lti_registrations_next) }

        it "returns 404" do
          subject
          expect(response).to be_not_found
        end
      end
    end
  end

  describe "GET list_controls", type: :request do
    subject do
      get url
      response
    end

    let(:url) { "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments/#{deployment.id}/controls" }
    let(:deployment) { registration.new_external_tool(account) }

    before do
      3.times do
        course = course_model(account:)
        Lti::ContextControl.create!(course:, registration:, deployment:)
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
      let(:student) { student_in_course(account:).user }

      before { user_session(student) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    context "with flag disabled" do
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    it { is_expected.to be_successful }

    it "returns a list of context controls" do
      subject
      expect(response_json.length).to eq(4)
    end

    it "has the expected fields in the results" do
      subject
      control = deployment.context_controls.first
      expect(response_json.find { |c| c["id"] == control.id }).to eq(
        {
          account_id: account.id,
          available: true,
          child_control_count: control.child_control_count,
          context_name: control.context_name,
          course_count: control.course_count,
          course_id: nil,
          created_at: control.created_at.iso8601,
          created_by: nil,
          deployment_id: deployment.id,
          depth: 0,
          display_path: control.display_path,
          id: control.id,
          path: control.path,
          registration_id: registration.id,
          subaccount_count: control.subaccount_count,
          updated_at: control.updated_at.iso8601,
          updated_by: nil,
          workflow_state: "active"
        }.with_indifferent_access
      )
    end

    context "when paginated" do
      let(:url) do
        "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments/#{deployment.id}/controls?per_page=2"
      end

      it "returns the correct number of context controls" do
        subject
        expect(response_json.length).to eq(2)
      end

      it "returns the correct pagination headers" do
        subject
        expect(response.headers["Link"]).to include('rel="next"')
      end
    end
  end

  describe "GET show", type: :request do
    subject do
      get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments/#{deployment.id}"
      response
    end

    let(:deployment) { registration.new_external_tool(account) }

    before { deployment.save! }

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
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    it { is_expected.to be_successful }

    it "returns the requested deployment" do
      subject
      expect(response_json).to eq(
        {
          id: deployment.id,
          context_id: account.id,
          context_type: "Account",
          context_name: account.name,
          deployment_id: deployment.deployment_id,
          registration_id: registration.id,
          workflow_state: "active",
        }.with_indifferent_access
      )
    end
  end

  describe "POST create", type: :request do
    subject do
      post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments",
           params: {},
           as: :json
      response
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
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end

    it { is_expected.to be_successful }

    it "creates a new LTI Deployment" do
      expect { subject }.to change { ContextExternalTool.count }.by(1)
      expect(ContextExternalTool.last.lti_registration.id).to eql(
        registration.id
      )
    end

    it "returns the created deployment" do
      subject
      expect(response).to be_successful
      expect(response_json[:registration_id]).to eq(registration.id)
      expect(response_json[:context_id]).to eq(account.id)
    end

    it "creates a context control for the deployment" do
      expect { subject }.to change { Lti::ContextControl.count }.by(1)
      expect(Lti::ContextControl.last.deployment.id).to eql(
        ContextExternalTool.last.id
      )
      expect(Lti::ContextControl.last.created_by).to eql(admin)
    end
  end

  describe "DELETE destroy", type: :request do
    subject do
      delete "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/deployments/#{deployment.id}",
             params: {},
             as: :json
      response
    end

    let(:deployment) { registration.new_external_tool(account) }
    let(:account) { account_model }
    let(:admin) { account_admin_user(account:) }

    before do
      # creates the deployment
      deployment
    end

    it "soft-deletes the deployment and controls" do
      expect { subject }.to change { ContextExternalTool.active.count }
        .by(-1)
        .and change { Lti::ContextControl.active.count }.by(-1)
    end
  end
end
