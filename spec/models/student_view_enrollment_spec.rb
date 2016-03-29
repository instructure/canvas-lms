#
# Copyright (C) 2012 Instructure, Inc.
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

describe StudentViewEnrollment do

  before(:each) do
    @student = User.create(:name => "some student")
    @course = Course.create(:name => "some course")
    @se = @course.enroll_student(@student)
    expect(@se.user_id).to eql(@student.id)
    expect(@course.students).to include(@student)
    @assignment = @course.assignments.create!(:title => 'some assignment')
    expect(@course.assignments).to include(@assignment)
    @submission = @assignment.submit_homework(@student)
    @assignment.reload
    expect(@submission).not_to be_nil
    expect(@assignment.submissions.to_a).to eql([@submission])
    @course.save!
    @se = @course.student_enrollments.first
  end

  it "should belong to a student" do
    @se.reload
    @student.reload
    expect(@se.user_id).to eql(@student.id)
    expect(@se.user).to eql(@student)
    expect(@se.user.id).to eql(@student.id)
  end
end
