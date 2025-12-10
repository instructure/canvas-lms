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

describe Lti::ContextControl do
  def create!(**overrides)
    described_class.create!(**params, **overrides)
  end

  let(:params) do
    {
      context: account || course,
      registration:,
      deployment:,
      available:,
    }
  end
  let(:course) { nil }
  let(:deployment) { registration.deployments.first }
  let(:registration) do
    lti_registration_with_tool(account: root_account)
  end
  let(:available) { true }
  let(:delete_controls) { true }
  let(:account) { root_account }

  let_once(:root_account) { account_model }

  before do
    # start with a blank slate
    if delete_controls
      registration&.context_controls&.each do |control|
        control.suspend_callbacks { control.destroy_permanently! }
      end
    end
  end

  describe "validations" do
    context "when neither account nor course are present" do
      let(:account) { nil }
      let(:course) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Exactly one context must be present/)
      end
    end

    context "with only course" do
      let(:account) { nil }
      let(:course) { course_model(account: root_account) }

      it "is valid" do
        expect { create! }.not_to raise_error
      end

      context "when deployment is not unique" do
        before { create! }

        it "is invalid" do
          expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment has already been taken/)
        end
      end

      context "when course changes" do
        let(:control) { create! }
        let(:new_course) { course_model(account:) }

        it "is invalid" do
          control.course = new_course
          expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
        end
      end
    end

    it "is valid" do
      expect { create! }.not_to raise_error
    end

    context "without deployment" do
      it "is invalid" do
        expect { create!(deployment: nil) }.to raise_error(ActiveRecord::RecordInvalid, /Deployment must exist/)
      end
    end

    context "without deployment link to registration" do
      before do
        deployment.lti_registration = nil
      end

      it "is invalid" do
        expect { create!(registration: nil) }.to raise_error(ActiveRecord::RecordInvalid, /Registration must exist/)
      end
    end

    context "without registration" do
      it "uses deployment to find registration" do
        expect { create!(registration: nil) }.not_to raise_error
      end
    end

    context "when deployment is not unique" do
      before { create! }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment has already been taken/)
      end
    end

    context "when account changes" do
      let(:control) { create! }
      let(:new_account) { account_model }

      it "is invalid" do
        control.account = new_account
        expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
      end
    end

    context "when path changes" do
      let(:control) { create! }
      let(:new_path) { "yolooooo" }

      it "is invalid" do
        control.path = new_path
        expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
      end
    end

    context "when context is outside deployment context chain" do
      let(:account) { account_model(parent_account: root_account) }
      let(:other_account) { account_model(parent_account: root_account) }
      let(:deployment) { registration.new_external_tool(account) }

      it "is invalid" do
        expect { create!(account: other_account) }.to raise_error(ActiveRecord::RecordInvalid, /must belong to the deployment's context/)
      end
    end
  end

  describe "#destroy" do
    subject { control.destroy }

    let_once(:parent_account) { account_model }
    let_once(:registration) do
      lti_registration_with_tool(account: parent_account)
    end
    let_once(:deployment) do
      registration.deployments.first
    end
    let_once(:account) { account_model(parent_account:) }
    let_once(:control) do
      Lti::ContextControl.create!(
        account:,
        registration:,
        deployment:
      )
    end
    let(:delete_controls) { false }

    it "soft-deletes the control" do
      expect { subject }.to change { control.reload.workflow_state }.from("active").to("deleted")
    end

    context "when control is primary for deployment" do
      let(:control) do
        Lti::ContextControl.find_by(account: parent_account, registration:, deployment:)
      end

      it "does not allow control deletion" do
        expect(subject).to be_falsey
        expect(control.reload.workflow_state).to eq("active")
        expect(control.errors[:base]).to include("Cannot delete primary control for deployment")
      end
    end

    it "doesn't delete controls associated with other registrations" do
      other_registration = lti_registration_with_tool(account: parent_account)

      subject
      expect(other_registration.reload.context_controls.where(workflow_state: "deleted").count).to eq(0)
    end

    it "doesn't delete controls associated with the same registration but different deployment" do
      other_deployment = registration.new_external_tool(account)

      subject

      expect(other_deployment.context_controls.where(workflow_state: "deleted").count).to eq(0)
    end

    context "with child controls" do
      let_once(:subaccount1) { account_model(parent_account: account) }
      let_once(:subaccount2) { account_model(parent_account: account) }
      let_once(:subsubaccount) { account_model(parent_account: subaccount1) }
      let_once(:course1) { course_model(account: subaccount1) }
      let_once(:course2) { course_model(account: subaccount2) }
      let_once(:subcourse) { course_model(account: subsubaccount) }
      let_once(:contexts) do
        [subaccount1, subaccount2, subsubaccount, course1, course2, subcourse]
      end
      let_once(:controls) do
        contexts.map do |context|
          Lti::ContextControl.create!(
            context:,
            registration:,
            deployment:
          )
        end
      end

      # exclude the primary control for the deployment which is not a child of `control`
      let(:children) { deployment.reload.context_controls.where.not(account: parent_account) }

      it "soft-deletes the children as well" do
        subject

        expect(children.pluck(:workflow_state)).to all(eq("deleted"))
      end

      context "one of the child controls is already deleted" do
        before do
          controls.first.update!(workflow_state: "deleted")
        end

        it "still soft-deletes the other children" do
          subject
          expect(children.pluck(:workflow_state)).to all(eq("deleted"))
        end

        it "doesn't try to update the already deleted control" do
          expect { subject }.not_to change { controls.first.reload.updated_at }
        end
      end
    end
  end

  describe "path" do
    def path_for(*contexts)
      contexts.map { |context| Lti::ContextControl.path_segment_for(context) }.join
    end

    let(:control) { create! }

    it "is set on create" do
      expect(control.path).to eq("a#{account.id}.")
    end

    context "with nested contexts" do
      let(:account) { nil }
      let(:course) { course_model(account: account2) }
      let(:account2) { account_model(parent_account: root_account) }

      it "includes course and all accounts in chain" do
        expect(control.path).to eq("a#{root_account.id}.a#{account2.id}.c#{course.id}.")
        expect(control.path).to eq(path_for(root_account, account2, course))
      end
    end

    context "when account hierarchy changes" do
      let(:control) { create!(account: subaccount) }
      let(:subaccount) { account_model(parent_account: account) }
      let(:new_sub_account) { account_model(parent_account: account) }

      before { control }

      it "updates the path" do
        subaccount.update!(parent_account: new_sub_account)
        expect(control.reload.path).to eq(path_for(account, new_sub_account, subaccount))
      end

      context "with sibling accounts" do
        let(:sibling_account) { account_model(parent_account: account) }

        it "does not change sibling control path" do
          sibling_control = create!(account: sibling_account)

          expect do
            subaccount.update!(parent_account: new_sub_account)
          end.not_to change { sibling_control.reload.path }
        end
      end

      context "when new parent account is at higher level" do
        let(:control) { create!(account:) }
        let(:account) { account_model(parent_account:) }
        let(:parent_account) { account_model(parent_account: root_account) }

        it "updates the path" do
          account.update!(parent_account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, account))
        end
      end

      context "when new parent account is at lower level" do
        let(:control) { create!(account:) }
        let(:account) { account_model(parent_account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }

        it "updates the path" do
          account.update!(parent_account:)
          expect(control.reload.path).to eq(path_for(root_account, parent_account, account))
        end
      end
    end

    context "when course gets re-parented" do
      let(:account) { nil }
      let(:course) { course_model(account: parent_account) }
      let(:parent_account) { account_model(parent_account: root_account) }
      let(:new_parent_account) { account_model(parent_account: root_account) }

      it "updates the path" do
        course.update!(account: new_parent_account)
        expect(control.reload.path).to eq(path_for(root_account, new_parent_account, course))
      end

      context "with sibling course" do
        let(:sibling_course) { course_model(account: parent_account) }

        it "does not change sibling control path" do
          sibling_control = create!(course: sibling_course)

          expect do
            course.update!(account: new_parent_account)
          end.not_to change { sibling_control.reload.path }
        end
      end

      context "when new parent account is at higher level" do
        let(:account) { nil }
        let(:course) { course_model(account: parent_account) }
        let(:parent_account) { account_model(parent_account: root_account) }

        it "updates the path" do
          course.update!(account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, course))
        end
      end

      context "when new parent account is at lower level" do
        let(:account) { nil }
        let(:course) { course_model(account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }

        it "updates the path" do
          course.update!(account: parent_account)
          expect(control.reload.path).to eq(path_for(root_account, parent_account, course))
        end
      end
    end
  end

  describe ".self_and_all_parent_paths" do
    it "returns the correct list of paths for a course in a subaccount" do
      subaccount = account.sub_accounts.create!
      course = course_model(account: subaccount)
      result = Lti::ContextControl.send(:self_and_all_parent_paths, course)
      expect(result).to eq([
                             "a#{account.id}.",
                             "a#{account.id}.a#{subaccount.id}.",
                             "a#{account.id}.a#{subaccount.id}.c#{course.id}.",
                           ])
    end

    it "handles being passed a bare path" do
      result = Lti::ContextControl.send(:self_and_all_parent_paths, "a1.a2.c3.")
      expect(result).to eq([
                             "a1.",
                             "a1.a2.",
                             "a1.a2.c3.",
                           ])
    end
  end

  describe ".deployment_ids_for_context" do
    let(:tool) { deployment }
    let(:root_control) { tool.primary_context_control }
    let(:delete_controls) { false }

    before { tool }

    it "finds the deployment in the account" do
      expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to eq([tool.id])
    end

    it "finds the deployment in a course within that account" do
      course = course_model(account: root_account)
      expect(Lti::ContextControl.deployment_ids_for_context(course)).to eq([tool.id])
    end

    context "when tool is disabled at the root account level" do
      before do
        root_control.update!(available: false)
      end

      it "returns empty array for any context" do
        course = course_model(account: root_account)
        subaccount = root_account.sub_accounts.create!
        subcourse = course_model(account: subaccount)

        expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to be_empty
        expect(Lti::ContextControl.deployment_ids_for_context(course)).to be_empty
        expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).to be_empty
        expect(Lti::ContextControl.deployment_ids_for_context(subcourse)).to be_empty
      end
    end

    context "with account hierarchy" do
      let_once(:subaccount) { root_account.sub_accounts.create! }
      let_once(:course) { course_model(account: subaccount) }

      context "with course-level overrides" do
        before do
          Lti::ContextControl.create!(account: subaccount, registration:, deployment: tool, available: false)
          Lti::ContextControl.create!(course:, registration:, deployment: tool, available: true)
        end

        it "uses course override when available" do
          expect(Lti::ContextControl.deployment_ids_for_context(course)).to match_array([tool.id])
        end

        it "respects account settings for the account itself" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).to be_empty
          expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to match_array([tool.id])
        end
      end

      context "with disabled root account and enabled subaccount" do
        before do
          root_control.update!(available: false)
          Lti::ContextControl.create!(
            account: subaccount,
            registration:,
            deployment: tool,
            available: true
          )
        end

        it "finds deployment in the subaccount with enabled deployment" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).to match_array([tool.id])
        end

        it "returns empty for the root account" do
          expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to be_empty
        end

        it "returns empty for other subaccounts" do
          subaccount2 = root_account.sub_accounts.create!
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount2)).to be_empty
        end
      end

      context "with multiple registrations across account hierarchy" do
        let_once(:registration1) { lti_registration_with_tool(account: root_account) }
        let_once(:registration2) { lti_registration_with_tool(account: root_account) }
        let_once(:tool1) { registration1.deployments.first }
        let_once(:tool2) { registration2.deployments.first }

        context "when registrations have different availability at different levels" do
          before(:once) do
            tool1.context_controls.find_by(account: root_account).update!(available: true)
            tool2.context_controls.find_by(account: root_account).update!(available: false)
            Lti::ContextControl.create!(account: subaccount, registration: registration2, deployment: tool2, available: true)
          end

          it "finds all tools in the course" do
            expect(Lti::ContextControl.deployment_ids_for_context(course))
              .to match_array([
                                tool.id,
                                tool1.id,
                                tool2.id
                              ])
          end

          it "doesn't find the disabled tool in the root account" do
            expect(Lti::ContextControl.deployment_ids_for_context(root_account))
              .to match_array([
                                tool.id,
                                tool1.id
                              ])
          end

          it "finds all tools in the subaccount" do
            expect(Lti::ContextControl.deployment_ids_for_context(subaccount))
              .to match_array([
                                tool.id,
                                tool1.id,
                                tool2.id
                              ])
          end

          context "and the context control for the subaccount is deleted" do
            before(:once) do
              Lti::ContextControl.find_by(account: subaccount, registration: registration2, deployment: tool2).destroy
            end

            it "doesn't find the tool in the subaccount" do
              expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).not_to include(tool2.id)
            end

            it "doesn't find the tool in the course" do
              expect(Lti::ContextControl.deployment_ids_for_context(course)).not_to include(tool2.id)
            end
          end
        end
      end
    end

    context "with multiple subaccounts" do
      let_once(:subaccount1) { root_account.sub_accounts.create! }
      let_once(:subaccount2) { root_account.sub_accounts.create! }

      context "with enabled root account and mixed subaccount settings" do
        before do
          Lti::ContextControl.create!(account: subaccount1, registration:, deployment: tool, available: false)
        end

        it "returns empty for subaccount with disabled registration" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount1)).to be_empty
        end

        it "inherits from root account for subaccount without explicit setting" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount2)).to match_array([tool.id])
        end

        context "with explicit available control in second subaccount" do
          before do
            Lti::ContextControl.create!(account: subaccount2, registration:, deployment: tool, available: true)
          end

          it "still returns registration for explicitly enabled subaccount" do
            expect(Lti::ContextControl.deployment_ids_for_context(subaccount2)).to match_array([tool.id])
          end
        end
      end

      context "with disabled root account and enabled subaccount" do
        before do
          root_control.update!(available: false)
          Lti::ContextControl.create!(account: subaccount1, registration:, deployment: tool, available: true)
        end

        it "returns registration for subaccount with enabled registration" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount1)).to match_array([tool.id])
        end

        it "returns empty for subaccount with no explicit setting" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount2)).to be_empty
        end
      end
    end

    context "with multiple deployments associated with the same registration" do
      let(:subaccount) { account_model(parent_account: root_account) }
      let(:other_tool) { registration.new_external_tool(subaccount) }

      before { other_tool }

      it "returns both tools' ids" do
        expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).to match_array([tool.id, other_tool.id])
      end

      context "one tool is marked as unavailable" do
        before do
          root_control.update!(available: false)
        end

        it "only returns the other tool's id" do
          expect(Lti::ContextControl.deployment_ids_for_context(subaccount)).to eql([other_tool.id])
        end
      end
    end
  end

  describe ".primary_controls_for" do
    subject { described_class.primary_controls_for(deployments:) }

    let(:deployment) { registration.deployments.first }
    let(:delete_controls) { false }
    let(:subdeployment) { registration.new_external_tool(subaccount) }
    let(:subaccount) { account_model(parent_account: root_account) }
    let(:course) { course_model(account: subaccount) }
    let(:course_deployment) { registration.new_external_tool(course) }
    let(:other_control) { Lti::ContextControl.create!(course:, registration:, deployment: subdeployment, available: true) }

    let(:deployments) { [deployment, subdeployment, course_deployment] }

    before do
      other_control
    end

    it "returns primary controls for each deployment" do
      controls = subject

      expect(controls.size).to eq(3)
      expect(controls.map(&:deployment_id)).to match_array(deployments.map(&:id))
      expect(controls.map(&:account_id)).to match_array([root_account.id, subaccount.id, nil])
      expect(controls.map(&:course_id)).to match_array([nil, nil, course.id])
    end

    context "with ids" do
      let(:deployments) { [deployment.id, subdeployment.id, course_deployment.id] }

      it "still returns primary controls for each deployment" do
        controls = subject

        expect(controls.size).to eq(3)
        expect(controls.map(&:deployment_id)).to match_array(deployments)
        expect(controls.map(&:account_id)).to match_array([root_account.id, subaccount.id, nil])
        expect(controls.map(&:course_id)).to match_array([nil, nil, course.id])
      end
    end
  end

  describe ".nearest_control_for_registration" do
    let(:subaccount) { root_account.sub_accounts.create! }
    let(:course) { course_model(account: subaccount) }
    let(:root_account_control) { tool.primary_context_control }
    let(:tool) { deployment }
    let(:delete_controls) { false }

    before do
      course
      tool
    end

    # Simple tests with control in specified context
    context "with direct context" do
      it "finds the control for root account context" do
        expect(Lti::ContextControl.nearest_control_for_registration(root_account, registration, tool))
          .to eq(root_account_control)
      end

      it "finds the control for subaccount context" do
        control = Lti::ContextControl.create!(
          account: subaccount,
          available: true,
          registration:,
          deployment: tool
        )
        expect(Lti::ContextControl.nearest_control_for_registration(subaccount, registration, tool))
          .to eq(control)
      end

      it "finds the control for course context" do
        control = Lti::ContextControl.create!(
          course:,
          available: true,
          registration:,
          deployment: tool
        )
        expect(Lti::ContextControl.nearest_control_for_registration(course, registration, tool))
          .to eq(control)
      end
    end

    context "and the context's control is deleted" do
      it "ignores the deleted control in a course and finds the root account control" do
        tool.context_controls.create!(
          course:,
          available: false,
          registration:,
          workflow_state: "deleted"
        )

        expect(Lti::ContextControl.nearest_control_for_registration(course, registration, tool))
          .to eq(root_account_control)
      end

      it "ignores the deleted control in a subaccount and finds the root account control" do
        tool.context_controls.create!(
          account: subaccount,
          available: false,
          registration:,
          workflow_state: "deleted"
        )

        expect(Lti::ContextControl.nearest_control_for_registration(subaccount, registration, tool))
          .to eq(root_account_control)
      end
    end

    # Tests for fallback behavior (when a context doesn't have its own control)
    context "when the context doesn't have it's own control" do
      it "finds root account control if context is subaccount" do
        expect(Lti::ContextControl.nearest_control_for_registration(subaccount, registration, tool))
          .to eq(root_account_control)
      end

      it "finds root account control if context is course" do
        expect(Lti::ContextControl.nearest_control_for_registration(course, registration, tool))
          .to eq(root_account_control)
      end

      context "with subaccount control" do
        let(:subaccount_control) do
          Lti::ContextControl.create!(
            account: subaccount,
            available: true,
            registration:,
            deployment: tool
          )
        end

        it "finds subaccount control if context is course" do
          subaccount_control
          expect(Lti::ContextControl.nearest_control_for_registration(course, registration, tool))
            .to eq(subaccount_control)
        end
      end
    end

    # Tests for special contexts (groups, assignments)
    context "with specialized contexts" do
      context "with group contexts" do
        it "uses the course control for a group in a course" do
          group = group_model(context: course)

          course_control = Lti::ContextControl.create!(
            course:,
            available: true,
            registration:,
            deployment: tool
          )

          expect(Lti::ContextControl.nearest_control_for_registration(group, registration, tool))
            .to eq(course_control)
        end

        it "uses the account control for a group in a course without a CC" do
          group = group_model(context: course)
          subaccount_control = Lti::ContextControl.create!(
            account: subaccount,
            available: true,
            registration:,
            deployment: tool
          )
          expect(Lti::ContextControl.nearest_control_for_registration(group, registration, tool))
            .to eq(subaccount_control)
        end

        it "uses the account control for a group in an account" do
          group = group_model(context: subaccount)

          subaccount_control = Lti::ContextControl.create!(
            account: subaccount,
            available: true,
            registration:,
            deployment: tool
          )

          expect(Lti::ContextControl.nearest_control_for_registration(group, registration, tool))
            .to eq(subaccount_control)
        end
      end

      context "with assignment context" do
        it "uses the course control for an assignment" do
          assignment = assignment_model(course:)

          course_control = Lti::ContextControl.create!(
            course:,
            available: true,
            registration:,
            deployment: tool
          )

          expect(Lti::ContextControl.nearest_control_for_registration(assignment, registration, tool))
            .to eq(course_control)
        end
      end
    end

    context "with duplicate tools" do
      let_once(:duplicate_tool) { registration.new_external_tool(root_account) }

      it "returns the control for the original tool, not the duplicate in the root account" do
        expect(Lti::ContextControl.nearest_control_for_registration(root_account, registration, tool))
          .to eql(root_account_control)
      end

      it "returns the control for the original tool, not the duplicate in the subaccount" do
        expect(Lti::ContextControl.nearest_control_for_registration(subaccount, registration, tool))
          .to eql(root_account_control)
      end

      it "returns the control for the original tool, not the duplicate in the course" do
        expect(Lti::ContextControl.nearest_control_for_registration(course, registration, tool))
          .to eql(root_account_control)
      end
    end
  end

  describe "#display_path" do
    let(:control) { create! }

    it "is empty for root account controls" do
      expect(control.display_path).to eq([])
    end

    context "with nested accounts" do
      let(:root_account) { account_model(name: "root") }
      let(:subaccount) { account_model(parent_account: root_account, name: "sub") }
      let(:account) { account_model(parent_account: subaccount, name: "account") }
      let(:control) { create! }

      it "only includes parent account names" do
        expect(control.display_path).to eq([subaccount.name])
      end
    end

    context "with course-level control" do
      let(:root_account) { account_model(name: "root") }
      let(:subaccount) { account_model(parent_account: root_account, name: "sub") }
      let(:course) { course_model(account: subaccount, name: "course") }
      let(:account) { nil }
      let(:control) { create! }

      it "does not include course name" do
        expect(control.display_path).to eq([subaccount.name])
      end
    end
  end

  describe "#subaccount_count" do
    let(:control) { create! }

    before do
      3.times do
        sub = account_model(parent_account: control.account)
        account_model(parent_account: sub)
      end
    end

    it "returns the number of all nested subaccounts" do
      expect(control.subaccount_count).to eq(6)
    end
  end

  describe "#course_count" do
    let(:control) { create! }

    before do
      3.times do
        sub = account_model(parent_account: control.account)
        course_model(account: control.account)
        course_model(account: sub)
      end
    end

    it "returns the number of all courses in account" do
      expect(control.course_count).to eq(6)
    end
  end

  describe "#child_control_count" do
    let(:control) { create! }

    before do
      3.times do
        sub = account_model(parent_account: control.account)
        create!(account: sub, deployment: control.deployment)
        create!(account: nil, course: course_model(account: sub), deployment: control.deployment)
      end
    end

    it "returns the number of all nested controls below this context" do
      expect(control.child_control_count).to eq(6)
    end
  end

  describe "self.calculate_path_for_course_id" do
    it "returns the correct path" do
      expect(described_class.calculate_path_for_course_id(123, [1, 2, 3]))
        .to eq("a3.a2.a1.c123.")
    end
  end

  describe "self.calculate_path_for_account_ids" do
    it "returns the correct path" do
      expect(described_class.calculate_path_for_account_ids([1, 2, 3]))
        .to eq("a3.a2.a1.")
    end
  end
end
