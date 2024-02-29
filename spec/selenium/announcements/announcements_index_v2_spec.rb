# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
require_relative "pages/announcement_index_page"
require_relative "pages/external_feed_page"

describe "announcements index v2" do
  include_context "in-process server selenium tests"

  before :once do
    @teacher = user_with_pseudonym(active_user: true)
    course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    course_with_student(course: @course, active_enrollment: true)
    @observer = user_factory(name: "Observer", active_all: true)
    @course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student.id, enrollment_state: "active")

    @announcement1_title = "Free food!"
    @announcement2_title = "Flu Shot"

    # Announcement attributes: title, message, delayed_post_at, allow_rating, user
    @announcement1 = @course.announcements.create!(
      title: @announcement1_title,
      message: "In the cafe!",
      user: @teacher
    )
    @announcement2 = @course.announcements.create!(
      title: @announcement2_title,
      message: "In the cafe!",
      delayed_post_at: 1.day.from_now,
      user: @teacher
    )

    @announcement1.discussion_entries.create!(user: @student, message: "I'm coming!")
    @announcement1.discussion_entries.create!(user: @student, message: "It's already gone! :(")
  end

  context "as a teacher" do
    before do
      user_session(@teacher)
      AnnouncementIndex.visit_announcements(@course.id)
    end

    it "announcements can be filtered", priority: "1" do
      AnnouncementIndex.select_filter("Unread")
      expect(AnnouncementIndex.announcement(@announcement1_title)).to be_displayed
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement2_title))
    end

    it "search by title works correctly", priority: "1" do
      AnnouncementIndex.enter_search("Free food!")
      expect(AnnouncementIndex.announcement(@announcement1_title)).to be_displayed
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement2_title))
    end

    it "an announcement can be locked for commenting", priority: "1" do
      AnnouncementIndex.click_lock_menu(@announcement1_title)
      expect(Announcement.where(title: @announcement1_title).first.locked).to be true
    end

    it "multiple announcements can be locked for commenting", priority: "1" do
      AnnouncementIndex.check_announcement(@announcement1_title)
      AnnouncementIndex.check_announcement(@announcement2_title)
      AnnouncementIndex.toggle_lock
      expect(Announcement.where(title: @announcement1_title).first.locked).to be true
      expect(Announcement.where(title: @announcement2_title).first.locked).to be true
    end

    it "an announcement can be deleted", priority: "1" do
      AnnouncementIndex.click_delete_menu(@announcement1_title)
      AnnouncementIndex.click_confirm_delete
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement1_title))
      expect(Announcement.where(title: @announcement1_title).first.workflow_state).to eq "deleted"
    end

    it "multiple announcements can be deleted", priority: "1" do
      AnnouncementIndex.check_announcement(@announcement1_title)
      AnnouncementIndex.check_announcement(@announcement2_title)
      AnnouncementIndex.click_delete
      AnnouncementIndex.click_confirm_delete
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement1_title))
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement2_title))
      expect(Announcement.where(title: @announcement1_title).first.workflow_state).to eq "deleted"
      expect(Announcement.where(title: @announcement2_title).first.workflow_state).to eq "deleted"
    end

    it "clicking the Add Announcement button redirects to new announcement page", priority: "1" do
      expect_new_page_load { AnnouncementIndex.click_add_announcement }
      expect(driver.current_url).to include(AnnouncementIndex.new_announcement_url)
    end

    it "clicking the announcement goes to the discussion page for that announcement", priority: "1" do
      expect_new_page_load { AnnouncementIndex.click_on_announcement(@announcement1_title) }
      expect(driver.current_url).to include(AnnouncementIndex.individual_announcement_url(@announcement1))
    end

    it "pill on announcement displays correct number of unread replies", priority: "1" do
      expect(AnnouncementIndex.announcement_unread_number(@announcement1_title)).to eq "2"
    end

    it "RSS feed info displayed", priority: "1" do
      AnnouncementIndex.open_external_feeds
      ExternalFeedPage.click_rss_feed_link
      expect(driver.current_url).to include(".atom")
    end

    it "an external feed can be added", priority: "1" do
      AnnouncementIndex.open_external_feeds
      ExternalFeedPage.add_external_feed("http://someurl", "full")
      ExternalFeedPage.add_external_feed("http://otherurl", "full")
      expect(ExternalFeed.all.length).to eq 2
    end

    it "an external feed can be deleted", priority: "1" do
      AnnouncementIndex.open_external_feeds
      ExternalFeedPage.add_external_feed("http://someurl", "full")
      ExternalFeedPage.add_external_feed("http://otherurl", "full")
      ExternalFeedPage.delete_first_feed
      expect(ExternalFeed.all.length).to eq 1
    end
  end

  context "as a student" do
    before do
      user_session(@student)
    end

    it "does not display delayed announcement to student", priority: "1" do
      AnnouncementIndex.visit_announcements(@course.id)
      expect(ff('[data-testid="announcement-reply"]').count).to eq 1
      expect(f("#content")).not_to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement2_title))
    end

    it "does not reply button to use without reply permissions", priority: "1" do
      @course.root_account.role_overrides.create!(permission: "post_to_forum", role: student_role, enabled: false)
      AnnouncementIndex.visit_announcements(@course.id)
      expect(@announcement1.grants_right?(@student, :reply)).to be false
      expect(f("#content")).not_to contain_jqcss("[data-testid=announcement-reply]")
      expect(f("#content")).to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement1_title))
    end
  end

  context "as an observer" do
    before do
      user_session(@observer)
    end

    it "does not display reply for observers", priority: "1" do
      AnnouncementIndex.visit_announcements(@course.id)
      expect(@announcement1.grants_right?(@observer, :reply)).to be false
      expect(f("#content")).not_to contain_jqcss("[data-testid=announcement-reply]")
      expect(f("#content")).to contain_jqcss(AnnouncementIndex.announcement_title_css(@announcement1_title))
    end
  end
end
