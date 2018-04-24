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

  context "announcements as a teacher" do
    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
      enable_all_rcs @course.account
    end

    before :each do
      user_session(@teacher)
      stub_rcs_config
    end

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

      before :once do
        @topic_title = 'new discussion'
        @context = @course
      end

      it "should start a new topic", priority: "1", test_id: 150528 do
        get url

        expect_new_page_load { f('#add_announcement').click }
        edit_announcement(@topic_title, 'new topic')
      end

      it "should add an attachment to a new topic", priority: "1", test_id: 150529 do
        topic_title = 'new topic with file'
        get url

        expect_new_page_load { f('#add_announcement').click }
        replace_content(f('input[name=title]'), topic_title)
        add_attachment_and_validate
        expect(what_to_create.where(title: topic_title).first.attachment_id).to be_present
      end

      it "should perform front-end validation for message", priority: "1", test_id: 220366 do
        topic_title = 'new topic with file'
        get url

        expect_new_page_load { f('#add_announcement').click }
        replace_content(f('input[name=title]'), topic_title)
        filename, fullpath, data = get_file("testfile5.zip")
        f('input[name=attachment]').send_keys(fullpath)
        submit_form('.form-actions')
        wait_for_ajaximations

        expect(ff('.error_box').any?{|box| box.text.include?("A message is required")}).to be_truthy
      end

      it "should add an attachment to a graded topic", priority: "1", test_id: 220367 do # no
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
        if what_to_create == DiscussionTopic
          what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
        end
        get url
        expect_new_page_load { f('.ic-announcement-row h3').click }
        expect_new_page_load { f(".edit-btn").click }

        add_attachment_and_validate
      end

      it "should edit a topic", priority: "1", test_id: 150530 do # no
        edit_name = 'edited discussion name'
        topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get url + "#{topic.id}"
        expect_new_page_load { f(".edit-btn").click }

        edit_announcement(edit_name, 'edit message')
      end
    end

    it "should remove delayed_post_at when unchecking delay_posting", priority: "1", test_id: 220371 do # no
      topic = @course.announcements.create!(:title => @topic_title, :user => @user, :delayed_post_at => 10.days.ago, :message => "message")
      get "/courses/#{@course.id}/announcements/#{topic.id}"
      expect_new_page_load { f(".edit-btn").click }

      f('input[type=checkbox][name="delay_posting"]').click
      expect_new_page_load { f('.form-actions button[type=submit]').click }

      topic.reload
      expect(topic.delayed_post_at).to be_nil
    end

    it "lets a teacher add a new entry to its own announcement", priority: "1", test_id: 220372 do
      create_announcement
      get [@course, @announcement]
      f('.discussion-reply-action').click
      entry_text = 'new entry text'
      type_in_tiny('textarea', entry_text)
      scroll_to_submit_button_and_click('#discussion_topic .discussion-reply-form')
      wait_for_ajax_requests
      expect(DiscussionEntry.last.message).to include(entry_text)
    end

    it "should show announcements to student view student", priority: "1", test_id: 220373 do # no
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('.ic-announcement-row')
      expect(announcement.find_element(:css, '.ic-announcement-row__content')).to include_text(@announcement.message)
    end

    it "should always see student replies when 'initial post required' is turned on", priority: "1", test_id: 150524 do
      skip_if_chrome('Student view breaks this test')
      student_entry = 'this is my reply'

      create_announcement_initial

      # Create reply as a student
      enter_student_view
      reply_to_announcement(@announcement.id, student_entry)
      leave_student_view

      #As a teacher, verify that you can see the student's reply even though you have not responded
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      expect(ff('.discussion_entry .message')[1]).to include_text(student_entry)
    end

    it "should create an announcement that requires an initial post", priority: "1", test_id: 3293292 do
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      replace_content(f('input[name=title]'), 'title')
      type_in_tiny('textarea[name=message]', 'hi')
      f('#allow_user_comments').click
      f('#require_initial_post').click
      expect_new_page_load { submit_form('.form-actions') }
      announcement = Announcement.where(title: 'title').first
      expect(announcement.require_initial_post).to eq(true)
    end
  end
end
