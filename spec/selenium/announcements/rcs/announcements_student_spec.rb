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

require_relative '../../common'
require_relative '../../helpers/announcements_common'

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

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
      enable_all_rcs @course.account
      stub_rcs_config
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
    before :each do
      course_with_student_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it "allows rating when enabled", priority: "1", test_id: 603587 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: true)
      announcement.discussion_entries.create!(message: 'reply')
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"
      expect(f('.discussion-rate-action')).to be_displayed

      f('.discussion-rate-action').click
      wait_for_ajaximations
      expect(f('.discussion-rate-action--checked')).to be_displayed
    end

    it "doesn't allow rating when not enabled", priority: "1", test_id: 603588 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: false)
      announcement.discussion_entries.create!(message: 'reply')
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"
      expect(f("#content")).not_to contain_css('.discussion-rate-action')
    end
  end
end
