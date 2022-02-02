# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../helpers/discussions_common"
require_relative "pages/discussion_page"

describe "threaded discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before :once do
    course_with_teacher(active_course: true, active_all: true, name: "teacher")
    @topic_title = "threaded discussion topic"
    @topic = create_discussion(@topic_title, "threaded")
    @student = student_in_course(course: @course, name: "student", active_all: true).user
  end

  before do
    stub_rcs_config
  end

  context "when discussions redesign feature flag is OFF" do
    before :once do
      Account.site_admin.disable_feature! :react_discussions_post
    end

    it "replies with iframe element" do
      user_session(@teacher)
      entry_text = "<iframe src='https://example.com'></iframe>"
      Discussion.visit(@course, @topic)
      f("#discussion_topic").find_element(:css, ".discussion-reply-action").click
      wait_for_ajaximations
      f('[data-btn-id="rce-edit-btn"]').click
      editor_switch_button = f('[data-btn-id="rce-editormessage-btn"]')
      if editor_switch_button.text == "Raw HTML Editor"
        editor_switch_button.click
      end
      wait_for_ajaximations
      f("textarea[data-rich_text='true']").send_keys entry_text
      fj("button:contains('Post Reply')").click
      wait_for_ajaximations
      expect(get_all_replies.count).to eq 1
      expect(f("iframe[src='https://example.com']")).to be_present
    end

    it "allows edits to entries with replies", priority: "2" do
      user_session(@teacher)
      edit_text = "edit message"
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded child reply from student",
        parent_entry: entry
      )
      Discussion.visit(@course, @topic)
      edit_entry(entry, edit_text)
      expect(entry.reload.message).to match(edit_text)
    end

    it "does not allow edits for a concluded student", priority: "2" do
      student_enrollment = course_with_student(
        course: @course,
        user: @student,
        active_enrollment: true
      )
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      user_session(@student)
      Discussion.visit(@course, @topic)
      student_enrollment.send("conclude")
      Discussion.visit(@course, @topic)
      wait_for_ajaximations

      fj("#entry-#{entry.id} .al-trigger").click
      expect(fj(".al-options:visible").text).to include("Edit (Disabled)")
    end

    it "does not allow deletes for a concluded student", priority: "2" do
      student_enrollment = course_with_student(
        course: @course,
        user: @student,
        active_enrollment: true
      )
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      user_session(@student)
      Discussion.visit(@course, @topic)
      student_enrollment.send("conclude")
      Discussion.visit(@course, @topic)
      wait_for_ajaximations

      fj("#entry-#{entry.id} .al-trigger").click
      expect(fj(".al-options:visible").text).to include("Delete (Disabled)")
    end

    it "allows edits to discussion with replies", priority: "1" do
      user_session(@teacher)
      reply_depth = 3
      reply_depth.times do |i|
        @topic.discussion_entries.create!(user: @student,
                                          message: "new threaded reply #{i} from student",
                                          parent_entry: DiscussionEntry.last)
      end
      Discussion.visit(@course, @topic)
      expect_new_page_load { f(".edit-btn").click }
      edit_topic("edited title", "edited message")
      expect(get_all_replies.count).to eq 3
    end

    it "does not allow students to edit replies to a locked topic", priority: "1" do
      user_session(@student)
      entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
      @topic.lock!
      Discussion.visit(@course, @topic)
      wait_for_ajaximations

      fj("#entry-#{entry.id} .al-trigger").click
      wait_for_ajaximations

      expect(fj(".al-options:visible").text).to include("Edit (Disabled)")
    end

    it "shows a reply time that is different from the creation time", priority: "2" do
      user_session(@teacher)
      @enrollment.workflow_state = "active"
      @enrollment.save!

      # Reset discussion created_at time to two minutes ago
      @topic.update_attribute(:posted_at, Time.zone.now - 2.minutes)

      # Create reply message and reset created_at to one minute ago
      @topic.reply_from(user: @student, html: "New test reply")
      reply = DiscussionEntry.last
      reply.update_attribute(:created_at, Time.zone.now - 1.minute)

      # Navigate to discussion URL
      Discussion.visit(@course, @topic)

      replied_at = f(".discussion-pubdate.hide-if-collapsed > time").attribute("data-html-tooltip-title")

      edit_entry(reply, "Reply edited")
      reply.reload
      edited_at = format_time_for_view(reply.updated_at)
      displayed_edited_at = f(".discussion-fyi").text

      # Verify displayed edit time includes object update time
      expect(displayed_edited_at).to include(edited_at)

      # Verify edit time is different than reply time
      expect(replied_at).not_to eql(edited_at)
    end

    it "deletes a reply", priority: "1" do
      user_session(@teacher)

      skip_if_safari(:alert)
      entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
      Discussion.visit(@course, @topic)
      delete_entry(entry)
    end

    it "displays editor name and timestamp after edit", priority: "2" do
      user_session(@teacher)

      skip_if_chrome("needs research: passes locally fails on Jenkins ")
      edit_text = "edit message"
      entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
      Discussion.visit(@course, @topic)
      edit_entry(entry, edit_text)
      wait_for_ajaximations
      expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
    end

    it "supports repeated editing", priority: "2" do
      user_session(@teacher)

      entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
      Discussion.visit(@course, @topic)
      edit_entry(entry, "New text 1")
      expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
      # second edit
      edit_entry(entry, "New text 2")
      entry.reload
      expect(entry.message).to match "New text 2"
    end

    it "re-renders replies after editing", priority: "2" do
      user_session(@teacher)

      edit_text = "edit message"
      entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")

      Discussion.visit(@course, @topic)
      @last_entry = f("#entry-#{entry.id}")
      reply_text = "this is a reply"
      add_reply(reply_text)
      expect { DiscussionEntry.count }.to become(2)
      subentry = DiscussionEntry.last
      refresh_page

      expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy, "precondition"
      edit_entry(entry, edit_text)
      expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy
    end

    it "displays editor name and timestamp after delete", priority: "2" do
      user_session(@teacher)

      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      fj('label[for="showDeleted"]').click
      add_reply(entry_text)
      entry = DiscussionEntry.last
      delete_entry(entry)
      expect(f("#entry-#{entry.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
    end

    context "student tray" do
      before do
        @account = Account.default
      end

      it "discussion page should display student name in tray", priority: "1" do
        topic = @course.discussion_topics.create!(
          user: @teacher,
          title: "Non threaded discussion",
          message: "discussion topic message"
        )
        topic.discussion_entries.create!(
          user: @student,
          message: "new threaded reply from student",
          parent_entry: DiscussionEntry.last
        )
        user_session(@teacher)

        Discussion.visit(@course, topic)
        f("a[data-student_id='#{@student.id}']").click
        expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("student")
      end
    end
  end

  context "when discussions redesign feature flag is ON" do
    before :once do
      Account.site_admin.enable_feature! :react_discussions_post
    end

    it "replies with iframe element" do
      user_session(@teacher)

      entry_text = "<iframe src='https://example.com'></iframe>"
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      f('[data-btn-id="rce-edit-btn"]').click
      editor_switch_button = f('[data-btn-id="rce-editormessage-btn"]')
      if editor_switch_button.text == "Raw HTML Editor"
        editor_switch_button.click
      end
      wait_for_ajaximations
      f("textarea[data-rich_text='true']").send_keys entry_text
      fj("button:contains('Reply')").click
      wait_for_ajaximations
      expect(f("iframe[src='https://example.com']")).to be_present
    end

    it "allows edits to entries with replies" do
      user_session(@teacher)

      edit_text = "edit message"
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded child reply from student",
        parent_entry: entry
      )
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='thread-actions-menu']").click
      fj("li:contains('Edit')").click
      wait_for_ajaximations
      type_in_tiny("textarea", edit_text)
      fj("button:contains('Save')").click
      wait_for_ajax_requests
      expect(entry.reload.message).to match(edit_text)
    end

    context "concluded student" do
      before do
        student_enrollment = course_with_student(
          course: @course,
          user: @student,
          active_enrollment: true
        )
        @topic.discussion_entries.create!(
          user: @student,
          message: "new threaded reply from student"
        )
        student_enrollment.send("conclude")
        user_session(@student)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      end

      it "does not allow editing or deleting for a concluded student" do
        f("button[data-testid='thread-actions-menu']").click
        expect(f("body")).not_to contain_jqcss("li:contains('Edit')")
        expect(f("body")).not_to contain_jqcss("li:contains('Delete')")
      end
    end

    it "does not allow students to edit replies to a locked topic" do
      user_session(@student)
      @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      @topic.lock!
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='thread-actions-menu']").click
      expect(f("body")).not_to contain_jqcss("li:contains('Edit')")
    end

    it "deletes a reply" do
      skip_if_safari(:alert)
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      user_session(@teacher)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='thread-actions-menu']").click
      fj("li:contains('Delete')").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      entry.reload
      expect(entry.workflow_state).to eq "deleted"
    end

    context "replies reporting" do
      before :once do
        Account.site_admin.enable_feature! :discussions_reporting
      end

      it "lets users report replies" do
        @topic.discussion_entries.create!(
          user: @student,
          message: "this is offensive content"
        )
        user_session(@teacher)

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        f("button[data-testid='thread-actions-menu']").click
        fj("li:contains('Report')").click
        expect(fj("h2:contains('Report Reply')")).to be_present

        # side test, click away from modal and make sure it closes
        force_click("button[data-testid='discussion-topic-reply']")
        expect(f("body")).not_to contain_jqcss("h2:contains('Report Reply')")

        # resume main test
        f("button[data-testid='thread-actions-menu']").click
        fj("li:contains('Report')").click
        force_click("input[value='offensive']")
        f("button[data-testid='report-reply-submit-button']").click
        wait_for_ajaximations
        f("button[data-testid='thread-actions-menu']").click
        expect(fj("li:contains('Reported')")).to be_present
      end
    end

    context "fully anonymous discussions" do
      before :once do
        Account.site_admin.enable_feature! :discussion_anonymity
      end

      it "only shows students as anonymous" do
        designer = designer_in_course(course: @course, name: "Designer", active_all: true).user
        ta = ta_in_course(course: @course, name: "TA", active_all: true).user

        anon_topic = @course.discussion_topics.create!(
          user: @teacher,
          title: "Fully Anonymous Topic",
          message: "Teachers, TAs and Designers are anonymized",
          workflow_state: "published",
          anonymous_state: "full_anonymity"
        )

        anon_topic.discussion_entries.create!(
          user: @teacher,
          message: "this a teacher entry"
        )

        anon_topic.discussion_entries.create!(
          user: designer,
          message: "this a designer entry"
        )

        anon_topic.discussion_entries.create!(
          user: ta,
          message: "this a ta entry"
        )

        student_entry = anon_topic.discussion_entries.create!(
          user: @student,
          message: "this a student entry"
        )

        user_session(@teacher)
        get "/courses/#{@course.id}/discussion_topics/#{anon_topic.id}"
        expect(fj("span[data-testid='non-graded-discussion-info'] span:contains('Anonymous Discussion')")).to be_present

        author_spans = ff("span[data-testid='author_name']")
        authors = author_spans.map(&:text)
        expect(student_entry.author_name).to include "Anonymous "
        expect(authors).to include("teacher", "TA", "Designer", student_entry.author_name)
        expect(authors).not_to include("student")
      end
    end
  end
end
