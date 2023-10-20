# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe AssignmentUtil do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "a student")
  end

  let(:assignment) do
    @course.assignments.create!(assignment_valid_attributes)
  end

  let(:assignment_name_length_value) { 15 }

  def account_stub_helper(assignment, require_due_date, sis_syncing, new_sis_integrations)
    allow(assignment.context.account).to receive_messages(
      sis_require_assignment_due_date: { value: require_due_date },
      sis_syncing: { value: sis_syncing }
    )
    allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(new_sis_integrations)
  end

  def due_date_required_helper(assignment, post_to_sis, require_due_date, sis_syncing, new_sis_integrations)
    assignment.post_to_sis = post_to_sis
    account_stub_helper(assignment, require_due_date, sis_syncing, new_sis_integrations)
  end

  describe "due_date_required?" do
    it "returns true when all 4 are set to true" do
      due_date_required_helper(assignment, true, true, true, true)
      expect(described_class.due_date_required?(assignment)).to be(true)
    end

    it "returns false when post_to_sis is false" do
      due_date_required_helper(assignment, false, true, true, true)
      expect(described_class.due_date_required?(assignment)).to be(false)
    end

    it "returns false when sis_require_assignment_due_date is false" do
      due_date_required_helper(assignment, true, false, true, true)
      expect(described_class.due_date_required?(assignment)).to be(false)
    end

    it "returns false when sis_syncing is false" do
      due_date_required_helper(assignment, true, true, false, true)
      expect(described_class.due_date_required?(assignment)).to be(false)
    end

    it "returns false when new_sis_integrations is false" do
      due_date_required_helper(assignment, true, true, true, false)
      expect(described_class.due_date_required?(assignment)).to be(false)
    end
  end

  describe "due_date_required_for_account?" do
    it "returns true when all 3 are set to true" do
      account_stub_helper(assignment, true, true, true)
      expect(described_class.due_date_required_for_account?(assignment.context)).to be(true)
    end

    it "returns false when sis_require_assignment_due_date is false" do
      account_stub_helper(assignment, false, true, true)
      expect(described_class.due_date_required_for_account?(assignment.context)).to be(false)
    end

    it "returns false when sis_syncing is false" do
      account_stub_helper(assignment, true, false, true)
      expect(described_class.due_date_required_for_account?(assignment.context)).to be(false)
    end

    it "returns false when new_sis_integrations is false" do
      account_stub_helper(assignment, true, true, false)
      expect(described_class.due_date_required_for_account?(assignment.context)).to be(false)
    end
  end

  describe "assignment_max_name_length" do
    it "returns 15 when the account setting sis_assignment_name_length_input is 15" do
      allow(assignment.context.account).to receive(:sis_assignment_name_length_input).and_return({ value: 15 })
      expect(described_class.assignment_max_name_length(assignment.context)).to eq(15)
    end
  end

  describe "post_to_sis_friendly_name" do
    it "returns custom friendly name when the account setting sis_name is custom" do
      assignment.context.account.root_account.settings[:sis_name] = "Foo Bar"
      expect(described_class.post_to_sis_friendly_name(assignment.context)).to eq("Foo Bar")
    end

    it "returns SIS when the account setting sis_name is not custom" do
      expect(described_class.post_to_sis_friendly_name(assignment.context)).to eq("SIS")
    end
  end

  describe "due_date_ok?" do
    it "returns false when due_at is blank and due_date_required? is true" do
      assignment.due_at = nil
      allow(described_class).to receive(:due_date_required?).with(assignment).and_return(true)
      expect(described_class.due_date_ok?(assignment)).to be(false)
    end

    it "returns true when due_at is blank, due_date_required? is true and grading_type is not_graded" do
      assignment.due_at = nil
      assignment.grading_type = "not_graded"
      allow(described_class).to receive(:due_date_required?).with(assignment).and_return(true)
      expect(described_class.due_date_ok?(assignment)).to be(true)
    end

    it "returns true when due_at is present and due_date_required? is true" do
      assignment.due_at = Time.zone.now
      allow(described_class).to receive(:due_date_required?).with(assignment).and_return(true)
      expect(described_class.due_date_ok?(assignment)).to be(true)
    end

    it "returns true when due_at is present and due_date_required? is false" do
      assignment.due_at = Time.zone.now
      allow(described_class).to receive(:due_date_required?).with(assignment).and_return(false)
      expect(described_class.due_date_ok?(assignment)).to be(true)
    end

    it "returns true when due_at is not present and due_date_required? is false" do
      assignment.due_at = nil
      allow(described_class).to receive(:due_date_required?).with(assignment).and_return(false)
      expect(described_class.due_date_ok?(assignment)).to be(true)
    end
  end

  describe "sis_integration_settings_enabled?" do
    it "returns true when new_sis_integrations fetaure enabled" do
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(true)
      expect(described_class.sis_integration_settings_enabled?(assignment.context)).to be(true)
    end

    it "returns false when new_sis_integrations fetaure enabled" do
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(false)
      expect(described_class.sis_integration_settings_enabled?(assignment.context)).to be(false)
    end
  end

  describe "assignment_name_length_required?" do
    it "returns true when all 4 are set to true" do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive_messages(
        sis_syncing: { value: true },
        sis_assignment_name_length: { value: true }
      )
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(true)
      expect(described_class.assignment_name_length_required?(assignment)).to be(true)
    end

    it "returns false when sis_sycning is set to false" do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive_messages(
        sis_syncing: { value: false },
        sis_assignment_name_length: { value: true }
      )
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(true)
      expect(described_class.assignment_name_length_required?(assignment)).to be(false)
    end

    it "returns false when post_to_sis is false" do
      assignment.post_to_sis = false
      allow(assignment.context.account).to receive_messages(
        sis_syncing: { value: true },
        sis_assignment_name_length: { value: true }
      )
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(true)
      expect(described_class.assignment_name_length_required?(assignment)).to be(false)
    end

    it "returns false when sis_assignment_name_length is false" do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive_messages(
        sis_syncing: { value: false },
        sis_assignment_name_length: { value: false }
      )
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(true)
      expect(described_class.assignment_name_length_required?(assignment)).to be(false)
    end

    it "returns false when new_sis_integrations is false" do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive_messages(
        sis_syncing: { value: false },
        sis_assignment_name_length: { value: true }
      )
      allow(assignment.context.account).to receive(:feature_enabled?).with("new_sis_integrations").and_return(false)
      expect(described_class.assignment_name_length_required?(assignment)).to be(false)
    end
  end

  describe "process_due_date_reminder" do
    let(:submission_for) do
      lambda do |user|
        Submission.find_by(assignment_id: assignment.id, user_id: user.id)
      end
    end

    it "alerts students who have not submitted" do
      expect(described_class).to receive(:alert_unaware_student).with(anything, assignment:, submission: submission_for[@student])

      described_class.process_due_date_reminder("Assignment", assignment.id)
    end

    it "does not alert students who have seen the assignment within the last 3 days" do
      expect(described_class).not_to receive(:alert_unaware_student)

      AssetUserAccess.create!({
                                asset_category: "assignments",
                                asset_code: assignment.asset_string,
                                context: @course,
                                last_access: 1.day.ago,
                                user_id: @student,
                              })

      described_class.process_due_date_reminder("Assignment", assignment.id)
    end

    it "alerts students who have not submitted, even if they have seen the assignment sometime in the past" do
      expect(described_class).to receive(:alert_unaware_student)

      AssetUserAccess.create!({
                                asset_category: "assignments",
                                asset_code: assignment.asset_string,
                                context: @course,
                                last_access: 4.days.ago,
                                user_id: @student,
                              })

      described_class.process_due_date_reminder("Assignment", assignment.id)
    end

    it "does not notify students in other sections" do
      section_a = @course.course_sections.create!
      section_a_user_1 = student_in_course(active_all: true, section: section_a).student
      section_a_user_2 = student_in_course(active_all: true, section: section_a).student
      section_a_ao = create_section_override_for_assignment(assignment, course_section: section_a)

      section_b = @course.course_sections.create!
      student_in_course(active_all: true, section: section_b).student
      create_section_override_for_assignment(assignment, course_section: section_b)

      expect(described_class).to receive(:alert_unaware_student).with(anything, assignment:, submission: submission_for[section_a_user_1])

      expect(described_class).to receive(:alert_unaware_student).with(anything, assignment:, submission: submission_for[section_a_user_2])

      described_class.process_due_date_reminder(section_a_ao.class.name, section_a_ao.id)
    end

    it "does nothing if assignment could not be found" do
      expect(described_class).not_to receive(:alert_unaware_student)
      described_class.process_due_date_reminder("Assignment", "asdfasdf")
    end

    it "does nothing if assignment override could not be found" do
      expect(described_class).not_to receive(:alert_unaware_student)
      described_class.process_due_date_reminder("AssignmentOverride", "asdfasdf")
    end

    it "does nothing if assignment has no due date" do
      expect(described_class).not_to receive(:alert_unaware_student)
      assignment.update_attribute(:due_at, nil)
      described_class.process_due_date_reminder("Assignment", assignment.id)
    end

    it "actually alerts the student" do
      notification = Notification.create!(name: "Upcoming Assignment Alert", category: "TestImmediately")

      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        assignment,
        notification.name,
        notification,
        [@student],
        hash_including(
          assignment_due_date: Submission.find_by(
            assignment_id: assignment.id,
            user_id: @student.id
          ).cached_due_date
        )
      )

      described_class.process_due_date_reminder("Assignment", assignment.id)
    end
  end
end
