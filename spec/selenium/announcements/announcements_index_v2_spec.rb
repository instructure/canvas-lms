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

require_relative '../common'
require_relative './announcement_index_page'

describe "announcements index v2" do
  include_context "in-process server selenium tests"

  context "as a teacher the correct page version is displayed" do
    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    end

    before :each do
      user_session(@teacher)
    end

    it 'when the feature flas is off' do
      AnnouncementIndex.set_section_specific_announcements_flag(@course,'off')
      AnnouncementIndex.visit(@course)
      expect(f('#external_feed_url')).not_to be_nil
    end

    it 'when the feature flag is on' do
      AnnouncementIndex.set_section_specific_announcements_flag(@course,'on')
      AnnouncementIndex.visit(@course)
      expect(f('.announcements-v2__wrapper')).not_to be_nil
    end
  end

  context "as a teacher" do
    announcement1_title = 'Free food!'
    announcement2_title = 'Flu Shot'

    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
      AnnouncementIndex.set_section_specific_announcements_flag(@course,'on')

      # Announcement attributes: title, message, delayed_post_at, allow_rating, user
      @announcement1 = @course.announcements.create!(
        title: announcement1_title,
        message: 'In the cafe!',
        delayed_post_at: 1.day.from_now
      )
      @announcement2 = @course.announcements.create!(
        title: announcement2_title,
        message: 'In the cafe!'
      )
    end

    before :each do
      user_session(@teacher)
      AnnouncementIndex.visit(@course)
    end

    it "announcements can be filtered" do
      skip('Add in with 	COMMS-560')
      AnnouncementIndex.select_filter("Delayed")
      expect(AnnouncementIndex.announcement(announcement1_title)).to be_displayed
      expect(AnnouncementIndex.announcement(announcement2_title)).not_to be_displayed
    end

    it "search by title works correctly" do
      skip('Add in with COMMS-556')
      AnnouncementIndex.enter_search("Free food!")
      expect(AnnouncementIndex.announcement(announcement1_title)).to be_displayed
      expect(AnnouncementIndex.announcement(announcement2_title)).not_to be_displayed
    end

    it "an announcement can be locked for commenting" do
      skip('Add in with COMMS-561')
      AnnouncementIndex.check_announcment(announcement1_title)
      AnnouncementIndex.toggle_lock
      expect(AnnouncementIndex.announcment_locked_icon(announcement1_title)).to be_displayed
      expect(Announcement.where(title: announcement1_title).first.locked).to be true
    end

    it 'multiple announcements can be locked for commenting' do
      skip('Add in with COMMS-561')
      AnnouncementIndex.check_announcment(announcement1_title)
      AnnouncementIndex.check_announcment(announcement2_title)
      AnnouncementIndex.toggle_lock
      expect(AnnouncementIndex.announcment_locked_icon(announcement1_title)).to be_displayed
      expect(AnnouncementIndex.announcment_locked_icon(announcement2_title)).to be_displayed
      expect(Announcement.where(title: announcement1_title).first.locked).to be true
      expect(Announcement.where(title: announcement2_title).first.locked).to be true
    end

    it 'an announcement can be deleted' do
      skip('Add in with COMMS-561')
      AnnouncementIndex.check_announcment(announcement1_title)
      AnnouncementIndex.click_delete
      expect(AnnouncementIndex.announcment_locked_icon(announcement1_title)).not_to be_displayed
      expect(Announcement.where(title: announcement1_title).first.workflow_state).to be 'deleted'
    end

    it 'multiple announcements can be deleted' do
      skip('Add in with COMMS-561')
      AnnouncementIndex.check_announcment(announcement1_title)
      AnnouncementIndex.check_announcment(announcement2_title)
      AnnouncementIndex.click_delete
      expect(AnnouncementIndex.announcment_locked_icon(announcement1_title)).not_to be_displayed
      expect(AnnouncementIndex.announcment_locked_icon(announcement2_title)).not_to be_displayed
      expect(Announcement.where(title: announcement1_title).first.workflow_state).to be 'deleted'
      expect(Announcement.where(title: announcement2_title).first.workflow_state).to be 'deleted'
    end

    it 'clicking the Add Announcement button redirects to new announcement page' do
      skip('Add in with COMMS-562')
      AnnouncementIndex.click_add_announcement
      expect(driver.current_url).to include(AnnouncementIndex.new_announcement_url)
    end

    it 'clicking the announcement goes to the discussion page for that announcement' do
      skip('Add in with COMMS-555')
      AnnouncementIndex.click_on_announcement(announcement1_title)
      expect(driver.current_url).to include(AnnouncementIndex.individual_announcement_url(@announcement1))
    end

    it 'pill on announcement displays correct number of unread replies' do
      skip('Add in with 	COMMS-555')
      # create 2 replies for @announcement1
      expect(AnnouncementIndex.announcement_unread_number(announcement1_title)).to eq 2
    end

    it 'RSS feed info displayed' do
      skip('Add with COMMS-590')
      AnnouncementIndex.open_external_feeds
      ExternalFeed.click_rss_feed_link
      expect(driver.current_url).to include('.atom')
    end

    it 'an external feed can be added' do
      skip('Add with COMMS-589')
      AnnouncementIndex.open_external_feeds
      ExternalFeed.add_external_feed('/someurl', 'Truncated')
      expect(ExternalFeed.feed_name).to be_displayed
    end
  end
end
