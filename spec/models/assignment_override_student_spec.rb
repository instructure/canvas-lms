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

describe AssignmentOverrideStudent do
  describe "validations" do
    before :each do
      student_in_course
      @override = assignment_override_model(:course => @course)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
    end

    it "should be valid in nominal setup" do
      @override_student.should be_valid
    end

    it "should reject an assignment other than that of the override" do
      @override_student.assignment = assignment_model
      @override_student.should_not be_valid
    end

    it "should reject an empty assignment_override" do
      @override_student.assignment_override = nil
      @override_student.should_not be_valid
    end

    it "should reject a non-adhoc assignment_override" do
      @override_student.assignment_override.set = @course.default_section
      @override_student.should_not be_valid
    end

    it "should reject an empty user" do
      @override_student.user = nil
      @override_student.should_not be_valid
    end

    it "should reject a student not in the course" do
      @override_student.user = user_model
      @override_student.should_not be_valid
    end

    it "should reject duplicate tuples" do
      @override_student.save!
      @override_student2 = @override.assignment_override_students.build
      @override_student2.user = @student
      @override_student2.should_not be_valid
    end
  end

  it "should maintain assignment from assignment_override" do
    student_in_course
    @override1 = assignment_override_model(:course => @course)
    @override2 = assignment_override_model(:course => @course)
    @override1.assignment_id.should_not == @override2.assignment_id

    @override_student = @override1.assignment_override_students.build
    @override_student.user = @student
    @override_student.valid? # trigger maintenance
    @override_student.assignment_id.should == @override1.assignment_id
    @override_student.assignment_override = @override2
    @override_student.valid? # trigger maintenance
    @override_student.assignment_id.should == @override2.assignment_id
  end
end
