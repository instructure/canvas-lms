#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../common'

describe "moderated grading assignments" do
  include_context "in-process server selenium tests"

  before do
    @course = course_model
    @course.offer!
    @assignment = @course.assignments.create!(submission_types: 'online_text_entry', title: 'Test Assignment')
    @assignment.update_attribute :moderated_grading, true
    @assignment.update_attribute :workflow_state, 'published'
    @student = User.create!
    @course.enroll_student(@student)
    @user = User.create!
    @course.enroll_ta(@user)
  end

  it "publishes grades from the moderate screen" do
    sub = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'hallo')
    sub.find_or_create_provisional_grade!(@user, score: 80)

    course_with_teacher_logged_in course: @course
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
    f('.ModeratedGrading__Header-PublishBtn').click
    driver.switch_to.alert.accept
    assert_flash_notice_message("Success! Grades were published to the grade book")
  end

end
