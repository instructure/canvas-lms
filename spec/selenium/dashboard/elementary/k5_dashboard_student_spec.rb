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
require_relative '../../helpers/k5_common'
require_relative '../../grades/setup/gradebook_setup'

describe "student k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common
  include GradebookSetup

  before :each do
    @account = Account.default
    @account.enable_feature!(:canvas_for_elementary)
    toggle_k5_setting(@account)
    @course_name = "K5 Course"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: 'K5Teacher1'
    )
    course_with_student_logged_in(active_all: true, new_user: true, user_name: 'KTStudent1', course: @course)
  end

  context 'homeroom dashboard standard' do
    it 'provides the homeroom dashboard tabs on dashboard' do
      get "/"

      expect(retrieve_welcome_text).to match(/Welcome,/)
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end

    it 'presents latest homeroom announcements' do
      @course.homeroom_course = true
      @course.save!
      announcement_heading = "K5 Let's do this"
      announcement_content = "So happy to see all of you."
      new_announcement(@course, announcement_heading, announcement_content)

      announcement_heading = "Happy Monday!"
      announcement_content = "Let's get to work"
      new_announcement(@course, announcement_heading, announcement_content)

      get "/"

      expect(homeroom_course_title(@course_name)).to be_displayed
      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
    end

    it 'shows no announcement creation button when there are no announcements' do
      @course.update!(homeroom_course: true)

      get "/"

      expect(announcement_button_exists?).to be_falsey
    end

    it 'dashboard tabs are sticky when scrolling down on homeroom view' do
      @course.update!(homeroom_course: true)

      create_courses(10,enroll_user: @student, return_type: :record)

      get "/"
      wait_for_ajaximations

      driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      wait_for_ajaximations

      expect(retrieve_welcome_text).to match(/Welcome,/)
      expect(homeroom_tab).to be_displayed
    end

    it 'shows 1 assignment due today' do
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

    it 'shows 1 assignment missing today' do
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
  end

  context 'schedule tab' do
    it 'dashboard tabs are sticky when scrolling down on planner view' do
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

  context 'course cards' do
    it 'shows subject course on dashboard' do
      @course.homeroom_course = true
      @course.save!
      subject_course_title = "Social Studies 4"
      course_with_student(active_all: true, user: @student, course_name: subject_course_title)

      get "/"

      expect(element_exists?(course_card_selector(@course_name))).to eq(false)
      expect(element_exists?(course_card_selector(subject_course_title))).to eq(true)
    end

    it 'shows latest announcement on subject course card' do
      new_announcement(@course, "K5 Let's do this", "So happy to see all of you.")
      announcement2 = new_announcement(@course, "K5 Latest", "Let's get to work!")

      get "/"

      expect(course_card_announcement(announcement2.title)).to be_displayed
    end

    it 'navigates to subject when subject card title is clicked' do
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

    it 'shows no assignments due today' do
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
  end

  context 'homeroom dashboard student grades panel' do
    let(:subject_title1) { "Math" }
    let(:math_subject_grade) { "75" }

    before :each do
      @homeroom_course = @course
      @homeroom_course.update!(homeroom_course: true)
      course_with_student(active_all: true, user: @student, course_name: subject_title1)
      @subject = @course
      @assignment = @subject.assignments.create!(
        title: subject_title1,
        description: "General Assignment",
        points_possible: 100,
        submission_types: 'online_text_entry',
        workflow_state: 'published'
      )
      @assignment.submit_homework(@student, {submission_type: "online_text_entry", body: "Here it is"})
    end

    it 'shows the grades panel with two courses' do
      subject_title2 = "Social Studies"
      course_with_student(active_all: true, user: @student, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(subject_title1)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
    end

    it 'shows the grades in default percentage format' do
      @assignment.grade_student(@student, grader: @teacher, score: math_subject_grade, points_deducted: 0)

      get "/#grades"

      expect(subject_grade(math_subject_grade + "%")).to be_displayed
    end

    it 'shows the grades with a different grading scheme' do
      grading_standard = @subject.grading_standards.create!(
        title: "Fun Grading Standard",
        standard_data: {
          "scheme_0" => { name: "Awesome", value: "90" },
          "scheme_1" => { name: "Fabulous", value: "80" },
          "scheme_2" => { name: "You got this", value: "70" },
          "scheme_3" => { name: "See me", value: "0" }
        }
      )
      @subject.update!(grading_standard_enabled: true, grading_standard_id: grading_standard.id)

      @assignment.grade_student(@student, grader: @teacher, score: math_subject_grade, points_deducted: 0)

      scheme_subject_grade = "You got this"
      get "/#grades"

      expect(subject_grade(scheme_subject_grade)).to be_displayed
    end

    it 'shows the grades for a different grading period' do
      @course = @subject
      create_grading_periods('Fall Term')
      associate_course_to_term("Fall Term")
      @assignment.update!(due_at: 1.week.ago)
      @assignment.grade_student(@student, grader: @teacher, score: "90", points_deducted: 0)

      get "/#grades"

      click_option(grading_period_dropdown_selector, "GP Ended")

      expect(subject_grade("90%")).to be_displayed
    end

    it 'shows two dashes and empty progress bar if no grades are available for a course' do
      get "/#grades"

      expect(subject_grade("--")).to be_displayed
      expect(grade_progress_bar("0")).to be_displayed
    end

    it 'show the progress bar with the appropriate progress' do
      @assignment.grade_student(@student, grader: @teacher, score: math_subject_grade, points_deducted: 0)

      get "/#grades"

      expect(grade_progress_bar(math_subject_grade)).to be_displayed
    end
  end

  context 'homeroom dashboard resource panel' do
    it 'shows the resource panel staff contacts' do
      @course.homeroom_course = true
      @course.save!
      @course.account.save!

      course_with_ta(
        course: @course,
        active_enrollment: 1
      )

      @teacher.email = 'teacher_person@example.com'
      @teacher.save!

      @ta.email = 'ta_person@example.com'
      @ta.save!

      get "/"

      select_resources_tab

      expect(staff_heading(@teacher.name)).to be_displayed
      # expect(email_link(@teacher.email)).to be_displayed
      expect(instructor_role('Teacher')).to be_displayed

      expect(staff_heading(@ta.name)).to be_displayed
      # expect(email_link(@ta.email)).to be_displayed
      expect(instructor_role('Teaching Assistant')).to be_displayed
    end

    it 'shows the bio for a contact if the profiles are enabled' do
      @course.homeroom_course = true
      @course.save!
      @course.account.settings[:enable_profiles] = true
      @course.account.save!

      user_profile = @teacher.profile

      bio = 'teacher profile bio'
      title = 'teacher profile title'

      user_profile.bio = bio
      user_profile.title = title
      user_profile.save!

      get "/#resources"

      expect(instructor_bio(bio)).to be_displayed
    end

    it 'allows student to send message to teacher', custom_timeout: 20 do
      @course.homeroom_course = true
      @course.save!

      get "/#resources"

      click_message_button

      expect(message_modal_displayed?(@teacher.name)).to be_truthy

      expect(is_send_available?).to be_falsey

      replace_content(subject_input, 'need help')
      replace_content(message_input, 'hey teach, I really need help with these fractions.')

      expect(is_send_available?).to be_truthy

      click_send_button

      wait_for_ajaximations

      expect(is_modal_gone?(@teacher.name)).to be_truthy
      expect(Conversation.count).to eq(1)
    end

    it 'allows student to cancel message to teacher' do
      @course.homeroom_course = true
      @course.save!

      get "/#resources"

      click_message_button

      expect(is_cancel_available?).to be_truthy

      replace_content(subject_input, 'need help')
      replace_content(message_input, 'hey teach, I really need help with these fractions.')

      click_cancel_button

      wait_for_ajaximations

      expect(is_modal_gone?(@teacher.name)).to be_truthy
      expect(Conversation.count).to eq(0)
    end
  end

  context 'homeroom dashboard resource panel LTI resources' do
    before :each do
      @lti_resource_name = 'Commons'
      create_lti_resource(@lti_resource_name)
    end

    it 'shows the LTI resources for account and course on resources page' do
      get "/#resources"

      expect(k5_app_buttons[0].text).to eq @lti_resource_name
    end

    it 'shows course modal to choose which LTI resource context when button clicked', ignore_js_errors:true do
      second_course_title = 'Second Course'
      course_with_student(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_course_title,
        user: @student
      )
      get "/#resources"

      click_k5_button(0)

      expect(course_selection_modal).to be_displayed
      expect(course_list.count).to eq(2)
    end
  end
end
