# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"

describe "educator announcement creation", :ignore_js_errors, custom_timeout: 30 do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage

  before :once do
    Account.default.enable_feature!(:educator_dashboard)

    @teacher = user_factory(active_all: true, name: "Test Teacher")

    @course1 = course_factory(active_course: true, course_name: "Biology 101")
    @course1.enroll_teacher(@teacher, enrollment_state: :active)

    @course2 = course_factory(active_course: true, course_name: "Chemistry 201")
    @course2.enroll_teacher(@teacher, enrollment_state: :active)

    @no_announce_role = custom_teacher_role("NoAnnouncementsTeacher", account: Account.default)
    @no_announce_role.role_overrides.create!(
      permission: "moderate_forum",
      enabled: false,
      account: Account.default
    )
    @course3 = course_factory(active_course: true, course_name: "Physics 301")
    @course3.enroll_user(@teacher, "TeacherEnrollment", role: @no_announce_role, enrollment_state: :active)
  end

  before do
    user_session(@teacher)
  end

  context "all courses succeed" do
    it "shows success flash alert and closes the modal" do
      open_announcement_modal
      select_course_in_modal("Biology 101")
      select_course_in_modal("Chemistry 201")
      fill_announcement_form(title: "Welcome!", content: "Hello everyone")
      click_announcement_send_button

      expect_instui_flash_message("Announcements created in 2 courses.")
      expect(announcement_modal_open?).to be false
    end
  end

  context "partial success" do
    it "shows success and error flash alerts, keeps modal open with failed courses selected" do
      open_announcement_modal
      select_course_in_modal("Biology 101")
      select_course_in_modal("Physics 301")
      fill_announcement_form(title: "Update", content: "Important update")
      click_announcement_send_button

      expect_instui_flash_message("Announcement created in 1 course.")
      expect_instui_flash_message("1 announcement failed to post. Please check your permissions and try again.")
      expect(announcement_modal_open?).to be true
      expect(announcement_course_tag_exists?(@course3.id)).to be true
    end
  end

  context "total failure" do
    it "shows error flash alert, keeps modal open with all courses selected" do
      open_announcement_modal
      select_course_in_modal("Physics 301")
      fill_announcement_form(title: "Notice", content: "Please read")
      click_announcement_send_button

      expect_instui_flash_message("1 announcement failed to post. Please check your permissions and try again.")
      expect(announcement_modal_open?).to be true
      expect(announcement_course_tag_exists?(@course3.id)).to be true
    end
  end

  context "RCE editor" do
    it "creates an announcement via RCE content" do
      open_announcement_modal
      select_course_in_modal("Biology 101")
      announcement_title_input.send_keys("RCE Announcement")
      type_in_tiny(rce_announcement_textarea_selector, "Hello via RCE")
      click_announcement_send_button

      keep_trying_until { DiscussionTopic.where(context: @course1, title: "RCE Announcement").exists? }
      expect(announcement_modal_open?).to be false
    end

    it "marks the RCE backing textarea as aria-required" do
      open_announcement_modal
      textarea = f(rce_announcement_textarea_selector)
      expect(textarea.attribute("aria-required")).to eq("true")
    end

    it "moves focus into the RCE iframe on empty-content validation error" do
      open_announcement_modal
      select_course_in_modal("Biology 101")
      announcement_title_input.send_keys("Focus Test")
      click_announcement_send_button

      in_frame(rce_announcement_iframe["id"]) do
        expect(driver.switch_to.active_element).to eq(f("body"))
      end
    end
  end
end
