# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../pages/k5_dashboard_common_page'
require_relative '../../../helpers/k5_common'
require_relative '../pages/k5_important_dates_section_page'
require_relative '../shared_examples/k5_important_dates_shared_examples'

describe "teacher k5 dashboard important dates" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject

  before :once do
    teacher_setup
  end

  before :each do
    user_session @homeroom_teacher
  end

  context 'mark important dates availability' do
    before :once do
      Account.site_admin.enable_feature!(:important_dates)
    end

    it 'sets the mark important dates checkbox for assignment', custom_timeout: 25 do
      due_at = 2.days.from_now(Time.zone.now)
      assignment = create_dated_assignment(@subject_course, "Marked Assignment", due_at)

      get "/courses/#{@subject_course.id}/assignments/#{assignment.id}/edit"


      expect(mark_important_dates).to be_displayed

      scroll_to_element(mark_important_dates)
      click_mark_important_dates

      expect_new_page_load { submit_form(edit_assignment_submit_selector) }
    end

    it 'sets the mark important dates checkbox for discussion', custom_timeout: 25 do
      discussion_title = "Electricity Discussion"
      due_at = 2.days.from_now(Time.zone.now)
      discussion_assignment = create_dated_assignment(@subject_course, discussion_title, due_at, 10)
      graded_discussion = @course.discussion_topics.create!(:title => discussion_title, :assignment => discussion_assignment)

      get "/courses/#{@subject_course.id}/discussion_topics/#{graded_discussion.id}/edit"

      expect(mark_important_dates).to be_displayed
      scroll_to_element(mark_important_dates)
      click_mark_important_dates

      expect_new_page_load { submit_form(edit_discussion_submit_selector) }
    end

    it 'sets the mark important dates checkbox for quiz', custom_timeout: 25 do
      quiz_title = "Electricity Quiz"
      due_at = 2.days.from_now(Time.zone.now)
      quiz = quiz_model(course: @subject_course, title: quiz_title)
      quiz.generate_quiz_data
      quiz.due_at = due_at
      quiz.save!
      quiz_assignment = Assignment.last
      quiz_assignment.update!(important_dates: true)

      get "/courses/#{@subject_course.id}/quizzes/#{quiz.id}/edit"

      expect(mark_important_dates).to be_displayed
      scroll_to_element(mark_important_dates)
      click_mark_important_dates

      expect_new_page_load { submit_form(edit_quiz_submit_selector) }
    end

    it 'shows marked dates enabled when date is added' do
      assignment = create_assignment(@subject_course, "How to make a battery", "battery stuff", 10)
      due_at = 2.days.from_now(Time.zone.now)
      get "/courses/#{@subject_course.id}/assignments/#{assignment.id}/edit"

      expect(mark_important_dates_input).to be_disabled

      scroll_to(date_field[0])
      set_and_tab_out_of_date_field(0, due_at)
      wait_for_ajaximations

      expect(mark_important_dates_input).not_to be_disabled
    end

    it 'grays out and unchecks marked dates when date is removed' do
      due_at = 2.days.from_now(Time.zone.now)
      assignment = create_dated_assignment(@subject_course, "Marked Assignment", due_at)
      assignment.update!(important_dates: true)

      get "/courses/#{@subject_course.id}/assignments/#{assignment.id}/edit"

      clear_date_field(0)
      wait_for_ajaximations

      expect(mark_important_dates_input).to be_disabled
      expect(is_checked(mark_important_dates_selector)).to be_falsey
    end

    it 'enables marked dates checkbox with assignment override' do
      skip("this behavior will be fixed with LS-2378")
      assignment = create_assignment(@subject_course, "How to make a battery", "battery stuff", 10)
      due_at = 2.days.from_now(Time.zone.now)

      get "/courses/#{@subject_course.id}/assignments/#{assignment.id}/edit"

      click_add_override
      expect(mark_important_dates_input).to be_disabled

      set_and_tab_out_of_date_field(1, due_at)
      expect(mark_important_dates_input).not_to be_disabled
    end
  end

  it_behaves_like 'k5 important dates'
end
