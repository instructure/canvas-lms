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

describe Lti::ContextControlsController, type: :request do
  # Introduces internal_lti_configuration and canvas_lti_configuration
  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:account) { account_model }
  let(:admin) { account_admin_user(name: "admin", account:) }

  let(:registration) { Lti::CreateRegistrationService.call(**create_registration_params) }
  let(:create_registration_params) do
    {
      account:,
      created_by: admin,
      registration_params:,
      configuration_params:
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
  let(:response_json) do
    response.parsed_body
  end

  before(:once) do
    account.enable_feature!(:lti_registrations_next)
  end

  before do
    user_session(admin)
  end

  def deployment_for(context)
    deployment = registration.new_external_tool(context)
    deployment.save!
    if context.is_a?(Course)
      Lti::ContextControl.create!(course: context, registration:, deployment:)
    elsif context.is_a?(Account)
      Lti::ContextControl.create!(account: context, registration:, deployment:)
    end

    deployment
  end

  describe "GET #index" do
    subject { get "/api/v1/lti_registrations/#{registration.id}/controls" }

    context "with deployments" do
      let(:deployment) { deployment_for(account) }
      let(:control) { deployment.context_controls.first }
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:course_deployment) { deployment_for(course) }
      let(:subaccount_deployment) { deployment_for(subaccount) }

      before do
        deployment
        course_deployment
        subaccount_deployment
      end

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns a list of deployments" do
        subject
        expect(response_json.length).to eq(3)
      end

      it "has the expected attributes" do
        subject
        deployment_json = response_json.find { |d| d["id"] == deployment.id }
        expect(deployment_json).to include(
          {
            id: deployment.id,
            context_name: account.name,
            context_id: account.id,
          }
        )
        expect(deployment_json.dig("context_controls", 0)).to include(
          {
            id: control.id,
            account_id: account.id,
            deployment_id: deployment.id,
          }
        )
      end

      it "sorts deployments by account hierarchy" do
        subject
        expect(response_json.map { |d| d["id"] }).to eq([deployment.id, course_deployment.id, subaccount_deployment.id])
      end

      context "when deployment has many controls" do
        let(:sub_course) { course_model(account: subaccount) }
        let(:other_control) { Lti::ContextControl.create!(course: sub_course, registration:, deployment:) }

        before do
          other_control
        end

        it "only returns control for deployment context" do
          # TODO: will be removed as part of INTEROP-8992
          subject

          deployment_json = response_json.find { |d| d["id"] == deployment.id }
          expect(deployment_json["context_controls"].length).to eq(1)
          expect(deployment_json["context_controls"].map { |cc| cc["id"] }).not_to include(other_control.id)
        end
      end
    end

    context "with no deployments" do
      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns an empty array" do
        subject
        expect(response_json).to eq([])
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
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end
    end
  end

  describe "GET #show" do
    subject { get "/api/v1/lti_registrations/#{registration.id}/controls/#{control.id}" }

    let(:deployment) { deployment_for(account) }
    let(:control) { deployment.context_controls.first }

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "returns the requested control" do
      subject
      expect(response_json).to eq(
        {
          account_id: account.id,
          available: true,
          context_name: account.name,
          course_id: nil,
          created_at: control.created_at.iso8601,
          created_by: nil,
          deployment_id: deployment.id,
          depth: 0,
          display_path: [account.name],
          id: control.id,
          path: control.path,
          registration_id: registration.id,
          updated_at: control.updated_at.iso8601,
          updated_by: nil,
          workflow_state: "active"
        }.with_indifferent_access
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
