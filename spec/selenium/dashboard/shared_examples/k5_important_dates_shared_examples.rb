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

require_relative "../../common"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../../helpers/shared_examples_common"
require_relative "../pages/k5_important_dates_section_page"

shared_examples_for "k5 important dates" do
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon
  include K5ImportantDatesSectionPageObject

  it "shows the important dates section on the dashboard" do
    get "/"

    expect(important_dates_title).to be_displayed
  end

  it "shows an image when no important dates have been created" do
    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it "shows an important date for an assignment" do
    assignment_title = "Elec HW"
    due_at = 2.days.from_now(Time.zone.now)

    assignment = create_important_date_assignment(@subject_course, assignment_title, due_at)

    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?("IconAssignment")).to be_truthy
    expect(important_date_link).to include_text(assignment_title)
    expect(element_value_for_attr(important_date_link, "href")).to include("/courses/#{@subject_course.id}/assignments/#{assignment.id}")
  end

  it "only shows no dates panda when important dates is not set for assignment" do
    assignment_title = "Elec HW"
    due_at = 2.days.from_now(Time.zone.now)
    create_dated_assignment(@subject_course, assignment_title, due_at)

    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it "shows an important date for a quiz" do
    quiz_title = "Elec Quiz"
    due_at = 2.days.from_now(Time.zone.now)
    quiz = quiz_model(course: @subject_course, title: quiz_title)
    quiz.generate_quiz_data
    quiz.due_at = due_at
    quiz.save!
    quiz_assignment = Assignment.last
    quiz_assignment.update!(important_dates: true)

    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?("IconQuiz")).to be_truthy
    expect(important_date_link).to include_text(quiz_title)
    expect(element_value_for_attr(important_date_link, "href")).to include("/courses/#{@subject_course.id}/assignments/#{quiz_assignment.id}")
  end

  it "shows an important date for a graded discussion" do
    discussion_title = "Elec Disc"
    due_at = 2.days.from_now(Time.zone.now)
    discussion_assignment = create_dated_assignment(@subject_course, discussion_title, due_at, 10)
    @course.discussion_topics.create!(title: discussion_title, assignment: discussion_assignment)
    discussion_assignment.update!(important_dates: true)

    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?("IconDiscussion")).to be_truthy
    expect(important_date_link).to include_text(discussion_title)
    expect(element_value_for_attr(important_date_link, "href")).to include("/courses/#{@subject_course.id}/assignments/#{discussion_assignment.id}")
  end

  it "does not show an important date assignment in the past" do
    assignment_title = "Elec HW"
    due_at = 2.days.ago(Time.zone.now)
    create_important_date_assignment(@subject_course, assignment_title, due_at)

    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it "shows an important date for a calendar event" do
    calendar_event_title = "Elec Event"
    start_at = 2.days.from_now(Time.zone.now)
    calendar_event = create_calendar_event(@subject_course, calendar_event_title, start_at)
    calendar_event.update!(important_dates: true)
    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?("IconCalendarMonth")).to be_truthy
    expect(important_date_link).to include_text(calendar_event_title)
    expect(element_value_for_attr(important_date_link, "href")).to include("/calendar?event_id=#{calendar_event.id}&include_contexts=course_#{@subject_course.id}")
  end

  it "does not show an important date for a calendar event" do
    calendar_event_title = "Elec Event"
    start_at = 2.days.ago(Time.zone.now)
    calendar_event = create_calendar_event(@subject_course, calendar_event_title, start_at)
    calendar_event.update!(important_dates: true)
    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it "shows a specific color icon when color is set for subject" do
    assignment_title = "Elec HW"
    due_at = 2.days.from_now(Time.zone.now)
    create_important_date_assignment(@subject_course, assignment_title, due_at)

    new_color = "#07AB99"
    @subject_course.update!(course_color: new_color)

    get "/"

    expect(hex_value_for_color(assignment_icon, "color")).to eq(new_color)
  end
end

shared_examples_for "k5 important dates calendar picker" do |context|
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon
  include K5ImportantDatesSectionPageObject

  before :once do
    @account.settings[:calendar_contexts_limit] = 2
    @account.save!
  end

  before do
    subject_course_title_prefix = "Subject "
    @new_course_list = []
    case context
    when :student
      2.times do |x|
        course_with_student(
          active_all: true,
          user: @student,
          course_name: "#{subject_course_title_prefix}#{x + 1}"
        )
        @new_course_list << @course
      end
      user_session(@student)
    when :teacher
      2.times do |x|
        course_with_teacher(
          active_course: 1,
          active_enrollment: 1,
          user: @homeroom_teacher,
          course_name: "#{subject_course_title_prefix}#{x + 1}"
        )
        @new_course_list << @course
      end
      user_session(@homeroom_teacher)
    when :observer
      @observer = user_with_pseudonym(name: "Mom", email: "bestmom@example.com", workflow_state: "available")
      add_linked_observer(@student, @observer, root_account: @account)
      # For now, The calendar picker is only available if the observer is viewing his own enrollments
      2.times do |x|
        course_with_student(
          active_all: true,
          user: @observer,
          course_name: "#{subject_course_title_prefix}#{x + 1}"
        )
        @new_course_list << @course
      end
      course_with_student(
        active_all: true,
        user: @observer,
        course: @subject_course
      )
      course_with_student(
        active_all: true,
        user: @observer,
        course: @homeroom_course
      )
      user_session(@observer)
    end
  end

  it "shows the gear if there are more subjects than the limit" do
    get "/"

    expect(calendar_picker_gear).to be_displayed
  end

  it "brings up calendar selection modal when gear is selected" do
    get "/"
    click_calendar_picker_gear

    expect(calendar_modal).to be_displayed
  end

  it "shows the number of calendars allowed for selection" do
    get "/"
    click_calendar_picker_gear

    expect(calendar_choose_text).to include_text("Choose up to 2 subject calendars")
  end

  it "shows the number of calendars left for selection" do
    get "/"
    click_calendar_picker_gear

    expect(calendars_left_text).to include_text("You have 0 calendars left")

    click_subject_calendar_checkbox(0)
    expect(calendars_left_text).to include_text("You have 1 calendar left")
  end

  it "shows the courses in the list" do
    get "/"
    click_calendar_picker_gear

    expect(subject_list_text.sort).to eq([@homeroom_course.name, @subject_course.name, "Subject 1", "Subject 2"].sort)
  end

  it "enables and disables items when calendar max is hit" do
    get "/"
    click_calendar_picker_gear

    expect(subject_list_input[2]).to be_disabled

    click_subject_calendar_checkbox(1)
    expect(subject_list_input[2]).not_to be_disabled
    expect(subject_list_input[1]).not_to be_disabled

    click_subject_calendar_checkbox(2)

    expect(subject_list_input[1]).to be_disabled
  end

  context "important items shown based on calendar selection" do
    before do
      @user.set_preference(:selected_calendar_contexts, [@subject_course.asset_string, @new_course_list[0].asset_string])
    end

    it "submits calendar selections when submit button is clicked", custom_timeout: 25 do
      create_important_date_assignment(@subject_course, "#{@subject_course.name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[0], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[1], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))

      get "/"

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[0].name)

      click_calendar_picker_gear
      click_subject_calendar_checkbox(2)
      click_subject_calendar_checkbox(3)
      click_calendar_modal_submit

      expect(is_calendar_modal_gone?).to be_truthy

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[1].name)
    end

    it "ignore calendar selections when cancel button is clicked", custom_timeout: 20 do
      create_important_date_assignment(@subject_course, "#{@subject_course.name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[0], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[1], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))

      get "/"

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[0].name)

      click_calendar_picker_gear
      click_subject_calendar_checkbox(2)
      click_subject_calendar_checkbox(3)
      click_calendar_modal_cancel

      expect(is_calendar_modal_gone?).to be_truthy

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[0].name)
    end

    it "ignore calendar selections when close button is clicked", custom_timeout: 25 do
      create_important_date_assignment(@subject_course, "#{@subject_course.name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[0], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))
      create_important_date_assignment(@new_course_list[1], "#{@new_course_list[0].name} New Assignment", 2.days.from_now(Time.zone.now))

      get "/"

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[0].name)

      click_calendar_picker_gear
      click_subject_calendar_checkbox(2)
      click_subject_calendar_checkbox(3)
      click_calendar_modal_close

      expect(is_calendar_modal_gone?).to be_truthy

      subject_list = important_date_subject_list
      expect(subject_list[0]).to include_text(@subject_course.name)
      expect(subject_list[1]).to include_text(@new_course_list[0].name)
    end
  end
end
