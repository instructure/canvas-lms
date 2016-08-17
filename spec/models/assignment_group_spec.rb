#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssignmentGroup do

  before(:once) do
    @valid_attributes = {
      :name => "value for name",
      :rules => "value for rules",
      :default_assignment_name => "value for default assignment name",
      :assignment_weighting_scheme => "value for assignment weighting scheme",
      :group_weight => 1.0
    }
    course_with_student(active_all: true)
    @course.update_attribute(:group_weighting_scheme, 'percent')
  end

  it "should act as list" do
    expect(AssignmentGroup).to be_respond_to(:acts_as_list)
  end

  context "visible assignments" do
    before(:each) do
      @ag = @course.assignment_groups.create!(@valid_attributes)
      @s = @course.course_sections.create!(name: "test section")
      student_in_section(@s, user: @student)
      assignments = (0...4).map { @course.assignments.create!({:title => "test_foo",
                                  :assignment_group => @ag,
                                  :points_possible => 10,
                                  :only_visible_to_overrides => true})}
      assignments.first.destroy
      assignments.second.grade_student(@student, {grade: 10})
      assignment_to_override = assignments.last
      create_section_override_for_assignment(assignment_to_override, course_section: @s)
      @course.reload
      @ag.reload
    end

    context "with differentiated assignments and draft state on" do
      it "should return only active assignments with overrides or grades for the user" do
        expect(@ag.active_assignments.count).to eq 3
        # one with override, one with grade
        expect(@ag.visible_assignments(@student).count).to eq 2
        expect(AssignmentGroup.visible_assignments(@student, @course, [@ag]).count).to eq 2
      end
    end

    context "logged out users" do
      it "should return published assignments for logged out users so that invited users can see them before accepting a course invite" do
        @course.active_assignments.first.unpublish
        expect(@ag.visible_assignments(nil).count).to eq 2
        expect(AssignmentGroup.visible_assignments(nil, @course, [@ag]).count).to eq 2
      end
    end
  end

  context "broadcast policy" do
    context "grade weight changed" do
      before(:once) do
        Notification.create!(name: 'Grade Weight Changed', category: 'TestImmediately')
        assignment_group_model
      end

      it "sends a notification when the grade weight changes" do
        @ag.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent['Grade Weight Changed'].any?{|m| m.user_id == @student.id}).to be_truthy
      end

      it "sends a notification to observers when the grade weight changes" do
        course_with_observer(course: @course, associated_user_id: @student.id, active_all: true)
        @ag.reload.update_attribute(:group_weight, 0.2)
        expect(@ag.context.messages_sent['Grade Weight Changed'].any?{|m| m.user_id == @observer.id}).to be_truthy
      end
    end
  end

  it "should have a state machine" do
    assignment_group_model
    expect(@ag.state).to eql(:available)
  end

  it "should return never_drop list as ints" do
    expected = [ 9, 22, 16, 4 ]
    rules = "drop_lowest:2\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end
    assignment_group_model :rules => rules
    result = @ag.rules_hash()
    expect(result['never_drop']).to eql(expected)
  end

  it "should return never_drop list as strings if `stringify_json_ids` is true" do
    expected = [ '9', '22', '16', '4' ]
    rules = "drop_highest:25\n"
    expected.each do |val|
      rules += "never_drop:#{val}\n"
    end

    assignment_group_model :rules => rules
    result = @ag.rules_hash({stringify_json_ids: true})
    expect(result['never_drop']).to eql(expected)
  end

  it "should return rules that aren't never_drops as ints" do
    rules = "drop_highest:25\n"
    assignment_group_model :rules => rules
    result = @ag.rules_hash()
    expect(result['drop_highest']).to eql(25)
  end

  it "should return rules that aren't never_drops as ints when `strigify_json_ids` is true" do
    rules = "drop_lowest:2\n"
    assignment_group_model :rules => rules
    result = @ag.rules_hash({stringify_json_ids: true})
    expect(result['drop_lowest']).to eql(2)
  end

  describe "#grants_right?" do
    before(:once) do
      @assignment_group = @course.assignment_groups.create!(@valid_attributes)
      assignments = (0..1).map do |n|
        @course.assignments.create!(
          title: "Example Assignment #{n}",
          assignment_group: @assignment_group,
          points_possible: 10,
          published: true
        )
      end
      @assignment = assignments.first

      @quiz = quiz_model(course: @course)
      @quiz.assignment_group_id = @assignment_group.id
      @quiz.save!

      @admin = account_admin_user()
      teacher_in_course(:course => @course)
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
      before(:each) do
        @course.root_account.enable_feature!(:multiple_grading_periods)
      end

      context "when multiple grading periods is disabled" do
        it "is true for admins" do
          @course.root_account.disable_feature!(:multiple_grading_periods)
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          @course.root_account.disable_feature!(:multiple_grading_periods)
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due in a closed grading period" do
        before(:once) do
          @assignment.update_attributes(due_at: 4.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the assignment is due in an open grading period" do
        before(:once) do
          @assignment.update_attributes(due_at: 2.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due after all grading periods" do
        before(:once) do
          @assignment.update_attributes(due_at: 1.day.from_now)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due before all grading periods" do
        before(:once) do
          @assignment.update_attributes(due_at: 6.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment has no due date" do
        before(:once) do
          @assignment.update_attributes(due_at: nil)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due in a closed grading period for a student" do
        before(:once) do
          @assignment.update_attributes(due_at: 2.days.from_now)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the assignment is overridden with no due date for a student" do
        before(:once) do
          @assignment.update_attributes(due_at: nil)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is deleted and due in a closed grading period" do
        before(:once) do
          @assignment.update_attributes(due_at: 4.weeks.ago)
          @assignment.destroy
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz is due in a closed grading period" do
        before(:once) do
          @quiz.update_attributes(due_at: 4.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the quiz is due in an open grading period" do
        before(:once) do
          @quiz.update_attributes(due_at: 2.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz is due after all grading periods" do
        before(:once) do
          @quiz.update_attributes(due_at: 1.day.from_now)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz is due before all grading periods" do
        before(:once) do
          @quiz.update_attributes(due_at: 6.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz has no due date" do
        before(:once) do
          @quiz.update_attributes(due_at: nil)
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz is due in a closed grading period for a student" do
        before(:once) do
          @quiz.update_attributes(due_at: 2.days.from_now)
          override = @quiz.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the quiz is overridden with no due date for a student" do
        before(:once) do
          @quiz.update_attributes(due_at: nil)
          override = @quiz.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the quiz is deleted and due in a closed grading period" do
        before(:once) do
          @quiz.update_attributes(due_at: 4.weeks.ago)
          @quiz.destroy
        end

        it "is true for admins" do
          expect(@assignment_group.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment_group.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end
    end
  end
end

def assignment_group_model(opts={})
  @ag = @course.assignment_groups.create!(@valid_attributes.merge(opts))
end
