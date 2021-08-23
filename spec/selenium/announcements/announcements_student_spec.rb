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

require_relative '../common'
require_relative '../helpers/announcements_common'

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  before(:each) do
    Account.default.enable_feature!(:rce_enhancements)
    stub_rcs_config
  end

  context "should validate replies are not visible until after users post" do
    before :each do
      course_with_student_logged_in
      topic_title = 'new replies hidden until post topic'
      @announcement = @course.announcements.create!(
        title: topic_title, message: 'blah', require_initial_post: true
      )
      student_2 = student_in_course.user
      @reply = @announcement.discussion_entries.create!(user: student_2, message: 'hello from student 2')
    end

    it "should hide replies if user hasn't posted", priority: "1", test_id: 150533 do
      get "/courses/#{@course.id}/announcements/#{@announcement.id}"
      info_text = "Replies are only visible to those who have posted at least one reply."
      expect(f('#discussion_subentries span').text).to eq info_text
      ff('.discussion_entry').each { |entry| expect(entry).not_to include_text(@reply.message) }
    end

    it "should show replies if user has posted", priority: "1", test_id: 3293301 do
      get "/courses/#{@course.id}/announcements/#{@announcement.id}"
      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny('textarea', 'reply')
      scroll_to_submit_button_and_click('#discussion_topic .discussion-reply-form')
      wait_for_ajaximations
      expect(ff('.discussion_entry .message')[1]).to include_text(@reply.message)
    end
  end

  context "announcements as a student" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should not show an announcements section if there are no announcements", priority: "1", test_id: 150534 do
      get "/courses/#{@course.id}"
      expect(f("#content")).not_to contain_css(".announcements active")
    end

    it "should validate that a student can not see an announcement with a delayed posting date", priority: "1", test_id: 220376 do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"

      expect(f("#content")).not_to contain_css(".ic-announcement-row")
      announcement.update(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      expect(f(".ic-announcement-row h3")).to include_text(announcement_title)
    end

    it "should not allow a student to close/open announcement for comments or delete an announcement", priority: "1", test_id: 220377 do
      announcement_title = "Announcement 1"
      announcement = @course.announcements.create!(:title => announcement_title, :message => "Hey")
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.discussion_actions a.al-trigger')
      expect(f("#content")).not_to contain_css('.discussion_actions ul.al-options')
    end

    it "should have deleted announcement removed from student account", priority: "1", test_id: 220379 do
      @announcement = @course.announcements.create!(:title => 'delete me', :message => 'Here is my message')
      get "/courses/#{@course.id}/announcements/"
      expect(f(".ic-announcement-row h3")).to include_text('delete me')
      @announcement.destroy
      get "/courses/#{@course.id}/announcements/"
      expect(f("#content")).not_to contain_css(".ic-announcement-row h3")
    end

    it "should remove notifications from unenrolled courses", priority: "1", test_id: 220380 do
      enable_cache do
        @student.enrollments.first.update_attribute(:workflow_state, 'active')
        @course.announcements.create!(:title => 'Something', :message => 'Announcement time!')
        get "/"
        f('#DashboardOptionsMenu_Container button').click
        fj('span[role="menuitemradio"]:contains("Recent Activity")').click
        expect(ff('.title .count')[0].text).to eq '1'
        @student.enrollments.first.destroy
        get "/"
        expect(f("#content")).not_to contain_css('.title .count')
      end
    end

    it "allows rating when enabled", priority: "1", test_id: 603587 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: true)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      wait_for_tiny(f("#root_reply_message_for_#{announcement.id}"))
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f('.discussion-rate-action')).to be_displayed
      scroll_to(f('.discussion-rate-action'))
      f('.discussion-rate-action').click
      wait_for_ajaximations

      expect(f('.discussion-rate-action--checked')).to be_displayed
    end

    it "doesn't allow rating when not enabled", priority: "1", test_id: 603588 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: false)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      wait_for_tiny(f("#root_reply_message_for_#{announcement.id}"))
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.discussion-rate-action')
    end

    it "does not display the Subscribe button after replying" do
      announcement = @course.announcements.create!(title: 'Allow Replies', message: 'Reply Here')
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      wait_for_tiny(f("#root_reply_message_for_#{announcement.id}"))
      type_in_tiny('textarea', 'this is my reply')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f('.topic-unsubscribe-button')).not_to be_displayed
      expect(f('.topic-subscribe-button')).not_to be_displayed
    end

    context "section specific announcements" do
      before (:once) do
        course_with_teacher(active_course: true)
        @section = @course.course_sections.create!(name: 'test section')

        @announcement = @course.announcements.create!(:user => @teacher, message: 'hello my favorite section!')
        @announcement.is_section_specific = true
        @announcement.course_sections = [@section]
        @announcement.save!

        @student1, @student2 = create_users(2, return_type: :record)
        @course.enroll_student(@student1, :enrollment_state => 'active')
        @course.enroll_student(@student2, :enrollment_state => 'active')
        student_in_section(@section, user: @student1)
      end

      it "should be visible to students in the specific section" do
        user_session(@student1)
        get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
        expect(f(".discussion-title")).to include_text(@announcement.title)
      end

      it "should not be visible to students not in the specific section" do
        user_session(@student2)
        get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
        expect(driver.current_url).to eq course_announcements_url @course
        expect_flash_message :error, 'You do not have access to the requested announcement.'
      end
    end
  end
end
