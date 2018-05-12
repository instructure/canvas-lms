#
# Copyright (C) 2014 - present Instructure, Inc.
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
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'

describe 'quizzes regressions' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_teacher_logged_in(course_name: 'teacher course')
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
  end

  it 'calendar pops up on top of #main', priority: "1", test_id: 209957 do
    get "/courses/#{@course.id}/quizzes"
    click_new_quiz_button
    wait_for_ajaximations
    fj('.ui-datepicker-trigger:first').click
    cal = f('#ui-datepicker-div')
    expect(cal).to be_displayed
    expect(cal.style('z-index')).to be > f('#main').style('z-index')
  end

  it 'marks questions as answered when the window loses focus', priority: "1", test_id: 209959

  it 'quiz show page displays the quiz due date', priority: "1", test_id: 209960 do
    due_date = Time.zone.now + 4.days
    create_quiz_with_due_date(due_at: due_date)
    verify_quiz_show_page_due_date(format_date_for_view(due_date))
  end

  context 'rubrics' do
    before(:each) do
      course_with_teacher_logged_in
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      f('.al-trigger').click
      f('.show_rubric_link').click
      wait_for_ajaximations
      fj('#rubrics .add_rubric_link:visible').click
    end

    it 'doesn\'t show \'use for grading\' as an option', priority: "2", test_id: 209962 do
      expect(f("#content")).not_to contain_jqcss('.rubric_grading:visible')
    end

    it "shows' criterion Popover menu" do
      dialog = fj(".ui-dialog:visible")
      fj(".icon-plus:visible", dialog).click

      expect(f("#criterion_duplicate_menu")).to be_displayed
    end
  end
end
