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
require 'lib/data_fixup/reset_ungraded_counts.rb'

describe 'DataFixup::ResetUngradedCounts' do
  it "should work" do
    assignment_model

    # teacher with a submission 
    s = @assignment.find_or_create_submission(@teacher)
    s.submission_type = 'online_quiz'
    s.workflow_state = 'submitted'
    s.save!

    # user with two enrollments and one submission
    user_model
    @course.enroll_student(@user, :enrollment_state => 'active')
    section = @course.course_sections.create!(:name => 's2')
    @course.enroll_student(@user, :enrollment_state => 'active', :section => section, :allow_multiple_enrollments => true)
    @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})

    # user with a graded submission
    user_model
    @course.enroll_student(@user, :enrollment_state => 'active')
    @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
    @assignment.reload.grade_student(@user, :grade => "0")

    @assignment.reload.update_attribute(:needs_grading_count, 0)
    expect(Submission.count).to eql 3
    expect(Enrollment.count).to eql 4

    DataFixup::ResetUngradedCounts.run

    expect(@assignment.reload.needs_grading_count).to eql 1
  end
end
