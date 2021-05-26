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

  before :once do
    teacher_setup
  end

  before :each do
    user_session @homeroom_teacher
  end

  context 'homeroom dashboard standard' do
    it 'shows homeroom enabled for course', ignore_js_errors: true do
      get "/courses/#{@homeroom_course.id}/settings"

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

    it 'navigates to homeroom course when homeroom when homeroom title clicked' do
      get "/"

      click_homeroom_course_title(@course_name)
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@homeroom_course.id}")
    end

    it 'does not show homeroom course on dashboard' do
      get "/"

      expect(element_exists?(course_card_selector(@course_name))).to eq(false)
      expect(element_exists?(course_card_selector(@subject_course_title))).to eq(true)
    end
  end

  context 'homeroom announcements' do
    it 'presents latest homeroom announcements' do
      announcement_heading = "K5 Let's do this"
      announcement_content = "So happy to see all of you."
      new_announcement(@homeroom_course, announcement_heading, announcement_content)

      announcement_heading = "Happy Monday!"
      announcement_content = "Let's get to work"
      new_announcement(@homeroom_course, announcement_heading, announcement_content)

      get "/"

      expect(homeroom_course_title_link(@course_name)).to be_displayed
      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
    end

    it 'navigates to homeroom course announcement edit when announcement button is clicked' do
      get "/"

      expect(announcement_button).to be_displayed
      click_announcement_button
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@homeroom_course.id}/discussion_topics/new?is_announcement=true")
    end

    it 'goes to the homeroom announcement for edit when clicked' do
      announcement_title = "K5 Let's do this"
      announcement = new_announcement(@homeroom_course, announcement_title, "So happy to see all of you.")

      get "/"

      click_announcement_edit_pencil
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@homeroom_course.id}/discussion_topics/#{announcement.id}/edit")
    end

    it 'shows two different homeroom course announcements for teacher enrolled in two homerooms' do
      first_course_announcement_title = "K5 Latest"
      new_announcement(@homeroom_course, first_course_announcement_title, "Let's get to work!")

      second_homeroom_course_title = 'Second Teacher Homeroom'
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_homeroom_course_title,
        user: @homeroom_teacher
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

    context 'announcement attachments with the better file downloading and previewing flags on' do
      before :once do
        Account.site_admin.enable_feature!(:rce_better_file_downloading)
        Account.site_admin.enable_feature!(:rce_better_file_previewing)

        attachment_model(uploaded_data: fixture_file_upload("files/example.pdf", "application/pdf"))
        @homeroom_course.announcements.create!(title: "Welcome to class", message: "Hello!", attachment: @attachment)
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
      new_announcement(@subject_course, "K5 Let's do this", "So happy to see all of you.")
      announcement2 = new_announcement(@subject_course, "K5 Latest", "Let's get to work!")

      get "/"

      expect(course_card_announcement(announcement2.title)).to be_displayed
    end

    it 'shows course color selection on dashboard card' do
      new_color = '#07AB99'
      @subject_course.update!(course_color: new_color)

      get "/"

      expect(hex_value_for_color(dashboard_card)).to eq(new_color)
    end
  end

  context 'homeroom dashboard grades panel' do
    it 'shows the subjects the teacher is enrolled in' do
      subject_title2 = "Social Studies"
      course_with_teacher(active_all: true, user: @homeroom_teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
    end

    it 'provides a button to the gradebook for subject teacher is enrolled in' do
      get "/#grades"

      expect(view_grades_button(@subject_course.id)).to be_displayed
    end

    it 'shows the subjects the TA is enrolled in' do
      course_with_ta(active_all: true, course: @subject_course)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(view_grades_button(@subject_course.id)).to be_displayed
    end

    it 'show teacher also as student on grades page' do
      subject_title2 = "Teacher Training"
      course_with_student(active_all: true, user: @homeroom_teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
      expect(subject_grade("--")).to be_displayed
    end
  end

  context 'homeroom dashboard resource panel contacts' do
    it 'shows the resource panel staff contacts' do
      course_with_ta(
        course: @homeroom_course,
        active_enrollment: 1
      )

      get "/"

      select_resources_tab

      expect(staff_heading(@homeroom_teacher.name)).to be_displayed
      expect(instructor_role('Teacher')).to be_displayed

      expect(staff_heading(@ta.name)).to be_displayed
      expect(instructor_role('Teaching Assistant')).to be_displayed
    end

    it 'shows the bio for a contact if the profiles are enabled' do
      @homeroom_course.account.settings[:enable_profiles] = true
      @homeroom_course.account.save!

      user_profile = @homeroom_teacher.profile

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
    let(:lti_resource_name) { 'Commons' }


    before :once do
      create_lti_resource(lti_resource_name)
    end

    it 'shows the LTI resources for account and course on resources page' do
      get "/#resources"

      expect(k5_app_buttons[0].text).to eq lti_resource_name
    end

    it 'shows course modal to choose which LTI resource context when button clicked', ignore_js_errors:true do
      second_course_title = 'Second Course'
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_course_title,
        user: @homeroom_teacher
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

    it 'shows a sample preview for teacher view of the course schedule tab' do
      get "/courses/#{@subject_course.id}#schedule"

      expect(teacher_preview).to be_displayed
    end
  end
end
