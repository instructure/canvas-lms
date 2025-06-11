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
    registration # auto-create deployment and control first
  end

  def deployment_for(context)
    registration.new_external_tool(context)
  end

  def control_for(deployment, context)
    if context.is_a?(Course)
      Lti::ContextControl.create!(course: context, registration:, deployment:)
    elsif context.is_a?(Account)
      Lti::ContextControl.create!(account: context, registration:, deployment:)
    else
      raise ArgumentError, "Context must be a Course or Account"
    end
  end

  describe "GET #index" do
    subject { get "/api/v1/lti_registrations/#{registration.id}/controls", params: }

    let(:params) { { per_page: 15 } }

    context "with multiple deployments and lots of controls" do
      let(:account_deployment) { ContextExternalTool.find_by(lti_registration: registration, context: account) }
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:course_deployment) { deployment_for(course) }
      let(:subaccount_deployment) { deployment_for(subaccount) }

      before do
        9.times do
          account_course = course_model(account:)
          other_subaccount = account_model(parent_account: account)
          subaccount_course = course_model(account: other_subaccount)

          control_for(account_deployment, account_course)
          control_for(course_deployment, other_subaccount)
          control_for(subaccount_deployment, subaccount_course)
        end
      end

      it "paginates across deployments" do
        subject
        expect(response).to be_successful
        # Expecting 2 deployments for a total of 15 controls
        expect(response_json.length).to eq(2)
        expect(response_json[0]["id"]).to eq(account_deployment.id)
        expect(response_json[0]["context_controls"].length).to eq(10)
        response_json[0]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(account_deployment.id)
        end
        expect(response_json[1]["id"]).to eq(course_deployment.id)
        expect(response_json[1]["context_controls"].length).to eq(5)
        response_json[1]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(course_deployment.id)
        end

        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.detect { |link| link[:rel] == "next" }
        expect(next_link["page"]).to start_with "bookmark:"

        get next_link[:uri].to_s
        expect(response).to be_successful
        next_page_json = response.parsed_body
        expect(next_page_json.length).to eq(2)
        expect(next_page_json[0]["id"]).to eq(course_deployment.id)
        expect(next_page_json[0]["context_controls"].length).to eq(5)
        next_page_json[0]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(course_deployment.id)
        end
        expect(next_page_json[1]["id"]).to eq(subaccount_deployment.id)
        expect(next_page_json[1]["context_controls"].length).to eq(10)
        next_page_json[1]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(subaccount_deployment.id)
        end

        Api.parse_pagination_links(response.headers["Link"])
        links.detect { |link| link[:rel] == "next" }
      end

      it "calculates attributes for each control" do
        subject { get "/api/v1/lti_registrations/#{registration.id}/controls", params: { per_page: 100 } }

        response_json.each do |deployment_json|
          deployment_json["context_controls"].each do |control_json|
            control = Lti::ContextControl.find(control_json["id"])
            expect(control_json).to include(
              "child_control_count" => control.child_control_count,
              "subaccount_count" => control.subaccount_count,
              "course_count" => control.course_count,
              "depth" => a_kind_of(Integer)
            )
          end
        end
      end
    end

    context "with deployments" do
      let(:deployment) { registration.deployments.first }
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

        it "returns controls for the deployment" do
          subject

          deployment_json = response_json.find { |d| d["id"] == deployment.id }
          expect(deployment_json["context_controls"].length).to eq(2)
          expect(deployment_json["context_controls"].map { |cc| cc["id"] }).to include(other_control.id)
        end

        it "includes calculated attributes for a top-level control" do
          subject

          control_json = response_json.find { |d| d["id"] == deployment.id }["context_controls"].find { |cc| cc["id"] == control.id }
          expect(control_json).to include(
            {
              child_control_count: 1,
              subaccount_count: 1,
              course_count: 2,
              depth: 0
            }.with_indifferent_access
          )
        end

        it "includes calculated attributes for a sub-level control" do
          subject

          control_json = response_json.find { |d| d["id"] == deployment.id }["context_controls"].find { |cc| cc["id"] == other_control.id }
          expect(control_json).to include(
            {
              child_control_count: 0,
              subaccount_count: 0,
              course_count: 0,
              depth: 1
            }.with_indifferent_access
          )
        end
      end
    end

    context "with no deployments" do
      before do
        registration.deployments.each(&:destroy)
      end

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
          child_control_count: control.child_control_count,
          context_name: account.name,
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

  describe "POST #create" do
    subject do
      post "/api/v1/lti_registrations/#{registration.id}/controls",
           params:,
           as: :json
    end

    let(:params) { { course_id: course.id } }
    let(:course) { course_model(account:) }
    let(:root_deployment) { registration.deployments.first }

    before { root_deployment }

    it "creates a new control" do
      expect { subject }.to change { Lti::ContextControl.count }.by(1)
      expect(response).to be_successful
      expect(response_json).to include(
        {
          account_id: nil,
          available: true,
          context_name: course.name,
          course_id: course.id,
          created_at: an_instance_of(String),
          created_by: hash_including(id: admin.id),
          deployment_id: root_deployment.id,
          depth: 0,
          display_path: an_instance_of(Array),
          id: an_instance_of(Integer),
          path: an_instance_of(String),
          registration_id: registration.id,
          updated_at: an_instance_of(String),
          updated_by: hash_including(id: admin.id),
          workflow_state: "active"
        }.with_indifferent_access
      )
    end

    context "with course_id" do
      let(:course) { course_model(account:) }
      let(:params) { { course_id: course.id } }

      it "creates a new control with the specified course" do
        subject
        expect(Lti::ContextControl.last.course_id).to eq(course.id)
        expect(response_json["course_id"]).to eq(course.id)
        expect(response_json["account_id"]).to be_nil
      end
    end

    context "with both course_id and account_id" do
      let(:course) { course_model(account:) }
      let(:params) { { account_id: account.id, course_id: course.id } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0)).to eq("Context must have either an account or a course, not both")
      end
    end

    context "with neither course_id nor account_id" do
      let(:params) { {} }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0)).to eq("Either account_id or course_id must be present.")
      end

      context "with existing control" do
        it "returns 422" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_json["errors"]).to include(
            "Either account_id or course_id must be present."
          )
        end
      end
    end

    context "with deployment_id" do
      let(:subaccount) { account_model(parent_account: account) }
      let(:deployment) { registration.new_external_tool(subaccount).tap(&:save!) }
      let(:params) { { account_id: account.id, deployment_id: deployment.id } }

      it "creates a new control with the specified deployment" do
        subject
        expect(Lti::ContextControl.last.deployment_id).to eq(deployment.id)
        expect(response_json["deployment_id"]).to eq(deployment.id)
      end
    end

    context "with available: false" do
      let(:params) { { course_id: course.id, available: false } }

      it "creates a new control with available set to false" do
        subject
        expect(Lti::ContextControl.last.available).to be false
        expect(response_json["available"]).to be false
      end
    end

    context "without root deployment" do
      let(:params) { { account_id: account.id } }

      before { root_deployment.destroy }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include(
          "No active deployment found for the root account."
        )
      end
    end

    context "with existing control" do
      let(:params) { { account_id: account.id } }

      before do
        root_deployment
      end

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include(
          "A context control for this deployment and context already exists."
        )
      end
    end

    context "with existing deleted control" do
      let(:params) { { account_id: account.id, available: true } }
      let(:control) do
        root_deployment
        Lti::ContextControl.last.update!(account:, registration:, deployment: root_deployment, workflow_state: "deleted", available: false)
        Lti::ContextControl.last
      end

      before { control }

      it "restores control and updates params" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        expect(response).to be_created
        expect(response_json).to include(
          {
            available: true,
            id: control.id,
            workflow_state: "active"
          }.with_indifferent_access
        )
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

  describe "POST #create_many" do
    subject do
      post "/api/v1/lti_registrations/#{registration.id}/controls/bulk",
           params:,
           as: :json
    end

    let(:params) { [] }
    let(:root_deployment) { registration.deployments.first }

    before { root_deployment }

    context "with empty params" do
      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include("Invalid parameters. Expected an array of context control parameters.")
      end
    end

    context "with non-array params" do
      let(:params) { { account_id: account.id } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include("Invalid parameters. Expected an array of context control parameters.")
      end
    end

    context "with valid params" do
      let(:params) do
        [
          { account_id: subaccount2.id, available: true },
          { course_id: course.id, available: false },
          { account_id: subaccount.id, deployment_id: subdeployment.id }
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:subaccount2) { account_model(parent_account: account) }
      let(:subdeployment) { registration.new_external_tool(subaccount).tap(&:save!) }

      it "creates context controls" do
        expect { subject }.to change { Lti::ContextControl.count }.by(3)
        expect(response).to be_successful
        expect(response_json.length).to eq(3)
        expect(response_json.map(&:with_indifferent_access)).to match_array(
          [
            hash_including(account_id: subaccount2.id, available: true),
            hash_including(course_id: course.id, available: false),
            hash_including(account_id: subaccount.id, deployment_id: subdeployment.id)
          ]
        )
      end
    end

    context "with multiple controls for the same context" do
      let(:params) do
        [
          { account_id: subaccount.id, available: true },
          { account_id: subaccount.id, available: false },
          { course_id: course.id, available: false },
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }

      it "returns 422" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Cannot create multiple context controls for the same context")
      end
    end

    context "with a control with no account or course id" do
      let(:params) do
        [
          { available: true },
          { course_id: course.id, available: false },
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }

      it "returns 422" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Either account_id or course_id must be present for each context control")
      end
    end

    context "with a control with both account and course id" do
      let(:params) do
        [
          { account_id: subaccount.id, available: true },
          { course_id: course.id, account_id: subaccount.id, available: false },
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }

      it "returns 422" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Either account_id or course_id must be present for each context control, but not both")
      end
    end

    context "with a control referencing an existing control in an account" do
      let(:params) do
        [
          { account_id: subaccount.id, available: true },
          { course_id: course.id, available: false }
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:existing_control) { Lti::ContextControl.create!(account: subaccount, registration:, deployment: root_deployment, available: false) }

      before do
        existing_control
      end

      it "updates the existing control according to the request" do
        expect { subject }
          .to change { Lti::ContextControl.count }.by(1)
          .and change { existing_control.reload.available }.to true

        expect(response).to be_successful
        expect(response_json.length).to eq(2)
        expect(response_json.map(&:with_indifferent_access)).to match_array(
          [
            hash_including(account_id: subaccount.id, available: true),
            hash_including(course_id: course.id, available: false)
          ]
        )
      end
    end

    context "with a control referencing an existing control in a course" do
      let(:params) do
        [
          { account_id: subaccount.id, available: true },
          { course_id: course.id, available: false }
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }

      let(:existing_control) { Lti::ContextControl.create!(course:, registration:, deployment: root_deployment, available: true) }

      before do
        existing_control
      end

      it "updates the existing control" do
        expect { subject }
          .to change { Lti::ContextControl.count }.by(1)
          .and change { existing_control.reload.available }.to false

        expect(response).to be_successful
        expect(response_json.length).to eq(2)
        expect(response_json.map(&:with_indifferent_access)).to match_array(
          [
            hash_including(account_id: subaccount.id, available: true),
            hash_including(course_id: course.id, available: false)
          ]
        )
      end
    end

    context "with too many controls" do
      let(:max_size) { 1 }
      let(:params) do
        [
          { account_id: subaccount.id, available: true },
          { course_id: course.id, available: false }
        ]
      end
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }

      before do
        stub_const("Lti::ContextControlsController::MAX_BULK_CREATE", max_size)
      end

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include(
          "Cannot create more than #{max_size} context controls at once"
        )
      end
    end

    context "without root deployment" do
      let(:params) { [{ account_id: subaccount.id }] }
      let(:subaccount) { account_model(parent_account: account) }

      before { root_deployment.destroy }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(
          "No active deployment found for the root account."
        )
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

  describe "PUT #update" do
    subject do
      put "/api/v1/lti_registrations/#{registration_id}/controls/#{control_id}",
          params:
    end

    let(:deployment) { deployment_for(account) }
    let(:control) { deployment.context_controls.first }
    let(:params) { { available: false } }
    # control_id and registration_id are specified here so that it's easy to create
    # an id variable for a control or registration that doesn't exist.
    let(:control_id) { control.id }
    let(:registration_id) { registration.id }

    context "with the lti_registrations_next feature flag enabled" do
      it "updates the context control" do
        expect(control.available).to be true
        subject
        expect(control.reload.available).to be false
      end

      context "when missing the available param" do
        let(:params) { { not_the_right_parameter: true } }

        it "throws an error" do
          subject
          expect(response).to be_bad_request
        end
      end

      context "with a non-existent control" do
        let(:control_id) { (Lti::ContextControl.last&.id || 1) + 1 }

        it "returns a 404" do
          subject
          expect(response).to be_not_found
        end
      end

      context "with a non-existent registration" do
        let(:registration_id) { (Lti::Registration.last&.id || 1) + 1 }

        it "returns a 404" do
          subject
          expect(response).to be_not_found
        end
      end

      it "returns a 403 if the user is not an admin" do
        user_session(user_model)
        subject
        expect(response).to be_forbidden
      end
    end

    context "with the lti_registration_next flag disabled" do
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns a 404 if the lti_registrations_next feature flag is disabled" do
        subject
        expect(response).to be_not_found
      end
    end
  end

  describe "DELETE #delete" do
    subject { delete "/api/v1/lti_registrations/#{registration_id}/controls/#{control_id}" }

    let(:deployment) { deployment_for(account) }
    let(:control) { deployment.context_controls.first }
    let(:registration_id) { registration.id }
    let(:control_id) { control.id }

    context "with the lti_registrations_next feature flag enabled" do
      it "deletes and returns the context control" do
        subject
        expect(control.reload).to be_deleted
        expect(response).to be_successful
      end

      context "with a non-existent control" do
        let(:control_id) { (Lti::ContextControl.last&.id || 1) + 1 }

        it "returns a 404" do
          subject
          expect(response).to be_not_found
        end
      end

      context "with a non-existent registration" do
        let(:registration_id) { (Lti::Registration.last&.id || 1) + 1 }

        it "returns a 404" do
          subject
          expect(response).to be_not_found
        end
      end

      it "returns a 403 if the user is not an admin" do
        user_session(user_model)
        subject
        expect(response).to be_forbidden
      end
    end

    context "with the lti_registration_next flag disabled" do
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns a 404 if the lti_registrations_next feature flag is disabled" do
        subject
        expect(response).to be_not_found
      end
    end
  end
end
