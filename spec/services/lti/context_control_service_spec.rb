# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Lti::ContextControlService do
  describe ".create_or_update" do
    subject do
      described_class.create_or_update(control_params)
    end

    # brings in a valid internal lti configuration
    include_context "lti_1_3_tool_configuration_spec_helper"

    let_once(:registration) do
      lti_tool_configuration_model(account: root_account).lti_registration
    end
    let_once(:root_account) { account_model }
    let_once(:account) { root_account }
    let_once(:course) { nil }
    let_once(:creating_user) { user_model }
    let_once(:editing_user) { user_model }
    let(:available) { true }
    let(:context_type) { "Account" }
    let(:workflow_state) { "active" }

    let(:deployment) do
      registration.new_external_tool(
        root_account,
        current_user: creating_user
      )
    end

    let(:control_params) do
      {
        root_account_id: root_account.id,
        account_id: account&.id,
        course_id: course&.id,
        registration_id: registration.id,
        deployment_id: deployment.id,
        created_by_id: editing_user.id,
        updated_by_id: editing_user.id,
        workflow_state:,
        available:,
      }
    end

    before do
      # intialize a deployment with a default control
      deployment
    end

    it "updates a soft-deleted control instead of creating a new one" do
      # Soft-delete the existing control
      control = deployment.primary_context_control
      control.workflow_state = "deleted"
      control.save!

      expect { subject }
        .to change { Lti::ContextControl.count }.by(1 - 1)
        .and change { Lti::ContextControl.active.count }.by(1)
      expect(control.reload.created_by_id).to eq(creating_user.id)
      expect(control.updated_by_id).to eq(editing_user.id)
    end

    context "when the course_id is provided" do
      let(:course) { course_model(account: root_account) }
      let(:account) { nil }

      it "creates a new control if no existing one is found" do
        expect { subject }.to change { Lti::ContextControl.active.count }.by(1)
      end
    end

    context "when params are invalid" do
      let(:course) { course_model(account: root_account) }
      let(:account) { account_model(parent_account: root_account) }

      it "raises an error with control validation messages" do
        expect { subject }.to raise_error(Lti::ContextControlErrors) do |error|
          expect(error.message).to include("Exactly one context must be present")
        end
      end
    end
  end

  describe ".build_anchor_control" do
    subject { described_class.build_anchor_control(deployment_id, account_id, course_id) }

    let(:registration) { lti_registration_with_tool(account: root_account) }
    let(:deployment_id) { deployment.id }
    let(:root_account) { account_model(name: "Root Account") }
    let(:subaccount) { account_model(name: "Subaccount", parent_account: root_account) }
    let(:account_id) { subaccount.id }
    let(:course_id) { nil }
    let(:deployment) { registration.deployments.first }

    context "without required parameters" do
      it "returns nil if no account_id or course_id is provided" do
        expect(described_class.build_anchor_control(deployment_id, nil, nil)).to be_nil
      end
    end

    context "when the deployment is a course-level deployment" do
      let(:course) { course_model(account: root_account) }
      let(:deployment) { registration.new_external_tool(course) }
      let(:account_id) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when the control is for the deployment's context" do
      let(:account_id) { root_account.id }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when control is for direct child of deployment's context" do
      let(:account_id) { subaccount.id }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when control is for a deeper subaccount" do
      let(:sub_subaccount) { account_model(name: "Sub Subaccount", parent_account: subaccount) }
      let(:account_id) { sub_subaccount.id }

      it "returns a new Lti::ContextControl with the correct attributes" do
        anchor_control = subject
        expect(anchor_control).to be_a(Lti::ContextControl)
        expect(anchor_control.account_id).to eq(subaccount.id)
        expect(anchor_control.deployment_id).to eq(deployment_id)
        expect(anchor_control.available).to eq(deployment.primary_context_control.available)
      end
    end

    context "when control is for a root course" do
      let(:course) { course_model(account: root_account) }
      let(:course_id) { course.id }
      let(:account_id) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when control is for a subaccount course right below deployment" do
      let(:course) { course_model(account: subaccount) }
      let(:course_id) { course.id }
      let(:account_id) { nil }
      let(:deployment) { registration.new_external_tool(subaccount) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when control is for a deep course" do
      let(:course) { course_model(account: subaccount) }
      let(:course_id) { course.id }
      let(:account_id) { nil }

      it "returns a new Lti::ContextControl with the correct attributes" do
        anchor_control = subject
        expect(anchor_control).to be_a(Lti::ContextControl)
        expect(anchor_control.account_id).to eq(subaccount.id)
        expect(anchor_control.deployment_id).to eq(deployment_id)
        expect(anchor_control.available).to eq(deployment.primary_context_control.available)
      end

      context "when anchor control already exists" do
        let(:anchor_control) { Lti::ContextControl.create!(deployment:, account: subaccount) }

        before { anchor_control }

        it "returns nil and does not create another" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe ".build_anchor_controls" do
    subject do
      described_class.build_anchor_controls(
        controls:,
        account_chains:,
        course_account_ids:,
        deployments: [deployment.id],
        deployment_account_ids:,
        deployment_course_ids:,
        cached_paths:
      )
    end

    let_once(:root_account) { account_model(name: "Root Account") }
    let_once(:registration) { lti_registration_with_tool(account: root_account) }
    let_once(:subaccount) { account_model(name: "Subaccount", parent_account: root_account) }
    let_once(:other_subaccount) { account_model(name: "Other Subaccount", parent_account: root_account) }
    let_once(:subsubaccount) { account_model(name: "Sub Subaccount", parent_account: subaccount) }
    let_once(:subsubsubaccount) { account_model(name: "Sub Sub Subaccount", parent_account: subsubaccount) }
    let_once(:subsubaccount_course) { course_model(account: subsubaccount) }
    let_once(:subaccount_course) { course_model(account: subaccount) }
    let_once(:other_subaccount_course) { course_model(account: other_subaccount) }
    let_once(:course) { course_model(account: root_account) }
    let_once(:subaccount_deployment) { registration.new_external_tool(subaccount) }
    let_once(:course_deployment) { registration.new_external_tool(course) }
    let_once(:deployment) { registration.deployments.first }

    let(:controls) { [] }

    # these "preloaded" values are constructed either by
    # .build_anchor_control or by the controller's create_many endpoint
    let_once(:account_chains) do
      {
        root_account.id => [root_account.id],
        subaccount.id => [subaccount.id, root_account.id],
        other_subaccount.id => [other_subaccount.id, root_account.id],
        subsubaccount.id => [subsubaccount.id, subaccount.id, root_account.id],
        subsubsubaccount.id => [subsubsubaccount.id, subsubaccount.id, subaccount.id, root_account.id]
      }
    end
    let_once(:course_account_ids) do
      {
        course.id => root_account.id,
        subaccount_course.id => subaccount.id,
        other_subaccount_course.id => other_subaccount.id,
        subsubaccount_course.id => subsubaccount.id
      }
    end
    let_once(:deployment_account_ids) do
      {
        deployment.id => root_account.id,
        subaccount_deployment.id => subaccount.id
      }
    end
    let_once(:deployment_course_ids) do
      {
        course_deployment.id => course.id
      }
    end
    let_once(:cached_paths) do
      {
        "#a{root_account.id}" => Lti::ContextControl.calculate_path_for_account_ids(account_chains[root_account.id]),
        "#a{subaccount.id}" => Lti::ContextControl.calculate_path_for_account_ids(account_chains[subaccount.id]),
        "#a{other_subaccount.id}" => Lti::ContextControl.calculate_path_for_account_ids(account_chains[other_subaccount.id]),
        "#a{subsubaccount.id}" => Lti::ContextControl.calculate_path_for_account_ids(account_chains[subsubaccount.id]),
        "#a{subsubsubaccount.id}" => Lti::ContextControl.calculate_path_for_account_ids(account_chains[subsubsubaccount.id])
      }
    end

    context "control is for account where root deployment lives" do
      let(:controls) { [{ account_id: root_account.id, deployment_id: deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for account where subaccount deployment lives" do
      let(:controls) { [{ account_id: subaccount.id, deployment_id: subaccount_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for direct child account of deployment context" do
      let(:controls) { [{ account_id: subsubaccount.id, deployment_id: subaccount_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for direct child course of deployment context" do
      let(:controls) { [{ course_id: subaccount_course.id, deployment_id: subaccount_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for course where deployment lives" do
      let(:controls) { [{ course_id: course.id, deployment_id: course_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for course outside deployment context chain" do
      let(:controls) { [{ course_id: other_subaccount_course.id, deployment_id: subaccount_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for account outside deployment context chain" do
      let(:controls) { [{ account_id: other_subaccount.id, deployment_id: subaccount_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for course that is not deployment course" do
      let(:controls) { [{ course_id: other_subaccount_course.id, deployment_id: course_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for account but deployment lives in course" do
      let(:controls) { [{ account_id: subaccount.id, deployment_id: course_deployment.id }] }

      it "does not need an anchor" do
        expect(subject).to be_empty
      end
    end

    context "control is for deep subaccount of subaccount deployment" do
      let(:controls) { [{ account_id: subsubsubaccount.id, deployment_id: subaccount_deployment.id }] }

      it "creates an anchor control for the first child of deployment context" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subsubaccount.id)
        expect(anchor_params[:deployment_id]).to eq(subaccount_deployment.id)
        expect(anchor_params[:available]).to eq(subaccount_deployment.primary_context_control.available)
      end
    end

    context "control is for deep course of subaccount deployment" do
      let(:controls) { [{ course_id: subsubaccount_course.id, deployment_id: subaccount_deployment.id }] }

      it "creates an anchor control for the first child of deployment context" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subsubaccount.id)
        expect(anchor_params[:deployment_id]).to eq(subaccount_deployment.id)
        expect(anchor_params[:available]).to eq(subaccount_deployment.primary_context_control.available)
      end
    end

    context "control is for deep subaccount of root deployment" do
      let(:controls) { [{ account_id: subsubsubaccount.id, deployment_id: deployment.id }] }

      it "creates an anchor control for the first child of deployment context" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subaccount.id)
        expect(anchor_params[:deployment_id]).to eq(deployment.id)
        expect(anchor_params[:available]).to eq(deployment.primary_context_control.available)
      end
    end

    context "control is for deep course of root deployment" do
      let(:controls) { [{ course_id: subsubaccount_course.id, deployment_id: deployment.id }] }

      it "creates an anchor control for the first child of deployment context" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subaccount.id)
        expect(anchor_params[:deployment_id]).to eq(deployment.id)
        expect(anchor_params[:available]).to eq(deployment.primary_context_control.available)
      end
    end

    context "anchor control already exists" do
      let(:anchor_control) do
        Lti::ContextControl.create!(
          deployment:,
          account: subaccount,
          available: deployment.primary_context_control.available
        )
      end
      let(:controls) { [{ course_id: subsubaccount_course.id, deployment_id: deployment.id }] }

      before { anchor_control }

      it "filters out the anchor control since it already exists" do
        # We don't touch anchors that already exist, to avoid overwriting their
        # already set availability.
        expect(subject.length).to eq 0
      end
    end

    context "multiple controls with one needing anchor" do
      let(:controls) do
        [
          { account_id: other_subaccount.id, deployment_id: deployment.id }, # no anchor needed
          { account_id: subsubaccount.id, deployment_id: deployment.id }
        ]
      end

      it "creates an anchor control for the one that needs it" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subaccount.id)
        expect(anchor_params[:deployment_id]).to eq(deployment.id)
        expect(anchor_params[:available]).to eq(deployment.primary_context_control.available)
      end
    end

    context "multiple controls with multiple needing anchors" do
      let(:controls) do
        [
          { account_id: subsubaccount.id, deployment_id: deployment.id }, # needs anchor
          { course_id: other_subaccount_course.id, deployment_id: deployment.id } # needs anchor
        ]
      end

      it "creates an anchor control for each that needs it" do
        expect(subject.length).to eq 2
        first_anchor = subject.find { |params| params[:account_id] == subaccount.id }
        expect(first_anchor).not_to be_nil
        expect(first_anchor[:deployment_id]).to eq(deployment.id)
        expect(first_anchor[:available]).to eq(deployment.primary_context_control.available)
        second_anchor = subject.find { |params| params[:account_id] == other_subaccount.id }
        expect(second_anchor).not_to be_nil
        expect(second_anchor[:deployment_id]).to eq(deployment.id)
        expect(second_anchor[:available]).to eq(deployment.primary_context_control.available)
      end
    end

    context "multiple controls that all need the same anchor control" do
      let(:controls) do
        [
          { course_id: subaccount_course.id, deployment_id: deployment.id },
          { course_id: subaccount_other_course.id, deployment_id: deployment.id }
        ]
      end
      let(:subaccount_other_course) { course_model(account: subaccount) }
      let(:course_account_ids) do
        ac = super()
        ac[subaccount_other_course.id] = subaccount.id
        ac
      end

      it "creates a single anchor control" do
        expect(subject).to eq([
                                {
                                  account_id: subaccount.id,
                                  course_id: nil,
                                  path: "a#{root_account.id}.a#{subaccount.id}.",
                                  deployment_id: deployment.id,
                                  available: deployment.primary_context_control.available
                                }.with_indifferent_access
                              ])
      end
    end

    context "multiple controls that include primary control" do
      let(:controls) do
        [
          { account_id: subsubaccount.id, deployment_id: deployment.id }, # needs anchor
          # primary deployment control, but with different availability
          { account_id: deployment.context_id, deployment_id: deployment.id, available: !deployment.primary_context_control.available }
        ]
      end

      it "uses new primary control available setting for anchor" do
        expect(subject.length).to eq 1
        anchor_params = subject.first
        expect(anchor_params[:account_id]).to eq(subaccount.id)
        expect(anchor_params[:deployment_id]).to eq(deployment.id)
        expect(anchor_params[:available]).to eq(!deployment.primary_context_control.available)
      end
    end

    context "multiple controls that includes anchor control" do
      let(:controls) do
        [
          { account_id: subaccount.id, deployment_id: deployment.id }, # anchor
          { account_id: subsubaccount.id, deployment_id: deployment.id }
        ]
      end

      it "does not try to create anchor again" do
        expect(subject).to be_empty
      end
    end

    context "when anchor control already exists" do
      let(:existing_anchor_control) do
        Lti::ContextControl.create!(
          deployment:,
          account: subaccount,
          available: false
        )
      end

      let(:controls) do
        [
          { account_id: subsubaccount.id, deployment_id: deployment.id, available: true }
        ]
      end

      it "does not try to create an anchor control there" do
        existing_anchor_control
        expect(subject).to be_empty
      end
    end

    context "when creating multiple nested controls where some anchors exist and some don't" do
      # This test ensures that when multiple nested controls need anchors, and some of those
      # anchors already exist, we:
      # 1. Preserve the existing anchor control's availability
      # 2. Still create the new anchor control that doesn't exist yet
      # 3. Give the new anchor control the correct availability from deployment

      let(:existing_anchor_control) do
        Lti::ContextControl.create!(
          deployment:,
          account: subaccount,
          available: false
        )
      end

      let(:controls) do
        [
          # This needs an anchor at (subaccount, deployment) - exists with available: false
          { account_id: subsubaccount.id, deployment_id: deployment.id, available: true },
          # This needs an anchor at (other_subaccount, deployment) - DOES NOT EXIST
          { course_id: other_subaccount_course.id, deployment_id: deployment.id, available: true }
        ]
      end

      it "filters out existing anchor but returns new anchor with deployment availability" do
        existing_anchor_control
        expect(subject.length).to eq(1)

        anchor_1 = subject.find { |a| a[:account_id] == subaccount.id && a[:deployment_id] == deployment.id }
        expect(anchor_1).to be_nil

        anchor_2 = subject.find { |a| a[:account_id] == other_subaccount.id && a[:deployment_id] == deployment.id }
        expect(anchor_2).not_to be_nil
        expect(anchor_2[:available]).to eq(deployment.primary_context_control.available),
                                        "Expected new anchor (#{other_subaccount.id}, #{deployment.id}) to use deployment availability"
      end
    end
  end

  describe ".preload_calculated_attrs" do
    subject do
      described_class.preload_calculated_attrs(controls)
    end

    let_once(:registration) do
      lti_tool_configuration_model(account: root_account).lti_registration
    end
    let_once(:root_account) { account_model(name: "root") }
    let_once(:account) { root_account }
    let_once(:deployment) do
      registration.new_external_tool(root_account)
    end

    context "with no controls" do
      let(:controls) { [] }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "with course-level control" do
      let(:course) { course_model(account: root_account) }
      let(:control) { Lti::ContextControl.create!(registration:, deployment:, course:) }
      let(:controls) { [control] }

      it "does not have subaccounts" do
        expect(subject.dig(control.id, :subaccount_count)).to eq 0
      end

      it "does not affect any courses" do
        expect(subject.dig(control.id, :course_count)).to eq 0
      end

      it "does not have child controls" do
        expect(subject.dig(control.id, :child_control_count)).to eq 0
      end

      it "has the correct depth" do
        expect(subject.dig(control.id, :depth)).to eq 1
      end

      it "has the correct display path" do
        expect(subject.dig(control.id, :display_path)).to eq []
      end

      it "has the context name" do
        expect(subject.dig(control.id, :context_name)).to eq(course.name)
      end
    end

    context "with one account-level control" do
      let(:control) { deployment.primary_context_control }
      let(:controls) { [control] }

      before do
        course_model(account:)
        subaccount = account_model(name: "Subaccount", parent_account: account)
        sub_course = course_model(account: subaccount)
        Lti::ContextControl.create!(registration:, deployment:, account: subaccount)
        Lti::ContextControl.create!(registration:, deployment:, course: sub_course)
      end

      it "correctly counts subaccounts" do
        expect(subject.dig(control.id, :subaccount_count)).to eq 1
      end

      it "correctly counts courses in all subaccounts" do
        expect(subject.dig(control.id, :course_count)).to eq 2
      end

      it "correctly counts child controls" do
        expect(subject.dig(control.id, :child_control_count)).to eq 2
      end

      it "has a depth of 0" do
        expect(subject.dig(control.id, :depth)).to eq 0
      end

      it "has the account's name" do
        expect(subject.dig(control.id, :context_name)).to eq(account.name)
      end
    end

    context "with multiple account-level controls" do
      let(:control1) { deployment.primary_context_control }
      let(:subaccount) { account_model(name: "Subaccount", parent_account: account) }
      let(:control2) { Lti::ContextControl.create!(registration:, deployment:, account: subaccount) }
      let(:subaccount2) { account_model(name: "Subaccount 2", parent_account: account) }
      let(:deployment2) { registration.new_external_tool(subaccount2) }
      let(:control3) { deployment2.primary_context_control }
      let(:controls) { [control1, control2, control3] }

      before do
        course_model(account:)
        sub_course = course_model(account: subaccount)
        Lti::ContextControl.create!(registration:, deployment:, course: sub_course)
        sub3 = account_model(name: "Subaccount 3", parent_account: subaccount2)
        sub4 = account_model(name: "Subaccount 4", parent_account: sub3)
        sub5 = account_model(name: "Subaccount 5", parent_account: sub4)
        Lti::ContextControl.create!(registration:, deployment: deployment2, account: sub5)

        sub2_course = course_model(account: subaccount2)
        Lti::ContextControl.create!(registration:, deployment: deployment2, course: sub2_course)
      end

      it "correctly counts subaccounts for all controls" do
        expect(subject.dig(control1.id, :subaccount_count)).to eq 5
        expect(subject.dig(control2.id, :subaccount_count)).to eq 0
        expect(subject.dig(control3.id, :subaccount_count)).to eq 3
      end

      it "correctly counts courses in all subaccounts for all controls" do
        expect(subject.dig(control1.id, :course_count)).to eq 3
        expect(subject.dig(control2.id, :course_count)).to eq 1
        expect(subject.dig(control3.id, :course_count)).to eq 1
      end

      it "correctly counts child controls for all controls" do
        expect(subject.dig(control1.id, :child_control_count)).to eq 2
        expect(subject.dig(control2.id, :child_control_count)).to eq 1
        expect(subject.dig(control3.id, :child_control_count)).to eq 2
      end

      it "matches counts calculated by individual controls" do
        expect(subject.dig(control1.id, :subaccount_count)).to eq control1.subaccount_count
        expect(subject.dig(control1.id, :course_count)).to eq control1.course_count
        expect(subject.dig(control1.id, :child_control_count)).to eq control1.child_control_count
        expect(subject.dig(control2.id, :subaccount_count)).to eq control2.subaccount_count
        expect(subject.dig(control2.id, :course_count)).to eq control2.course_count
        expect(subject.dig(control2.id, :child_control_count)).to eq control2.child_control_count
        expect(subject.dig(control3.id, :subaccount_count)).to eq control3.subaccount_count
        expect(subject.dig(control3.id, :course_count)).to eq control3.course_count
        expect(subject.dig(control3.id, :child_control_count)).to eq control3.child_control_count
      end

      it "finds the depth for all controls" do
        expect(subject.dig(control1.id, :depth)).to eq 0
        expect(subject.dig(control2.id, :depth)).to eq 1
        expect(subject.dig(control3.id, :depth)).to eq 0
      end

      it "finds the display path for all controls" do
        expect(subject.dig(control1.id, :display_path)).to eq []
        expect(subject.dig(control2.id, :display_path)).to eq []
        expect(subject.dig(control3.id, :display_path)).to eq []
      end

      it "finds the context name for all controls" do
        # These are all preloaded, so should match directly
        expect(subject.dig(control1.id, :context_name)).to eq(control1.context_name)
        expect(subject.dig(control2.id, :context_name)).to eq(control2.context_name)
        expect(subject.dig(control3.id, :context_name)).to eq(control3.context_name)
      end
    end

    context "with nested subaccounts that lack controls" do
      let!(:control) { deployment.primary_context_control }
      # subaccount lacks a CC
      let!(:subaccount) { account_model(name: "Subaccount", parent_account: account) }
      # subaccount_2, inside of subaccount, also lacks a CC
      let!(:subaccount_2) { account_model(name: "Subaccount 2", parent_account: subaccount) }
      # subaccount_3, inside of subaccount_2, *has* a CC
      let!(:subaccount_3) do
        account_model(name: "Subaccount 3", parent_account: subaccount_2)
      end
      let!(:subaccount_3_control) do
        Lti::ContextControl.create!(registration:, deployment:, account: subaccount_3)
      end

      let!(:subaccount_3_course) { course_model(account: subaccount_3) }
      let!(:subaccount_3_course_control) do
        Lti::ContextControl.create!(registration:, deployment:, course: subaccount_3_course)
      end

      let(:controls) { [control, subaccount_3_control, subaccount_3_course_control] }

      it "finds the correct depths" do
        expect(subject.dig(control.id, :depth)).to eq 0
        expect(subject.dig(subaccount_3_control.id, :depth)).to eq 1
        expect(subject.dig(subaccount_3_course_control.id, :depth)).to eq 2
      end

      it "finds the correct display paths" do
        expect(subject.dig(control.id, :display_path)).to eq []
        expect(subject.dig(subaccount_3_control.id, :display_path)).to eq [subaccount.name, subaccount_2.name]
        expect(subject.dig(subaccount_3_course_control.id, :display_path)).to eq [subaccount.name, subaccount_2.name, subaccount_3.name]
      end
    end
  end
end
