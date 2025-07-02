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
      control = deployment.context_controls.first
      control.workflow_state = "deleted"
      control.save!

      expect { subject }
        .to change { Lti::ContextControl.count }.by(1 - 1)
        .and change { Lti::ContextControl.active.count }.by(1)
      expect(control.reload.created_by_id).to eq(creating_user.id)
      expect(control.updated_by_id).to eq(editing_user.id)
    end

    context "when the course_id is provided" do
      let(:course) { course_model }
      let(:account) { nil }

      it "creates a new control if no existing one is found" do
        expect { subject }.to change { Lti::ContextControl.active.count }.by(1)
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
    end

    context "with one account-level control" do
      let(:control) { deployment.context_controls.first }
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
    end

    context "with multiple account-level controls" do
      let(:control1) { deployment.context_controls.first }
      let(:subaccount) { account_model(name: "Subaccount", parent_account: account) }
      let(:control2) { Lti::ContextControl.create!(registration:, deployment:, account: subaccount) }
      let(:subaccount2) { account_model(name: "Subaccount 2", parent_account: account) }
      let(:deployment2) { registration.new_external_tool(subaccount2) }
      let(:control3) { deployment2.context_controls.first }
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
    end

    context "with nested subaccounts that lack controls" do
      let!(:control) { deployment.context_controls.first }
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
