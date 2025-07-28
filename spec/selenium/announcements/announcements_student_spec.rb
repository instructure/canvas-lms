# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/announcements_common"

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  before do
    stub_rcs_config
  end

  context "announcements as a student" do
    before do
      course_with_student_logged_in
    end

    it "does not show an announcements section if there are no announcements", priority: "1" do
      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      expect(f("#content")).not_to contain_css('[data-category="Announcement"]')
    end

    it "does show an announcements section if there are announcements", priority: "1" do
      @course.announcements.create!(title: "Hi there!", message: "Announcement time!")
      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      expect(f("#content")).to contain_css('[data-category="Announcement"]')
    end

    it "validates that a student can not see an announcement with a delayed posting date", priority: "1" do
      announcement_title = "Hi there!"
      announcement = @course.announcements.create!(title: announcement_title, message: "Announcement time!", delayed_post_at: 1.day.from_now)
      get "/courses/#{@course.id}/announcements"

      expect(f("#content")).not_to contain_css(".ic-announcement-row")
      announcement.update(delayed_post_at: nil)
      announcement.reload
      refresh_page # in order to see the announcement
      expect(f(".ic-announcement-row h3")).to include_text(announcement_title)
    end

    it "does not allow a student to close/open announcement for comments or delete an announcement", priority: "1" do
      announcement_title = "Announcement 1"
      @course.announcements.create!(title: announcement_title, message: "Hey")
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css(".ic-item-row__manage-menu")
    end

    it "has deleted announcement removed from student account", priority: "1" do
      @announcement = @course.announcements.create!(title: "delete me", message: "Here is my message")
      get "/courses/#{@course.id}/announcements/"
      expect(f(".ic-announcement-row h3")).to include_text("delete me")
      @announcement.destroy
      get "/courses/#{@course.id}/announcements/"
      expect(f("#content")).not_to contain_css(".ic-announcement-row h3")
    end

    it "removes notifications from unenrolled courses", priority: "1" do
      enable_cache do
        @student.enrollments.first.update_attribute(:workflow_state, "active")
        @course.announcements.create!(title: "Something", message: "Announcement time!")
        get "/"
        f("#DashboardOptionsMenu_Container button").click
        fj('span[role="menuitemradio"]:contains("Recent Activity")').click
        expect(ff(".title .count")[0].text).to eq "1"
        @student.enrollments.first.destroy
        get "/"
        expect(f("#content")).not_to contain_css(".title .count")
      end
    end

    it "allows rating when enabled", priority: "1" do
      announcement = @course.announcements.create!(title: "stuff", message: "things", allow_rating: true)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('[data-testid="discussion-topic-reply"]').click
      wait_for_ajaximations
      wait_for_rce
      type_in_tiny("textarea", "stuff and things")
      f('[data-testid="DiscussionEdit-submit"]').click
      wait_for_ajaximations

      expect(f('[data-testid="like-button"]')).to be_displayed
      expect(f("#content")).to contain_css('[data-action-state="likeButton"]')
      scroll_to(f('[data-testid="like-button"]'))
      f('[data-testid="like-button"]').click
      wait_for_ajaximations

      expect(f("#content")).to contain_css('[data-action-state="unlikeButton"]')
    end

    it "doesn't allow rating when not enabled", priority: "1" do
      announcement = @course.announcements.create!(title: "stuff", message: "things", allow_rating: false)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('[data-testid="discussion-topic-reply"]').click
      wait_for_ajaximations
      wait_for_rce
      type_in_tiny("textarea", "stuff and things")
      f('[data-testid="DiscussionEdit-submit"]').click
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('[data-testid="like-button"]')
    end

    context "section specific announcements" do
      before(:once) do
        course_with_teacher(active_course: true)
        @section = @course.course_sections.create!(name: "test section")

        @announcement = @course.announcements.create!(user: @teacher, message: "hello my favorite section!")
        @announcement.is_section_specific = true
        @announcement.course_sections = [@section]
        @announcement.save!

        @student1, @student2 = create_users(2, return_type: :record)
        @course.enroll_student(@student1, enrollment_state: "active")
        @course.enroll_student(@student2, enrollment_state: "active")
        student_in_section(@section, user: @student1)
      end

      it "is visible to students in the specific section" do
        user_session(@student1)
        get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
        expect(f('[data-testid="message_title"]')).to include_text(@announcement.title)
      end

      it "is not visible to students not in the specific section" do
        user_session(@student2)
        get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
        expect(driver.current_url).to eq course_announcements_url @course
        expect_flash_message :error, "You do not have access to the requested announcement."
      end
    end
  end
end
