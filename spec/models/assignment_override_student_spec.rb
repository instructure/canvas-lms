#
# Copyright (C) 2011 Instructure, Inc.
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
require_relative '../sharding_spec_helper'

describe AssignmentOverrideStudent do
  describe "validations" do
    before :once do
      student_in_course
      @override = assignment_override_model(:course => @course)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
    end

    it "should be valid in nominal setup" do
      expect(@override_student).to be_valid
    end

    it "should always make assignment match the overriden assignment" do
      assignment = assignment_model
      @override_student.assignment = assignment
      expect(@override_student).to be_valid
      expect(@override_student.assignment).to eq @override.assignment
    end

    it "should reject an empty assignment_override" do
      @override_student.assignment_override = nil
      expect(@override_student).not_to be_valid
    end

    it "should reject a non-adhoc assignment_override" do
      @override_student.assignment_override.set = @course.default_section
      expect(@override_student).not_to be_valid
    end

    it "should reject an empty user" do
      @override_student.user = nil
      expect(@override_student).not_to be_valid
    end

    it "should reject a student not in the course" do
      @override_student.user = user_model
      expect(@override_student).not_to be_valid
    end

    it "should reject duplicate tuples" do
      @override_student.save!
      @override_student2 = @override.assignment_override_students.build
      @override_student2.user = @student
      expect(@override_student2).not_to be_valid
    end
  end

  describe "cross sharded users" do
    specs_require_sharding
    it "should work outside of the users native account" do
      course_with_student(account: @account, active_all: true, user: @student)
      @shard1.activate do
        account = Account.create!
        course = account.courses.create!
        e2 = course.enroll_student(@student)
        e2.update_attribute(:workflow_state, 'active')
        override = assignment_override_model(:course => course)
        override_student = override.assignment_override_students.build
        override_student.user = @student
        expect(override_student).to be_valid
      end
    end
  end

  it "should maintain assignment from assignment_override" do
    student_in_course
    @override1 = assignment_override_model(:course => @course)
    @override2 = assignment_override_model(:course => @course)
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
    student_in_course
    @assignment = assignment_model(:course => @course)
    @ao = AssignmentOverride.new()
    @ao.assignment = @assignment
    @ao.title = "ADHOC OVERRIDE"
    @ao.workflow_state = "active"
    @ao.set_type = "ADHOC"
    @ao.save!
    @override_student = @ao.assignment_override_students.build
    @override_student.user = @user
    @override_student.save!
  end

  it "should call destroy its override if its the only student and is deleted" do
    adhoc_override_with_student

    expect(@ao.workflow_state).to eq("active")
    @override_student.destroy
    @ao.reload

    expect(@ao.workflow_state).to eq("deleted")
  end

  describe "clean_up_for_assignment" do
    it "if callbacks arent run clean_up_for_assignment should delete invalid overrides" do
      adhoc_override_with_student
      #no callbacks
      @user.enrollments.each(&:destroy_permanently!)

      expect(@ao.workflow_state).to eq("active")
      AssignmentOverrideStudent.clean_up_for_assignment(@assignment)
      @ao.reload

      expect(@ao.workflow_state).to eq("deleted")
    end
  end

  describe "default_values" do
    let(:override_student) { AssignmentOverrideStudent.new }
    let(:override) { AssignmentOverride.new }
    let(:quiz_id) { 1 }
    let(:assignment_id) { 2 }

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
  end
end
