# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe AssignmentOverrideStudent do
  describe "validations" do
    before :once do
      student_in_course
      @override = assignment_override_model(course: @course)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
    end

    it "is valid in nominal setup" do
      expect(@override_student).to be_valid
    end

    it "always makes assignment match the overridden assignment" do
      assignment = assignment_model
      @override_student.assignment = assignment
      expect(@override_student).to be_valid
      expect(@override_student.assignment).to eq @override.assignment
    end

    it "rejects an empty assignment_override" do
      @override_student.assignment_override = nil
      expect(@override_student).not_to be_valid
    end

    it "rejects a non-adhoc assignment_override" do
      @override_student.assignment_override.set = @course.default_section
      expect(@override_student).not_to be_valid
    end

    it "rejects an empty user" do
      @override_student.user = nil
      expect(@override_student).not_to be_valid
    end

    it "rejects a student not in the course" do
      @override_student.user = user_model
      expect(@override_student).not_to be_valid
    end

    it "rejects duplicate tuples" do
      @override_student.save!
      @override_student2 = @override.assignment_override_students.build
      @override_student2.user = @student
      expect(@override_student2).not_to be_valid
    end
  end

  describe "recalculation of cached due dates" do
    before(:once) do
      course = Course.create!
      @student = User.create!
      course.enroll_student(@student, active_all: true)
      @assignment = course.assignments.create!
      @assignment_override = @assignment.assignment_overrides.create!
    end

    it "on creation, recalculates cached due dates on the assignment" do
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(@student.id, @assignment.context, [@assignment]).once
      @assignment_override.assignment_override_students.create!(user: @student)
    end

    it "on destroy, recalculates cached due dates on the assignment" do
      override_student = @assignment_override.assignment_override_students.create!(user: @student)

      # Expect SubmissionLifecycleManager to be called once from AssignmentOverrideStudent after it's destroyed and another time
      # after it realizes that its corresponding AssignmentOverride can also be destroyed because it now has an empty
      # set of students.  Hence the specific nature of this expectation.
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(@student.id, @assignment.context, [@assignment]).once
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment).once
      override_student.destroy
    end
  end

  describe "cross sharded users" do
    specs_require_sharding
    it "works outside of the users native account" do
      course_with_student(account: @account, active_all: true, user: @student)
      @shard1.activate do
        account = Account.create!
        course = account.courses.create!
        e2 = course.enroll_student(@student)
        e2.update_attribute(:workflow_state, "active")
        override = assignment_override_model(course:)
        override_student = override.assignment_override_students.build
        override_student.user = @student
        expect(override_student).to be_valid
      end
    end
  end

  it "maintains assignment from assignment_override" do
    student_in_course
    @override1 = assignment_override_model(course: @course)
    @override2 = assignment_override_model(course: @course)
    expect(@override1.assignment_id).not_to eq @override2.assignment_id

    @override_student = @override1.assignment_override_students.build
    @override_student.user = @student
    @override_student.valid? # trigger maintenance
    expect(@override_student.assignment_id).to eq @override1.assignment_id
    @override_student.assignment_override = @override2
    @override_student.valid? # trigger maintenance
    expect(@override_student.assignment_id).to eq @override2.assignment_id
  end

  def adhoc_override_with_student
    student_in_course(active_all: true)
    @assignment = assignment_model(course: @course)
    @ao = AssignmentOverride.new
    @ao.assignment = @assignment
    @ao.title = "ADHOC OVERRIDE"
    @ao.workflow_state = "active"
    @ao.set_type = "ADHOC"
    @ao.save!
    @override_student = @ao.assignment_override_students.build
    @override_student.user = @user
    @override_student.save!
  end

  it "calls destroy its override if its the only student and is deleted" do
    adhoc_override_with_student

    expect(@ao).to be_active
    @override_student.destroy
    expect(@ao.reload).to be_deleted
  end

  describe "clean_up_for_assignment" do
    it "if callbacks aren't run clean_up_for_assignment should delete invalid overrides" do
      adhoc_override_with_student
      Score.where(enrollment_id: @user.enrollments).each(&:destroy_permanently!)
      @user.enrollments.each(&:destroy_permanently!)

      expect(@override_student).to be_active
      expect(@ao).to be_active
      AssignmentOverrideStudent.clean_up_for_assignment(@assignment)

      expect(@override_student.reload).to be_deleted
      expect(@ao.reload).to be_deleted
    end

    it "does not delete overrides for inactive users" do
      adhoc_override_with_student
      @user.enrollments.each(&:deactivate)

      expect do
        AssignmentOverrideStudent.clean_up_for_assignment(@assignment)
      end.not_to change {
        @override_student.reload.active?
      }.from(true)
    end

    it "does not delete overrides for conclude/completed users" do
      adhoc_override_with_student
      @user.enrollments.each(&:conclude)

      expect do
        AssignmentOverrideStudent.clean_up_for_assignment(@assignment)
      end.not_to change {
        @override_student.reload.active?
      }.from(true)
    end

    it "does not broadcast notifications when processing a cleanup" do
      Timecop.freeze(1.day.ago) do
        adhoc_override_with_student
      end
      Enrollment.where(id: @enrollment).update_all(workflow_state: "deleted") # skip callbacks

      notification_name = "Assignment Due Date Override Changed"
      @notification = Notification.create! name: notification_name, category: "TestImmediately"
      teacher_in_course(active_all: true)
      notification_policy_model

      expect(DelayedNotification).to_not receive(:process)
      AssignmentOverrideStudent.clean_up_for_assignment(@assignment)
      expect(@ao.reload).to be_deleted
    end

    it "trying to update an orphaned override student (one without an enrollment) removes it" do
      adhoc_override_with_student
      Score.where(enrollment_id: @user.enrollments).each(&:destroy_permanently!)
      @user.enrollments.each(&:destroy_permanently!)

      # using update instead of touch in order to trigger validations
      expect { AssignmentOverrideStudent.find(@override_student.id).update(updated_at: Time.zone.now) }.to change {
        AssignmentOverrideStudent.where(id: @override_student.id).active.count
      }.from(1).to(0)
    end
  end

  describe "default_values" do
    let(:override_student) { AssignmentOverrideStudent.new }
    let(:override) { AssignmentOverride.new }
    let(:quiz_id) { 1 }
    let(:assignment_id) { 2 }
    let(:context_module_id) { 3 }
    let(:wiki_page_id) { 4 }
    let(:discussion_topic_id) { 5 }
    let(:attachment_id) { 6 }

    before do
      override_student.assignment_override = override
    end

    context "when the override has an assignment" do
      before do
        override.assignment_id = assignment_id
        override_student.send(:default_values)
      end

      it "has the assignment's ID" do
        expect(override_student.assignment_id).to eq assignment_id
      end

      it "has a nil quiz ID" do
        expect(override_student.quiz_id).to be_nil
      end
    end

    context "when the override has a quiz and assignment" do
      before do
        override.assignment_id = assignment_id
        override.quiz_id = quiz_id
        override_student.send(:default_values)
      end

      it "has the assignment's ID" do
        expect(override_student.assignment_id).to eq assignment_id
      end

      it "has the quiz's ID" do
        expect(override_student.quiz_id).to eq quiz_id
      end
    end

    context "when the override has a module" do
      before do
        override.context_module_id = context_module_id
        override_student.send(:default_values)
      end

      it "has the module's ID" do
        expect(override_student.context_module_id).to eq context_module_id
      end

      it "has a nil assignment ID" do
        expect(override_student.assignment_id).to be_nil
      end

      it "has a nil quiz ID" do
        expect(override_student.quiz_id).to be_nil
      end
    end

    it "sets default values when the override has a wiki_page" do
      override.wiki_page_id = wiki_page_id
      override_student.send(:default_values)
      expect(override_student.wiki_page_id).to eq wiki_page_id
    end

    it "sets default values when the override has a discussion_topic" do
      override.discussion_topic_id = discussion_topic_id
      override_student.send(:default_values)
      expect(override_student.discussion_topic_id).to eq discussion_topic_id
    end

    it "sets default values when the override has an attachment" do
      override.attachment_id = attachment_id
      override_student.send(:default_values)
      expect(override_student.attachment_id).to eq attachment_id
    end
  end

  describe "create" do
    it "sets the root_account_id using assignment" do
      adhoc_override_with_student
      expect(@override_student.root_account_id).to eq @assignment.root_account_id
    end
  end
end
