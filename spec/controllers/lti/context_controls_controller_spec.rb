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
      configuration_params:,
      binding_params: { workflow_state: "on" }
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

  before do
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

  shared_examples "navigation cache invalidation" do
    context "when the tool has navigation placements" do
      let(:configuration_params) do
        internal_lti_configuration.deep_merge({
                                                placements: [
                                                  { placement: "course_navigation", message_type: "LtiResourceLinkRequest" }
                                                ]
                                              })
      end

      it "invalidates the navigation cache" do
        nav_cache = instance_double(Lti::NavigationCache)
        allow(Lti::NavigationCache).to receive(:new).with(account).and_return(nav_cache)
        expect(nav_cache).to receive(:invalidate_cache_key)
        subject
      end
    end

    context "when the tool does not have navigation placements" do
      let(:configuration_params) do
        internal_lti_configuration.deep_merge({
                                                placements: [
                                                  { placement: "assignment_selection", message_type: "LtiDeepLinkingRequest" }
                                                ]
                                              })
      end

      it "does not invalidate the navigation cache" do
        expect(Lti::NavigationCache).not_to receive(:new)
        subject
      end
    end
  end

  describe "GET #index" do
    subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls", params: }

    let(:params) { { per_page: 15 } }

    context "with multiple deployments and lots of controls" do
      let(:account_deployment) { ContextExternalTool.find_by(lti_registration: registration, context: account) }
      let(:course) { course_model(account:) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:other_account_deployment) { deployment_for(account) }
      let(:subaccount_deployment) { deployment_for(subaccount) }

      before do
        9.times do
          account_course = course_model(account:)
          other_subaccount = account_model(parent_account: account)
          subaccount_course = course_model(account: subaccount)

          control_for(account_deployment, account_course)
          control_for(other_account_deployment, other_subaccount)
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
        expect(response_json[1]["id"]).to eq(other_account_deployment.id)
        expect(response_json[1]["context_controls"].length).to eq(5)
        response_json[1]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(other_account_deployment.id)
        end

        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.detect { |link| link[:rel] == "next" }
        expect(next_link["page"]).to start_with "bookmark:"

        get next_link[:uri].to_s
        expect(response).to be_successful
        next_page_json = response.parsed_body
        expect(next_page_json.length).to eq(2)
        expect(next_page_json[0]["id"]).to eq(other_account_deployment.id)
        expect(next_page_json[0]["context_controls"].length).to eq(5)
        next_page_json[0]["context_controls"].each do |control|
          expect(control["deployment_id"]).to eq(other_account_deployment.id)
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
      let(:control) { deployment.primary_context_control }
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
        expect(response_json.pluck("id")).to eq([deployment.id, course_deployment.id, subaccount_deployment.id])
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
          expect(deployment_json["context_controls"].pluck("id")).to include(other_control.id)
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

        it "doesn't include deleted or controls" do
          other_control.destroy

          subject
          controls = response_json.find { |d| d["id"] == deployment.id }["context_controls"]
          expect(controls.pluck("id")).not_to include(other_control.id)
        end

        it "sorts child course exceptions before child sub-account exceptions at the same level" do
          sub_sub_account = account_model(parent_account: subaccount)
          another_sub_course = course_model(account: subaccount)

          sub_sub_account_control = Lti::ContextControl.create!(account: sub_sub_account, registration:, deployment:)
          course_control = Lti::ContextControl.create!(course: another_sub_course, registration:, deployment:)

          subject

          deployment_json = response_json.find { |d| d["id"] == deployment.id }
          control_ids = deployment_json["context_controls"].pluck("id")

          course_index = control_ids.index(course_control.id)
          sub_account_index = control_ids.index(sub_sub_account_control.id)

          expect(course_index).to be < sub_account_index
        end

        it "ensures exceptions are ordered by parent account, not just logical depth" do
          sub_sub_account = account_model(parent_account: subaccount)
          other_sub_sub_account = account_model(parent_account: subaccount)
          another_sub_course = course_model(account: sub_sub_account)

          sub_account_control = Lti::ContextControl.create!(account: subaccount, registration:, deployment:)
          sub_sub_account_control = Lti::ContextControl.create!(account: sub_sub_account, registration:, deployment:)
          course_control = Lti::ContextControl.create!(course: another_sub_course, registration:, deployment:)
          sub_sub_account_control_2 = Lti::ContextControl.create!(account: other_sub_sub_account, registration:, deployment:)

          subject

          deployment_json = response_json.find { |d| d["id"] == deployment.id }
          control_ids = deployment_json["context_controls"].pluck("id")

          sub_account_index = control_ids.index(sub_account_control.id)
          sub_sub_account_index = control_ids.index(sub_sub_account_control.id)
          course_index = control_ids.index(course_control.id)
          other_sub_sub_index = control_ids.index(sub_sub_account_control_2.id)

          expect(sub_account_index).to be < sub_sub_account_index
          expect(sub_sub_account_index).to be < course_index
          expect(course_index).to be < other_sub_sub_index
        end

        it "paginates correctly with mixed courses and accounts at the same level" do
          courses = []
          accounts = []

          5.times do |i|
            courses << course_model(account: subaccount, name: "Course #{i}")
            accounts << account_model(parent_account: subaccount, name: "Sub-Account #{i}")
          end

          course_controls = courses.map { |c| Lti::ContextControl.create!(course: c, registration:, deployment:) }
          account_controls = accounts.map { |a| Lti::ContextControl.create!(account: a, registration:, deployment:) }

          # Fetch with small page size to force pagination. 14 controls total at this point:
          # 3 from each of the three deployments, one in the sub-course, then 10 we just made.
          get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls", params: { per_page: 7 }
          expect(response).to be_successful

          all_controls = []
          deployment_json = response.parsed_body.find { |d| d["id"] == deployment.id }
          all_controls.concat(deployment_json["context_controls"]) if deployment_json

          links = Api.parse_pagination_links(response.headers["Link"])
          next_link = links.detect { |link| link[:rel] == "next" }

          get next_link[:uri].to_s
          expect(response).to be_successful

          links = Api.parse_pagination_links(response.headers["Link"])

          expect(links.detect { it[:rel] == "next" }).to be_nil
          deployment_json = response.parsed_body.find { |d| d["id"] == deployment.id }
          all_controls.concat(deployment_json["context_controls"]) if deployment_json
          all_control_ids = all_controls.pluck("id")

          expect(all_control_ids).to include(*(course_controls.map(&:id) + account_controls.map(&:id)))

          course_control_ids = course_controls.map(&:id)
          account_control_ids = account_controls.map(&:id)

          last_course_index = all_control_ids.rindex { |id| course_control_ids.include?(id) }
          first_account_index = all_control_ids.index { |id| account_control_ids.include?(id) }

          expect(last_course_index).to be < first_account_index
        end
      end
    end

    context "with cross-shard registration" do
      specs_require_sharding

      let(:registration) { @shard2.activate { lti_registration_with_tool(account: xshard_account) } }
      let(:xshard_account) { @shard2.activate { account_model } }
      let(:local_deployment) { deployment_for(account) }

      before { local_deployment }

      it "returns deployments and controls from current shard" do
        subject
        expect(response).to be_successful
        expect(response_json.length).to eq(1)
        expect(response_json[0]["id"]).to eq(local_deployment.id)
        expect(response_json[0]["context_controls"].length).to eq(1)
      end

      context "when registration's account has flag off" do
        before { xshard_account.disable_feature!(:lti_registrations_next) }

        it "returns deployment and controls from current shard" do
          subject
          expect(response).to be_successful
          expect(response_json.length).to eq(1)
          expect(response_json[0]["id"]).to eq(local_deployment.id)
          expect(response_json[0]["context_controls"].length).to eq(1)
        end
      end
    end

    context "with inherited registration shared across multiple root accounts" do
      subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{site_admin_registration.id}/controls", params: }

      let(:site_admin) { Account.site_admin }
      let(:site_admin_user) { account_admin_user(account: site_admin) }
      let(:site_admin_registration) do
        Lti::CreateRegistrationService.call(
          account: site_admin,
          created_by: site_admin_user,
          registration_params:,
          configuration_params:
        )
      end
      let(:other_root_account) { account_model }
      let(:account_deployment) { site_admin_registration.new_external_tool(account) }
      let(:other_deployment) { site_admin_registration.new_external_tool(other_root_account) }
      let(:account_control) { account_deployment.primary_context_control }
      let(:other_control) { other_deployment.primary_context_control }

      before do
        site_admin.enable_feature!(:lti_registrations_next)
        other_root_account.enable_feature!(:lti_registrations_next)
        account_control
        other_control
      end

      it "only returns controls from the current root account" do
        subject
        expect(response).to be_successful

        # Should only see controls from current account, not other_root_account
        all_control_ids = response_json.flat_map { |d| d["context_controls"].pluck("id") }
        expect(all_control_ids).to eql([account_control.id])
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
    subject { get "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls/#{control.id}" }

    let(:deployment) { deployment_for(account) }
    let(:control) { deployment.primary_context_control }

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
      post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls",
           params:,
           as: :json
    end

    let(:params) { { course_id: course.id } }
    let(:course) { course_model(account:) }
    let(:root_deployment) { registration.deployments.first }

    before { root_deployment }

    include_examples "navigation cache invalidation"

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

    it "tracks the changes" do
      expect { subject }.to change { Lti::RegistrationHistoryEntry.count }.by(1)
      history_entry = Lti::RegistrationHistoryEntry.last

      expect(history_entry.diff["context_controls"]).to match_array(
        [["+", [Lti::ContextControl.last.id], Lti::ContextControl.last.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)]]
      )

      # We created a bunch, so the old will just be an empty hash.
      expect(history_entry.old_context_controls).to eq({})
      expect(history_entry.new_context_controls).to be_present

      new_control_id = Lti::ContextControl.last.id
      expect(history_entry.new_context_controls[new_control_id.to_s])
        .to eql(Lti::ContextControl.last.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES))
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
        expect(response_json.dig("errors", 0)).to eq("Exactly one context must be present")
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
      let(:subsubaccount) { account_model(parent_account: subaccount) }
      let(:deployment) { registration.new_external_tool(subaccount).tap(&:save!) }
      let(:params) { { account_id: subsubaccount.id, deployment_id: deployment.id } }

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

    context "with context outside the deployment's context chain" do
      let(:subaccount) { account_model(parent_account: account) }
      let(:subdeployment) { registration.new_external_tool(subaccount) }
      let(:other_account) { account_model(parent_account: account) }
      let(:params) { { account_id: other_account.id, deployment_id: subdeployment.id } }

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include(
          "Context must belong to the deployment's context"
        )
      end
    end

    context "for context deep in deployment's hierarchy" do
      let(:subaccount) { account_model(parent_account: account) }
      let(:subsubaccount) { account_model(parent_account: subaccount) }
      let(:params) { { account_id: subsubaccount.id } }

      it "also creates an anchor control" do
        expect { subject }.to change { Lti::ContextControl.count }.by(2)
      end

      context "anchor control" do
        let(:anchor_control) { Lti::ContextControl.find_by(deployment: root_deployment, account: subaccount) }

        it "belongs to context right below deployment" do
          subject
          expect(anchor_control).to be_present
        end

        it "matches deployment control's availability" do
          subject
          expect(anchor_control.available).to eq(root_deployment.primary_context_control.available)
        end
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

    context "for account outside root account" do
      let(:other_account) { account_model }
      let(:params) { { account_id: other_account.id } }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end

    context "for course outside root account" do
      let(:other_account) { account_model }
      let(:params) { { course_id: other_course.id } }
      let(:other_course) { course_model(account: other_account) }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
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
      post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls/bulk",
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

      include_examples "navigation cache invalidation"

      it "creates context controls" do
        subdeployment
        expect { subject }.to change { Lti::ContextControl.count }.by(2)
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

      it "tracks the changes properly" do
        subdeployment
        expect { subject }.to change { Lti::RegistrationHistoryEntry.count }.by(1)
        expect(response).to be_successful

        subaccount_control = Lti::ContextControl.find_by(account_id: subaccount2.id, registration:)
        course_control = Lti::ContextControl.find_by(course_id: course.id, registration:)

        # The subdeployment control isn't included because it doesn't actually get changed by this request
        # and our history tracker notices that!
        expected_diff = [
          ["+", [subaccount_control.id], subaccount_control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)],
          ["+", [course_control.id], course_control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)],
        ]

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["context_controls"]).to match_array(expected_diff)

        expect(history_entry.old_context_controls).to be_present
        expect(history_entry.new_context_controls).to be_present

        expect(history_entry.new_context_controls[subaccount_control.id.to_s])
          .to eql(subaccount_control.reload.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES))
        expect(history_entry.new_context_controls[course_control.id.to_s])
          .to eql(course_control.reload.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES))
      end
    end

    describe "with controls that need anchors" do
      # see Lti::ContextControlService.build_anchor_controls for what these mean
      let(:params) do
        [
          { account_id: other_subsubaccount.id.to_s, available: true },
          { course_id: course.id.to_s, available: false },
        ]
      end

      let(:course) { course_model(account: subaccount) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:other_subaccount) { account_model(parent_account: account) }
      let(:other_subsubaccount) { account_model(parent_account: other_subaccount) }

      it "creates controls and anchor controls where needed" do
        expect { subject }.to change { Lti::ContextControl.count }.by(4)
        expect(response).to be_successful
        expect(response_json.length).to eq(4)
        expect(response_json.map(&:with_indifferent_access)).to match_array(
          [
            hash_including(account_id: other_subsubaccount.id, available: true),
            hash_including(course_id: course.id, available: false),
            hash_including(account_id: other_subaccount.id, available: root_deployment.primary_context_control.available), # anchor
            hash_including(account_id: subaccount.id, available: root_deployment.primary_context_control.available) # anchor
          ]
        )
      end

      it "tracks the changes" do
        subject

        body = response.parsed_body

        controls = Lti::ContextControl.where(id: body.pluck("id"))

        expected = controls.map do |control|
          ["+", [control.id], control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)]
        end
        expect(Lti::RegistrationHistoryEntry.last.diff["context_controls"]).to match_array(
          expected
        )
      end

      context "and all of those controls need the same anchor control" do
        let(:params) do
          [
            { course_id: course.id.to_s, available: false },
            { course_id: other_course.id.to_s, available: true }
          ]
        end

        let(:other_course) { course_model(account: subaccount) }

        it "creates a single anchor control and doesn't error" do
          subject
          expect(response).to be_successful
          expect(response_json.length).to eq(3)
          expect(response_json.map(&:with_indifferent_access)).to match_array(
            [
              hash_including(course_id: other_course.id, available: true),
              hash_including(course_id: course.id, available: false),
              hash_including(account_id: subaccount.id, available: root_deployment.primary_context_control.available) # anchor
            ]
          )
        end
      end

      context "when anchor control already exists" do
        let(:anchor_control) { Lti::ContextControl.create!(account: other_subaccount, registration:, deployment: root_deployment, available: true) }

        before do
          anchor_control
        end

        it "does not create a new anchor control" do
          expect { subject }.to change { Lti::ContextControl.count }.by(3)
          expect(response).to be_successful
          expect(response_json.length).to eq(4)
          expect(response_json.map(&:with_indifferent_access)).to match_array(
            [
              hash_including(account_id: other_subsubaccount.id, available: true),
              hash_including(course_id: course.id, available: false),
              hash_including(account_id: other_subaccount.id, available: root_deployment.primary_context_control.available), # existing anchor is still returned
              hash_including(account_id: subaccount.id, available: root_deployment.primary_context_control.available) # anchor
            ]
          )
        end

        it "tracks the changes" do
          subject

          body = response.parsed_body

          controls = Lti::ContextControl.where(id: body.filter { |c| c["id"] != anchor_control.id }.pluck("id"))

          expected = controls.map do |control|
            ["+", [control.id], control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)]
          end
          expected << ["~", [anchor_control.id, "available"], true, false]

          expect(Lti::RegistrationHistoryEntry.last.diff["context_controls"]).to match_array(
            expected
          )
        end
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

      it "tracks the changes" do
        expect { subject }.to change { Lti::RegistrationHistoryEntry.count }.by(1)

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["context_controls"]).to match_array(
          [
            ["~", [existing_control.id, "available"], false, true],
            ["+", [Lti::ContextControl.last.id], Lti::ContextControl.last.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES)]
          ]
        )

        expect(history_entry.old_context_controls[existing_control.id.to_s]["available"]).to be false
        expect(history_entry.new_context_controls[existing_control.id.to_s]["available"]).to be true

        new_control = Lti::ContextControl.last
        expect(history_entry.new_context_controls[new_control.id.to_s])
          .to eql(new_control.attributes.with_indifferent_access.slice(*Lti::ContextControl::TRACKED_ATTRIBUTES))
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

      it "does not create a history entry when re-setting the same values" do
        # First create both controls
        post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls/bulk",
             params: [
               { account_id: subaccount.id, available: true },
               { course_id: course.id, available: false }
             ],
             as: :json
        expect(response).to be_successful

        # Now try to create them again with the same values - should not create a history entry
        expect do
          post "/api/v1/accounts/#{account.id}/lti_registrations/#{registration.id}/controls/bulk",
               params: [
                 { account_id: subaccount.id, available: true },
                 { course_id: course.id, available: false }
               ],
               as: :json
        end.not_to change { Lti::RegistrationHistoryEntry.count }

        expect(response).to be_successful
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

    context "with control for a context outside the deployment's context chain" do
      let(:subaccount) { account_model(parent_account: account) }
      let(:subdeployment) { registration.new_external_tool(subaccount) }
      let(:other_account) { account_model(parent_account: account) }
      let(:params) do
        [
          { account_id: other_account.id, deployment_id: subdeployment.id, available: true }
        ]
      end

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0, "message")).to eq(
          "Context must belong to the deployment's context"
        )
      end
    end

    context "with control for a context outside the root account" do
      let(:other_account) { account_model }
      let(:params) do
        [
          { account_id: other_account.id, available: true }
        ]
      end

      it "returns 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json.dig("errors", 0, "message")).to eq(
          "Context must belong to the deployment's context"
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
      put "/api/v1/accounts/#{account.id}/lti_registrations/#{registration_id}/controls/#{control_id}",
          params:
    end

    let(:deployment) { deployment_for(account) }
    let(:control) { deployment.primary_context_control }
    let(:params) { { available: false } }
    # control_id and registration_id are specified here so that it's easy to create
    # an id variable for a control or registration that doesn't exist.
    let(:control_id) { control.id }
    let(:registration_id) { registration.id }

    context "with the lti_registrations_next feature flag enabled" do
      include_examples "navigation cache invalidation"

      it "updates the context control" do
        expect(control.available).to be true
        subject
        expect(control.reload.available).to be false
      end

      it "tracks the changes" do
        subject
        history_entry = Lti::RegistrationHistoryEntry.last

        expect(history_entry.diff["context_controls"]).to match_array(
          [["~", [control.id, "available"], true, false]]
        )

        expect(history_entry.old_context_controls[control.id.to_s]["available"]).to be true
        expect(history_entry.new_context_controls[control.id.to_s]["available"]).to be false
      end

      it "does not create a history entry when no changes are made" do
        # First update to set available to false
        put "/api/v1/accounts/#{account.id}/lti_registrations/#{registration_id}/controls/#{control_id}",
            params: { available: false }
        expect(control.reload.available).to be false

        # Try to update with the same value - should not create a history entry
        expect do
          put "/api/v1/accounts/#{account.id}/lti_registrations/#{registration_id}/controls/#{control_id}",
              params: { available: false }
        end.not_to change { Lti::RegistrationHistoryEntry.count }

        expect(response).to be_successful
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
    subject { delete "/api/v1/accounts/#{account.id}/lti_registrations/#{registration_id}/controls/#{control_id}" }

    let(:deployment) { deployment_for(account) }
    let(:course) { course_model(account:) }
    let(:control) { deployment.context_controls.create!(course:, registration:) }
    let(:registration_id) { registration.id }
    let(:control_id) { control.id }

    include_examples "navigation cache invalidation"

    it "deletes and returns the context control" do
      subject
      expect(control.reload).to be_deleted
      expect(response).to be_successful
    end

    it "tracks the changes" do
      subject
      expect(Lti::RegistrationHistoryEntry.last.diff["context_controls"]).to match_array(
        [["~", [control.id, "workflow_state"], "active", "deleted"]]
      )
    end

    context "with the deployment's primary control" do
      let(:control) { deployment.primary_context_control }

      it "returns a 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json["errors"]).to include("Cannot delete primary control for deployment")
      end

      it "does not delete the control" do
        control
        expect { subject }.not_to change { Lti::ContextControl.active.count }
        expect(control.reload).not_to be_deleted
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

    context "with the lti_registration_next flag disabled" do
      before { account.disable_feature!(:lti_registrations_next) }

      it "returns a 404 if the lti_registrations_next feature flag is disabled" do
        subject
        expect(response).to be_not_found
      end
    end
  end
end
