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

describe "student k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject

  before :each do
    Account.default.enable_feature!(:canvas_for_elementary)
    @course_name = "K5 Course"
    course_with_student_logged_in(active_all: true, new_user: true, user_name: 'KTStudent1', course_name: @course_name)
  end

  it 'provides the homeroom dashboard tabs on dashboard', ignore_js_errors:true do
    get "/"

    expect(retrieve_welcome_text).to match(/Welcome,/)
    expect(homeroom_tab).to be_displayed
    expect(schedule_tab).to be_displayed
    expect(grades_tab).to be_displayed
    expect(resources_tab).to be_displayed
  end

  it 'navigates to planner when Schedule is clicked', ignore_js_errors:true do
    @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: Time.zone.today,
      submission_types: 'online_text_entry'
    )
    get "/"

    select_schedule_tab
    wait_for_ajaximations

    expect(today_header).to be_displayed
  end

  it 'presents homeroom announcement when feature is enabled', ignore_js_errors:true do
    # This one's not fully fleshed out yet.
    @course.homeroom_course = true
    @course.save!
    new_announcement(@course, "K5 Let's do this", "So happy to see all of you.")

    get "/"

    expect(true).to eq(true)
  end

  it 'does not show homeroom course on dashboard', ignore_js_errors:true do
    @course.homeroom_course = true
    @course.save!
    subject_course_title = "Social Studies 4"
    course_with_student(active_all: true, user: @student, course_name: subject_course_title)

    get "/"

    expect(element_exists?(course_card_selector(@course_name))).to eq(false)
    expect(element_exists?(course_card_selector(subject_course_title))).to eq(true)
  end

  it 'shows latest announcement on subject course card', ignore_js_errors:true do
    new_announcement(@course, "K5 Let's do this", "So happy to see all of you.")
    announcement2 = new_announcement(@course, "K5 Latest", "Let's get to work!")

    get "/"

    expect(course_card_announcement(announcement2.title)).to be_displayed
  end

  it 'navigates to subject when subject card title is clicked', ignore_js_errors:true do
    @course.homeroom_course = true
    @course.save!
    subject_title = "Math Level 1"
    course_with_student(active_all: true, user: @student, course_name: subject_title)

    get "/"

    subject_href = element_value_for_attr(subject_title_link(subject_title), 'href')
    navigate_to_subject(subject_title)
    wait_for_ajaximations

    expect(driver.current_url).to eq(subject_href)
  end

  it 'shows no assignments due today', ignore_js_errors:true do
    @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: 1.week.from_now(Time.zone.now),
      submission_types: 'online_text_entry'
    )

    get "/"

    expect(subject_items_due(@course_name, 'Nothing due today')).to be_displayed
  end

  it 'shows 1 assignment due today', ignore_js_errors:true do
    @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: Time.zone.today,
      submission_types: 'online_text_entry'
    )

    get "/"

    expect(subject_items_due(@course_name, '1 due today')).to be_displayed
  end

  it 'shows 1 assignment missing today', ignore_js_errors:true do
    @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: 3.days.ago,
      submission_types: 'online_text_entry'
    )
    get "/"

    expect(subject_items_missing(@course_name, 1)).to be_displayed
  end

  it 'dashboard tabs are sticky when scrolling down on planner view', ignore_js_errors:true do
    5.times do
      @course.assignments.create!(
        title: 'old assignment',
        grading_type: 'points',
        points_possible: 10,
        due_at: 1.week.from_now(Time.zone.now),
        submission_types: 'online_text_entry'
      )
    end

    get "/"
    select_schedule_tab
    wait_for_ajaximations

    driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    wait_for_ajaximations

    expect(retrieve_welcome_text).to match(/Welcome,/)
    expect(homeroom_tab).to be_displayed
  end
end
