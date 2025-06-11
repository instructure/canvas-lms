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
      account:,
      course:,
      registration:,
      deployment:,
      available:,
    }
  end
  let(:course) { nil }
  let(:deployment) { external_tool_1_3_model(context: account) }
  let(:registration) do
    reg = lti_registration_model(account:)
    reg.ims_registration = lti_ims_registration_model(account:, lti_registration: reg)
    reg.developer_key = reg.ims_registration.developer_key
    reg
  end
  let(:available) { true }

  let_once(:account) { account_model }

  describe "validations" do
    context "when both account and course are present" do
      let(:course) { course_model(account:) }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /must have either an account or a course, not both/)
      end
    end

    context "when neither account nor course are present" do
      let(:account) { nil }
      let(:course) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /must have either an account or a course/)
      end
    end

    context "with only course" do
      let(:account) { nil }
      let(:course) { course_model(account:) }

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
      let(:deployment) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment must exist/)
      end
    end

    context "without registration" do
      let(:registration) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Registration must exist/)
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
  end

  describe "#destroy" do
    subject { control.destroy }

    let_once(:registration) do
      lti_registration_with_tool(account:)
    end
    let_once(:deployment) do
      registration.deployments.first
    end
    let_once(:control) do
      Lti::ContextControl.find_by(account:, registration:, deployment:)
    end

    it "soft-deletes the control" do
      expect { subject }.to change { control.reload.workflow_state }.from("active").to("deleted")
    end

    it "doesn't delete controls associated with other registrations" do
      other_registration = lti_registration_with_tool(account:)

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
            account: context.is_a?(Account) ? context : nil,
            course: context.is_a?(Course) ? context : nil,
            registration:,
            deployment:
          )
        end
      end

      it "soft-deletes the children as well" do
        subject

        expect(deployment.reload.context_controls.pluck(:workflow_state)).to all(eq("deleted"))
      end

      context "one of the child controls is already deleted" do
        before do
          controls.first.update!(workflow_state: "deleted")
        end

        it "still soft-deletes the other children" do
          subject
          expect(deployment.reload.context_controls.pluck(:workflow_state)).to all(eq("deleted"))
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

    before { control }

    it "is set on create" do
      expect(control.path).to eq("a#{account.id}.")
    end

    context "with nested contexts" do
      let(:account) { nil }
      let(:course) { course_model(account: account2) }
      let(:account2) { account_model(parent_account:) }
      let(:parent_account) { account_model }

      it "includes course and all accounts in chain" do
        expect(control.path).to eq("a#{parent_account.id}.a#{account2.id}.c#{course.id}.")
        expect(control.path).to eq(path_for(parent_account, account2, course))
      end
    end

    context "when account hierarchy changes" do
      let(:account) { account_model(parent_account:) }
      let(:parent_account) { account_model }
      let(:new_parent_account) { account_model }

      it "updates the path" do
        account.update!(parent_account: new_parent_account)
        expect(control.reload.path).to eq(path_for(new_parent_account, account))
      end

      context "with sibling accounts" do
        let(:sibling_account) { account_model(parent_account:) }

        it "does not change sibling control path" do
          sibling_control = create!(account: sibling_account)

          expect do
            account.update!(parent_account: new_parent_account)
          end.not_to change { sibling_control.reload.path }
        end
      end

      context "when new parent account is at higher level" do
        let(:account) { account_model(parent_account:) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          account.update!(parent_account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, account))
        end
      end

      context "when new parent account is at lower level" do
        let(:account) { account_model(parent_account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          account.update!(parent_account:)
          expect(control.reload.path).to eq(path_for(root_account, parent_account, account))
        end
      end
    end

    context "when course gets re-parented" do
      let(:account) { nil }
      let(:course) { course_model(account: parent_account) }
      let(:parent_account) { account_model }
      let(:new_parent_account) { account_model }

      it "updates the path" do
        course.update!(account: new_parent_account)
        expect(control.reload.path).to eq(path_for(new_parent_account, course))
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
        let(:root_account) { account_model }

        it "updates the path" do
          course.update!(account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, course))
        end
      end

      context "when new parent account is at lower level" do
        let(:account) { nil }
        let(:course) { course_model(account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

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
  end

  describe ".deployment_ids_for_context" do
    let_once(:dev_key) { create_dev_key_with_registration(root_account) }
    let_once(:registration) { dev_key.lti_registration }
    let_once(:tool) { registration.new_external_tool(root_account) }
    let_once(:root_account) { account_model }
    # This must always exist! TODO: when Paul's commit is merged, we can remove this,
    # as CETs will always create a control set to available wherever they're installed at.
    let_once(:root_control) { tool.context_controls.first }

    def create_dev_key_with_registration(account)
      lti_developer_key_model(account:).tap do |k|
        lti_tool_configuration_model(account: k.account, developer_key: k, lti_registration: k.lti_registration)
      end
    end

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
        let_once(:dev_key1) { create_dev_key_with_registration(root_account) }
        let_once(:dev_key2) { create_dev_key_with_registration(root_account) }
        let_once(:registration1) { dev_key1.lti_registration }
        let_once(:registration2) { dev_key2.lti_registration }
        let_once(:tool1) { registration1.new_external_tool(root_account) }
        let_once(:tool2) { registration2.new_external_tool(root_account) }

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
      let_once(:other_tool) { registration.new_external_tool(root_account) }

      it "returns both tools' ids" do
        expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to match_array([tool.id, other_tool.id])
      end

      context "one tool is marked as unavailable" do
        before(:once) do
          root_control.update!(available: false)
        end

        it "only returns the other tool's id" do
          expect(Lti::ContextControl.deployment_ids_for_context(root_account)).to eql([other_tool.id])
        end
      end
    end
  end

  describe ".nearest_control_for_registration" do
    let_once(:root_account) { account_model }
    let_once(:subaccount) { root_account.sub_accounts.create! }
    let_once(:course) { course_model(account: subaccount) }
    let_once(:tool) { registration.new_external_tool(root_account) }
    let_once(:developer_key) do
      lti_developer_key_model(account: root_account).tap do |k|
        lti_tool_configuration_model(developer_key: k, lti_registration: k.lti_registration)
      end
    end
    let_once(:registration) { developer_key.lti_registration }
    let_once(:root_account_control) { tool.context_controls.first }

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
      it "ignores the deleted control in a course and finds the subaccount control" do
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
        let_once(:subaccount_control) do
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
