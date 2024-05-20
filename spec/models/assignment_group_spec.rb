# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AssignmentGroup do
  before(:once) do
    @valid_attributes = {
      name: "value for name",
      rules: "value for rules",
      default_assignment_name: "value for default assignment name",
      assignment_weighting_scheme: "value for assignment weighting scheme",
      group_weight: 1.0
    }
    course_with_student(active_all: true)
    @course.update_attribute(:group_weighting_scheme, "percent")
  end

  it "acts as list" do
    expect(AssignmentGroup).to respond_to(:acts_as_list)
  end

  it "converts NaN group weight values to 0 on save" do
    ag = @course.assignment_groups.create!(@valid_attributes)
    ag.group_weight = 0 / 0.0
    ag.save!
    expect(ag.group_weight).to eq 0
  end

  it "allows association with scores" do
    ag = @course.assignment_groups.create!(@valid_attributes)
    @course.student_enrollments.first
    score = ag.scores.first
    expect(score.assignment_group_id).to be ag.id
  end

  context "visible_assignments" do
    before do
      @ag = @course.assignment_groups.create!(@valid_attributes)
      @s = @course.course_sections.create!(name: "test section")
      student_in_section(@s, user: @student)
      assignments = (0...4).map do
        @course.assignments.create!(
          title: "test_foo",
          assignment_group: @ag,
          points_possible: 10,
          only_visible_to_overrides: true
        )
      end
      @destroyed_assignment = assignments.first
      @destroyed_assignment.destroy
      @assignment = assignments.second
      create_adhoc_override_for_assignment(@assignment, @student)
      @overridden_assignment = assignments.last
      create_section_override_for_assignment(@overridden_assignment, course_section: @s)
      @course.reload
      @ag.reload
    end

    describe "class method" do
      it "optionally scopes results to specific assignment IDs" do
        assignment_ids = AssignmentGroup.visible_assignments(
          @student,
          @course,
          [@ag],
          assignment_ids: [@assignment.id]
        ).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id]
      end

      it "does not include requested assignments that would otherwise not be returned" do
        assignment_ids = AssignmentGroup.visible_assignments(
          @student,
          @course,
          [@ag],
          assignment_ids: [@assignment.id, @destroyed_assignment.id]
        ).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id]
      end

      it "gracefully ignores assignment_ids if passed nil" do
        assignment_ids = AssignmentGroup.visible_assignments(
          @student,
          @course,
          [@ag],
          assignment_ids: nil
        ).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id, @overridden_assignment.id]
      end
    end

    describe "instance method" do
      it "optionally scopes results to specific assignment IDs" do
        assignment_ids = @ag.visible_assignments(@student, assignment_ids: [@assignment.id]).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id]
      end

      it "does not include requested assignments that would otherwise not be returned" do
        assignment_ids = @ag.visible_assignments(
          @student,
          assignment_ids: [@assignment.id, @destroyed_assignment.id]
        ).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id]
      end

      it "gracefully ignores assignment_ids if passed nil" do
        assignment_ids = @ag.visible_assignments(@student, assignment_ids: nil).pluck(:id)
        expect(assignment_ids).to match_array [@assignment.id, @overridden_assignment.id]
      end
    end

    context "with differentiated assignments and draft state on" do
      it "returns only active assignments with overrides or grades for the user" do
        expect(@ag.active_assignments.count).to eq 3
        # one with override, one with grade
        expect(@ag.visible_assignments(@student).count).to eq 2
        expect(AssignmentGroup.visible_assignments(@student, @course, [@ag]).count).to eq 2
      end
    end

    context "logged out users" do
      it "returns published assignments for logged out users so that invited users can see them before accepting a course invite" do
        @course.active_assignments.first.unpublish
        expect(@ag.visible_assignments(nil).count).to eq 2
        expect(AssignmentGroup.visible_assignments(nil, @course, [@ag]).count).to eq 2
      end
    end
  end

  context "broadcast policy" do
    context "grade weight changed" do
      before(:once) do
        Notification.create!(name: "Grade Weight Changed", category: "TestImmediately")
        assignment_group_model
      end

      it "sends a notification when the grade weight changes" do
        @ag.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent["Grade Weight Changed"].any? { |m| m.user_id == @student.id }).to be_truthy
      end

      it "sends a notification to observers when the grade weight changes" do
        course_with_observer(course: @course, associated_user_id: @student.id, active_all: true)
        @ag.reload.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent["Grade Weight Changed"].any? { |m| m.user_id == @observer.id }).to be_truthy
      end
    end
  end

  it "has a state machine" do
    assignment_group_model
    expect(@ag.state).to be(:available)
  end

  it "returns never_drop list as ints" do
    expected = [9, 22, 16, 4]
    rules = "drop_lowest:2\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end
    assignment_group_model(rules:)
    result = @ag.rules_hash
    expect(result["never_drop"]).to eql(expected)
  end

  it "converts rules decimal values into integers" do
    custom_rules_hash = {
      drop_lowest: 1.1,
      drop_highest: 2.9,
      never_drop: [1, 2]
    }.with_indifferent_access
    assignment_group_model.rules_hash = custom_rules_hash
    expect(@ag.rules).to eql("drop_lowest:1\ndrop_highest:2\nnever_drop:1\nnever_drop:2\n")
  end

  it "converts string values into integers" do
    custom_rules_hash = {
      drop_lowest: "123abc",
      drop_highest: 2,
      never_drop: [1, 2]
    }.with_indifferent_access
    assignment_group_model.rules_hash = custom_rules_hash
    expect(@ag.rules).to eql("drop_lowest:123\ndrop_highest:2\nnever_drop:1\nnever_drop:2\n")
  end

  it "validate is false when drop_lowest is negative" do
    rules = "drop_lowest:-1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
    assignment_group_model(rules:)
    @ag.validate_rules = true
    @ag.reload
    @course.assignments.create!(title: "test", assignment_group: @ag)
    expect(@ag.validate).to be(false)
    expect(@ag.errors.full_messages).to eql(["Rules Drop rules must be a positive number"])
  end

  it "validate is false when drop_highest is negative" do
    rules = "drop_lowest:1\ndrop_highest:-1\nnever_drop:1\nnever_drop:2\n"
    assignment_group_model(rules:)
    @ag.validate_rules = true
    @ag.reload
    @course.assignments.create!(title: "test", assignment_group: @ag)
    expect(@ag.validate).to be(false)
    expect(@ag.errors.full_messages).to eql(["Rules Drop rules must be a positive number"])
  end

  it "validate is false when drop_lowest is greater than number of assignments" do
    rules = "drop_lowest:2\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
    assignment_group_model(rules:)
    @ag.validate_rules = true
    @ag.reload
    @course.assignments.create!(title: "test", assignment_group: @ag)
    expect(@ag.validate).to be(false)
    expect(@ag.errors.full_messages).to eql(["Rules Drop rules cannot be higher than the number of assignments"])
  end

  it "validate is false when drop_highest and drop_lowest are valid" do
    rules = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
    assignment_group_model(rules:)
    @ag.validate_rules = true
    @ag.reload
    @course.assignments.create!(title: "test", assignment_group: @ag)
    expect(@ag.validate).to be(true)
  end

  it "validate is true when ndrop_highest is greater than number of assignments" do
    rules = "drop_lowest:1\ndrop_highest:2\nnever_drop:1\nnever_drop:2\n"
    assignment_group_model(rules:)
    @ag.validate_rules = true
    @ag.reload
    @course.assignments.create!(title: "test", assignment_group: @ag)
    expect(@ag.validate).to be(false)
    expect(@ag.errors.full_messages).to eql(["Rules Drop rules cannot be higher than the number of assignments"])
  end

  it "returns never_drop list as strings if `stringify_json_ids` is true" do
    expected = %w[9 22 16 4]
    rules = "drop_highest:25\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end

    assignment_group_model(rules:)
    result = @ag.rules_hash({ stringify_json_ids: true })
    expect(result["never_drop"]).to eql(expected)
  end

  it "returns rules that aren't never_drops as ints" do
    rules = "drop_highest:25\n"
    assignment_group_model(rules:)
    result = @ag.rules_hash
    expect(result["drop_highest"]).to be(25)
  end

  it "returns rules that aren't never_drops as ints when `strigify_json_ids` is true" do
    rules = "drop_lowest:2\n"
    assignment_group_model(rules:)
    result = @ag.rules_hash({ stringify_json_ids: true })
    expect(result["drop_lowest"]).to be(2)
  end

  describe "#grants_right?" do
    before(:once) do
      @assignment_group = @course.assignment_groups.create!(@valid_attributes)
      assignments = (0..1).map do |n|
        @course.assignments.create!(
          title: "Example Assignment #{n}",
          assignment_group: @assignment_group,
          points_possible: 10
        )
      end
      @assignment = assignments.first

      @quiz = quiz_model(course: @course)
      @quiz.assignment_group_id = @assignment_group.id
      @quiz.save!

      @admin = account_admin_user
      teacher_in_course(course: @course)
      @grading_period_group = @course.root_account.grading_period_groups.create!(title: "Example Group")
      @grading_period_group.enrollment_terms << @course.enrollment_term
      @course.enrollment_term.save!
      @assignment_group.reload

      @grading_period_group.grading_periods.create!({
                                                      title: "Example Grading Period",
                                                      start_date: 5.weeks.ago,
                                                      end_date: 3.weeks.ago,
                                                      close_date: 1.week.ago
                                                    })
      @grading_period_group.grading_periods.create!({
                                                      title: "Example Grading Period",
                                                      start_date: 3.weeks.ago,
                                                      end_date: 1.week.ago,
                                                      close_date: 1.week.from_now
                                                    })
    end

    context "to delete" do
      context "without grading periods" do
        it "is true for admins" do
          allow(@course).to receive(:grading_periods?).and_return false
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be true
        end

        it "is false for teachers" do
          allow(@course).to receive(:grading_periods?).and_return false
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be true
        end
      end

      context "when the assignment is due in a closed grading period" do
        before(:once) do
          @assignment.update(due_at: 4.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(false)
        end
      end

      context "when the assignment is due in an open grading period" do
        before(:once) do
          @assignment.update(due_at: 2.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the assignment is due after all grading periods" do
        before(:once) do
          @assignment.update(due_at: 1.day.from_now)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the assignment is due before all grading periods" do
        before(:once) do
          @assignment.update(due_at: 6.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the assignment has no due date" do
        before(:once) do
          @assignment.update(due_at: nil)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the assignment is due in a closed grading period for a student" do
        before(:once) do
          @assignment.update(due_at: 2.days.from_now)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(false)
        end
      end

      context "when the assignment is overridden with no due date for a student" do
        before(:once) do
          @assignment.update(due_at: nil)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the assignment is deleted and due in a closed grading period" do
        before(:once) do
          @assignment.update(due_at: 4.weeks.ago)
          @assignment.destroy
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz is due in a closed grading period" do
        before(:once) do
          @quiz.update(due_at: 4.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(false)
        end
      end

      context "when the quiz is due in an open grading period" do
        before(:once) do
          @quiz.update(due_at: 2.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz is due after all grading periods" do
        before(:once) do
          @quiz.update(due_at: 1.day.from_now)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz is due before all grading periods" do
        before(:once) do
          @quiz.update(due_at: 6.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz has no due date" do
        before(:once) do
          @quiz.update(due_at: nil)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz is due in a closed grading period for a student" do
        before(:once) do
          @quiz.update(due_at: 2.days.from_now)
          override = @quiz.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(false)
        end
      end

      context "when the quiz is overridden with no due date for a student" do
        before(:once) do
          @quiz.update(due_at: nil)
          override = @quiz.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end

      context "when the quiz is deleted and due in a closed grading period" do
        before(:once) do
          @quiz.update(due_at: 4.weeks.ago)
          @quiz.destroy
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to be(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to be(true)
        end
      end
    end
  end

  describe "#any_assignment_in_closed_grading_period?" do
    it "calls EffectiveDueDates#in_closed_grading_period?" do
      assignment_group_model
      edd = EffectiveDueDates.for_course(@ag.context, @ag.published_assignments)
      expect(EffectiveDueDates).to receive(:for_course).with(@ag.context, @ag.published_assignments).and_return(edd)
      expect(edd).to receive(:any_in_closed_grading_period?).and_return(true)
      expect(@ag.any_assignment_in_closed_grading_period?).to be(true)
    end
  end

  describe "#destroy" do
    before(:once) do
      @student_enrollment = @student.enrollments.find_by(course_id: @course)
      @group = @course.assignment_groups.create!(@valid_attributes)
    end

    let(:student_score) do
      Score.find_by(enrollment_id: @student_enrollment, assignment_group_id: @group)
    end

    it "destroys scores belonging to active students" do
      expect { @group.destroy }.to change { student_score.reload.state }.from(:active).to(:deleted)
    end

    it "does not destroy scores belonging to concluded students" do
      @student_enrollment.conclude
      expect { @group.destroy }.not_to change { student_score.reload.state }
    end

    it "destroys active assignments belonging to the group" do
      assignment = @course.assignments.create!
      @group.destroy
      expect(assignment.reload).to be_deleted
    end

    it "does not run validations on soft-deleted assignments belonging to the group" do
      now = Time.zone.now
      assignment = @course.assignments.create!(
        unlock_at: 3.days.ago(now),
        due_at: now,
        lock_at: 3.days.from_now(now),
        workflow_state: "deleted"
      )
      # update the assignment to be invalid, so that if validations are run
      # we'll get an error
      assignment.update_columns(lock_at: 2.days.ago(now))
      expect { @group.destroy }.not_to raise_error
    end
  end

  describe "#restore" do
    before(:once) do
      @student_enrollment = @student.enrollments.find_by(course_id: @course)
      @group = @course.assignment_groups.create!(@valid_attributes)
      @group.destroy
    end

    let(:student_score) do
      Score.find_by(enrollment_id: @student_enrollment, assignment_group_id: @group)
    end

    it "restores the assignment group back to an 'available' state" do
      expect { @group.restore }.to change { @group.state }.from(:deleted).to(:available)
    end

    it "restores scores belonging to active students" do
      expect { @group.restore }.to change { student_score.reload.state }.from(:deleted).to(:active)
    end

    it "does not restore scores belonging to concluded students" do
      @student_enrollment.conclude
      expect { @group.restore }.not_to change { student_score.reload.state }
    end

    it "does not restore scores belonging to deleted students" do
      @student_enrollment.destroy
      expect { @group.restore }.not_to change { student_score.reload.state }
    end
  end

  describe "#create" do
    it "sets the root_account_id using context" do
      group = @course.assignment_groups.create!(@valid_attributes)
      expect(group.root_account_id).to eq @course.root_account_id
    end
  end
end

def assignment_group_model(opts = {})
  @ag = @course.assignment_groups.create!(@valid_attributes.merge(opts))
end
