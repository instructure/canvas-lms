#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative './announcement_new_edit_page'

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  context "announcements as a teacher" do
    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    end

    before :each do
      user_session(@teacher)
    end

    it "should allow saving of section announcement", test_id:3469728, priority: "1" do
      @course.course_sections.create!(name: "Section 1")
      @course.course_sections.create!(name: "Section 2")
      AnnouncementNewEdit.visit_new(@course)
      AnnouncementNewEdit.select_a_section("Section")
      AnnouncementNewEdit.add_message("Announcement Body")
      AnnouncementNewEdit.add_title("Announcement Title")
      expect_new_page_load {AnnouncementNewEdit.submit_announcement_form}
      expect(driver.current_url).to include(AnnouncementNewEdit.
                                            individual_announcement_url(Announcement.last))
    end

    it "should not allow empty sections", test_id:3469730, priority: "1" do
      @course.course_sections.create!(name: "Section 1")
      @course.course_sections.create!(name: "Section 2")
      AnnouncementNewEdit.visit_new(@course)
      AnnouncementNewEdit.select_a_section("")
      AnnouncementNewEdit.add_message("Announcement Body")
      AnnouncementNewEdit.add_title("Announcement Title")
      expect(AnnouncementNewEdit.section_error).to include("A section is required")
    end

    it "should not show the allow comments checkbox if globally disabled" do
      @course.lock_all_announcements = true
      @course.save!
      AnnouncementNewEdit.visit_new(@course)
      expect { f("#allow_user_comments") }.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
    end

    it "should show the comments checkbox if not globally disabled" do
      AnnouncementNewEdit.visit_new(@course)
      expect { f("#allow_user_comments") }.not_to raise_error
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

      it "should be visible to teacher in course" do
        user_session(@teacher)
        get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
        expect(f(".discussion-title")).to include_text(@announcement.title)
      end
    end

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements" }
      let(:new_url) { "/courses/#{@course.id}/discussion_topics/new?is_announcement=true" }
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
        get new_url
        wait_for_tiny(f('#discussion-edit-view textarea[name=message]'))

        replace_content(f('input[name=title]'), topic_title)
        add_attachment_and_validate
        expect(what_to_create.where(title: topic_title).first.attachment_id).to be_present
      end

      it "should perform front-end validation for message", priority: "1", test_id: 220366 do
        topic_title = 'new topic with file'
        get new_url

        wait_for_tiny(f('#discussion-edit-view textarea[name=message]'))
        replace_content(f('input[name=title]'), topic_title)
        submit_form('.form-actions')
        wait_for_ajaximations

        expect(ff('.error_box').any?{|box| box.text.include?("A message is required")}).to be_truthy
      end

      it "should add an attachment to a graded topic", priority: "1", test_id: 220367 do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
        if what_to_create == DiscussionTopic
          what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
        end
        get url
        expect_new_page_load { f('.ic-announcement-row h3').click }
        expect_new_page_load { f(".edit-btn").click }

        add_attachment_and_validate
      end

      it "should edit a topic", priority: "1", test_id: 150530 do
        edit_name = 'edited discussion name'
        topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get "#{url}/#{topic.id}"
        expect_new_page_load { f(".edit-btn").click }

        edit_announcement(edit_name, 'edit message')
      end
    end

    it "should create a delayed announcement with an attachment", priority: "1", test_id: 150531 do
      AnnouncementNewEdit.visit_new(@course)
      f('input[type=checkbox][name=delay_posting]').click
      replace_content(f('input[name=title]'), "First Announcement")
      type_in_tiny('textarea[name=message]', 'Hi, this is my first announcement')
      f('.ui-datepicker-trigger').click
      datepicker_next
      f('.ui-datepicker-time .ui-datepicker-ok').click
      _, path = get_file('testfile1.txt')
      f('#discussion_attachment_uploaded_data').send_keys(path)
      expect_new_page_load { submit_form('.form-actions') }
      expect(Announcement.last.title).to eq("First Announcement")
      # the delayed post at should be far enough in the future to make this
      # not flaky
      expect(Announcement.last.delayed_post_at > Time.zone.now).to eq true
    end

    it "displayed delayed post note on page of delayed announcement" do
      a = @course.announcements.create!(:title => "Announcement", :message => "foobers",
        :delayed_post_at => 1.week.from_now)
      get AnnouncementNewEdit.full_individual_announcement_url(@course, a)
      expect(f('.discussion-fyi')).to include_text(
        'The content of this announcement will not be visible to users until'
      )
    end

    it "allows delay post date edit with disabled comments", priority: "2", test_id: 3035859 do
      time_new = format_time_for_view(Time.zone.today + 1.day)
      disable_comments_on_announcements
      announcement = @course.announcements.create!(
        title: 'Hello there!', message: 'Hi!', delayed_post_at: time_new
      )
      get [@course, announcement]
      click_edit_btn
      submit_form(f('.form-horizontal'))
      expect(f('.discussion-fyi')).to include_text(time_new)
    end

    it "should remove delayed_post_at when unchecking delay_posting", priority: "1", test_id: 220371 do
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
      f('button[type=submit]').click
      wait_for_ajax_requests
      expect(DiscussionEntry.last.message).to include(entry_text)
    end

    it "should show announcements to student view student", priority: "1", test_id: 220373 do
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

      # As a teacher, verify that you can see the student's reply even though
      # you have not responded
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      expect(ff('.discussion_entry .message')[1]).to include_text(student_entry)
    end
  end
end
