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

describe "teacher k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common

  before :each do
    teacher_setup
  end

  context 'homeroom dashboard standard' do
    it 'enables homeroom for course' do
      get "/courses/#{@course.id}/settings"

      check_enable_homeroom_checkbox
      wait_for_new_page_load { submit_form('#course_form') }

      expect(is_checked(enable_homeroom_checkbox_selector)).to be_truthy
    end

    it 'provides the homeroom dashboard tabs on dashboard' do
      get "/"

      expect(retrieve_welcome_text).to match(/Welcome,/)
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end

    it 'saves tab information for refresh' do
      get "/"

      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
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

      expect(homeroom_course_title_link(@course_name)).to be_displayed
      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
    end

    it 'navigates to homeroom course when homeroom when homeroom title clicked' do
      @course.homeroom_course = true
      @course.save!

      get "/"

      click_homeroom_course_title(@course_name)
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@course.id}")
    end

    it 'navigates to homeroom course announcement edit when announcement button is clicked' do
      @course.homeroom_course = true
      @course.save!

      get "/"

      expect(announcement_button).to be_displayed
      click_announcement_button
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@course.id}/discussion_topics/new?is_announcement=true")
    end

    it 'goes to the homeroom announcement for edit when clicked' do
      @course.homeroom_course = true
      @course.save!
      announcement_title = "K5 Let's do this"
      announcement = new_announcement(@course, announcement_title, "So happy to see all of you.")

      get "/"

      click_announcement_edit_pencil
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@course.id}/discussion_topics/#{announcement.id}/edit")

    end

    it 'shows two different homeroom course announcements for teacher enrolled in two homerooms' do
      @course.homeroom_course = true
      @course.save!
      first_course = @course
      first_course_announcement_title = "K5 Latest"
      announcement_course1 = new_announcement(@course, first_course_announcement_title, "Let's get to work!")

      second_homeroom_course_title = 'Second Teacher Homeroom'
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_homeroom_course_title,
        user: @teacher
      )

      @course.homeroom_course = true
      @course.save!
      second_course_announcement_title = "Homeroom 2"
      announcement_course2 = new_announcement(@course, second_course_announcement_title, "You got this!")

      get "/"

      expect(homeroom_course_title_link(@course_name)).to be_displayed
      expect(announcement_title(first_course_announcement_title)).to be_displayed
      expect(homeroom_course_title_link(second_homeroom_course_title)).to be_displayed
      expect(announcement_title(second_course_announcement_title)).to be_displayed
    end

    it 'does not show homeroom course on dashboard' do
      @course.homeroom_course = true
      @course.save!
      subject_course_title = "Social Studies 4"
      subject_course = Course.create!(name: subject_course_title)
      subject_course.enroll_teacher(@teacher).accept!

      get "/"

      expect(element_exists?(course_card_selector(@course_name))).to eq(false)
      expect(element_exists?(course_card_selector(subject_course_title))).to eq(true)
    end

    context 'announcement attachments with the better file downloading and previewing flags on' do
      before :each do
        Account.site_admin.enable_feature!(:rce_better_file_downloading)
        Account.site_admin.enable_feature!(:rce_better_file_previewing)

        @course.homeroom_course = true
        @course.save!
        attachment_model(uploaded_data: fixture_file_upload("files/example.pdf", "application/pdf"))
        @course.announcements.create!(title: "Welcome to class", message: "Hello!", attachment: @attachment)
      end

      it 'shows download button next to homeroom announcement attachment', custom_timeout: 30 do
        get "/"
        wait_for(method: nil, timeout: 20) { f('span.instructure_file_holder').displayed? }
        expect(f("a.file_download_btn")).to be_displayed
      end

      it 'opens preview overlay when clicking on homeroom announcement attachment' do
        get "/"
        f("a.preview_in_overlay").click
        expect(f("iframe.ef-file-preview-frame")).to be_displayed
      end
    end
  end

  context 'course cards' do
    it 'shows latest announcement on subject course card' do
      new_announcement(@course, "K5 Let's do this", "So happy to see all of you.")
      announcement2 = new_announcement(@course, "K5 Latest", "Let's get to work!")

      get "/"

      expect(course_card_announcement(announcement2.title)).to be_displayed
    end
  end

  context 'homeroom dashboard grades panel' do
    let(:subject_title1) { "Math" }

    before :each do
      @homeroom_course = @course
      @homeroom_course.update!(homeroom_course: true)
      course_with_teacher(active_all: true, user: @teacher, course_name: subject_title1)
      @subject = @course
    end

    it 'shows the subjects the teacher is enrolled in' do
      subject_title2 = "Social Studies"
      course_with_teacher(active_all: true, user: @teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(subject_title1)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
    end

    it 'provides a button to the gradebook for subject teacher is enrolled in' do
      get "/#grades"

      expect(view_grades_button(@subject.id)).to be_displayed
    end

    it 'shows the subjects the TA is enrolled in' do
      course_with_ta(active_all: true, course: @subject)

      get "/#grades"

      expect(subject_grades_title(subject_title1)).to be_displayed
      expect(view_grades_button(@subject.id)).to be_displayed
    end

    it 'show teacher also as student on grades page' do
      subject_title2 = "Teacher Training"
      course_with_student(active_all: true, user: @teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(subject_title1)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
      expect(subject_grade("--")).to be_displayed
    end
  end

  context 'homeroom dashboard resource panel contacts' do
    it 'shows the resource panel staff contacts' do
      @course.homeroom_course = true
      @course.save!
      @course.account.save!

      course_with_ta(
        course: @course,
        active_enrollment: 1
      )

      get "/"

      select_resources_tab

      expect(staff_heading(@teacher.name)).to be_displayed
      expect(instructor_role('Teacher')).to be_displayed

      expect(staff_heading(@ta.name)).to be_displayed
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
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_course_title,
        user: @teacher
      )
      get "/#resources"

      click_k5_button(0)

      expect(course_selection_modal).to be_displayed
      expect(course_list.count).to eq(2)
    end

    it 'shows the LTI resource scoped to the course', ignore_js_errors:true do
      create_lti_resource('New Commons')

      get "/#resources"

      expect(k5_resource_button_names_list).to include 'New Commons'
    end
  end

  context 'teacher schedule' do
    it 'shows a sample preview for teacher view of the schedule tab' do
      get "/#schedule"

      expect(teacher_preview).to be_displayed
    end
  end
end
