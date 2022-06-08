# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../common"
require_relative "pages/courses_home_page"

describe "courses" do
  include_context "in-process server selenium tests"
  include CoursesHomePage

  context "as a teacher" do
    before do
      account = Account.default
      account.settings = { open_registration: true, no_enrollments_can_create_courses: true, teachers_can_create_courses: true }
      account.save!
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:new_user_tutorial).and_return(false)
    end

    context "in draft state" do
      before do
        course_with_student_submissions
        @course.default_view = "feed"
        @course.save
      end

      it "allows unpublishing of the course if submissions have no score or grade" do
        visit_course(@course)
        unpublish_btn.click

        wait_for(method: nil, timeout: 5) do
          assert_flash_notice_message("successfully updated")
        end
        expect(unpublish_btn).to have_class("disabled")
      end

      it "loads the users page using ajax", custom_timeout: 30 do
        # Set up the course with > 50 users (to test scrolling)
        create_users_in_course @course, 60
        @course.enroll_user(user_factory, "TaEnrollment")
        visit_course_people(@course)
        wait_for_ajaximations

        expect_no_flash_message :error
        expect(course_user_list.length).to eq 50
      end
    end
  end

  context "as a student" do
    before :once do
      course_with_teacher(active_all: true, name: "discussion course")
      @student = User.create!(name: "First Student")
      @course.enroll_student(@student)
    end

    before do
      user_session(@student)
    end

    it "auto-accepts the course invitation if previews are not allowed", custom_timeout: 20 do
      Account.default.settings[:allow_invitation_previews] = false
      Account.default.save!
      visit_course(@course)
      wait_for_ajaximations

      assert_flash_notice_message "Invitation accepted!"
      expect(course_page_content).not_to contain_css(accept_enrollment_alert_selector)
    end

    it "accepts the course invitation", custom_timeout: 20 do
      Account.default.settings[:allow_invitation_previews] = true
      Account.default.save!
      visit_course(@course)
      wait_for_ajaximations
      accept_enrollment_button.click

      assert_flash_notice_message "Invitation accepted!"
    end

    it "rejects a course invitation", custom_timeout: 20 do
      Account.default.settings[:allow_invitation_previews] = true
      Account.default.save!
      visit_course(@course)
      decline_enrollment_button.click
      wait_for_ajaximations

      assert_flash_notice_message "Invitation canceled."
    end

    describe "course navigation menu" do
      it "collapses and persists when clicking the collapse/expand button" do
        visit_course(@course)
        expect(left_side).to be_displayed
        click_course_menu_toggle
        wait_for_ajax_requests
        expect(left_side).not_to be_displayed
        refresh_page
        expect(left_side).not_to be_displayed
      end

      it "can be expanded when collapsed" do
        @student.preferences[:collapse_course_nav] = true
        @student.save!
        visit_course(@course)
        expect(left_side).not_to be_displayed
        click_course_menu_toggle
        wait_for_ajax_requests
        expect(left_side).to be_displayed
        refresh_page
        expect(left_side).to be_displayed
      end
    end
  end
end
