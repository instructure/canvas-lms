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

  it "should validate replies are not visible until after users post", priority: "1", test_id: 150533 do
    password = 'asdfasdf'
    student_2_entry = 'reply from student 2'
    topic_title = 'new replies hidden until post topic'

    course_factory
    enable_all_rcs @course.account
    stub_rcs_config
    @course.offer
    student = user_with_pseudonym(:unique_id => 'student@example.com', :password => password, :active_user => true)
    teacher = user_with_pseudonym(:unique_id => 'teacher@example.com', :password => password, :active_user => true)
    @course.enroll_user(student, 'StudentEnrollment').accept!
    @course.enroll_user(teacher, 'TeacherEnrollment').accept!
    create_session(teacher.primary_pseudonym)

    get "/courses/#{@course.id}/announcements"
    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), topic_title)
    type_in_tiny('textarea[name=message]', 'hi, first announcement')
    f('#require_initial_post').click
    wait_for_ajaximations
    expect_new_page_load { submit_form('.form-actions') }
    announcement = Announcement.where(title: topic_title).first
    expect(announcement[:require_initial_post]).to eq true
    student_2 = student_in_course.user
    announcement.discussion_entries.create!(:user => student_2, :message => student_2_entry)

    create_session(student.primary_pseudonym)
    get "/courses/#{@course.id}/announcements/#{announcement.id}"
    expect(f('#discussion_subentries span').text).to eq "Replies are only visible to those who have posted at least one reply."
    ff('.discussion_entry').each { |entry| expect(entry).not_to include_text(student_2_entry) }
    f('.discussion-reply-action').click
    wait_for_ajaximations
    type_in_tiny('textarea', 'reply')
    submit_form('#discussion_topic .discussion-reply-form')
    wait_for_ajaximations
    expect(ff('.discussion_entry .message')[1]).to include_text(student_2_entry)

    unstub_rcs_config
  end

  context "announcements as a student" do
    before (:each) do
      course_with_student_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    after (:each) do
      unstub_rcs_config
    end

    it "should allow a group member to create an announcement", priority: "1", test_id: 220378 do
      gc = group_category
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      get "/groups/#{group.id}/announcements"
      expect {
        create_announcement_option(nil)
        expect_new_page_load { submit_form('.form-actions') }
      }.to change(Announcement, :count).by 1
    end

    it "allows rating when enabled", priority: "1", test_id: 603587 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: true)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f('.discussion-rate-action')).to be_displayed

      f('.discussion-rate-action').click
      wait_for_ajaximations

      expect(f('.discussion-rate-action--checked')).to be_displayed
    end

    it "doesn't allow rating when not enabled", priority: "1", test_id: 603588 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: false)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.discussion-rate-action')
    end
  end
end
