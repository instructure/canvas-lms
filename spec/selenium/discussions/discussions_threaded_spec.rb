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
      if editor_switch_button.text == "Switch to raw HTML Editor"
        editor_switch_button.click
      end
      wait_for_ajaximations
      f("textarea[data-rich_text='true']").send_keys entry_text
      fj("button:contains('Post Reply')").click
      wait_for_ajaximations
      expect(get_all_replies.count).to eq 1
      expect(f("iframe[src='https://example.com']")).to be_present
    end

    it "only respects the 'n' shortcut when no rce editors are open" do
      @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student"
      )
      user_session(@teacher)
      Discussion.visit(@course, @topic)

      # verify n triggered editor to open
      driver.action.send_keys("n").perform
      expect(f(".tox-editor-container")).to be_present

      fj("button:contains('Cancel')").click

      # open the editor for a reply, then put focus outside of editor
      f("a[data-event='addReply']").click
      f("h1").click

      # verify pressing n again does not open an additional editor
      driver.action.send_keys("n").perform
      expect(ff(".tox-editor-container").size).to eq 1
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
      student_enrollment.send(:conclude)
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
      student_enrollment.send(:conclude)
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
      @topic.update_attribute(:posted_at, 2.minutes.ago)

      # Create reply message and reset created_at to one minute ago
      @topic.reply_from(user: @student, html: "New test reply")
      reply = DiscussionEntry.last
      reply.update_attribute(:created_at, 1.minute.ago)

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

      delete_me = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
      Discussion.visit(@course, @topic)
      fj('label[for="showDeleted"]').click

      delete_entry(delete_me)
      expect(f("#entry-#{delete_me.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
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

  context "when discussions redesign feature flag is ON", :ignore_js_errors do
    before :once do
      Account.site_admin.enable_feature! :react_discussions_post
    end

    context "reply flow" do
      before do
        @threaded_topic = create_discussion("threaded discussion", "threaded")
        @first_reply = @threaded_topic.discussion_entries.create!(
          user: @student,
          message: "1st level reply"
        )
        @second_reply = DiscussionEntry.create!(
          message: "2nd level reply",
          discussion_topic_id: @first_reply.discussion_topic_id,
          user_id: @first_reply.user_id,
          root_entry_id: @first_reply.id,
          parent_id: @first_reply.id
        )
        @third_reply = DiscussionEntry.create!(
          message: "3rd level reply",
          discussion_topic_id: @second_reply.discussion_topic_id,
          user_id: @second_reply.user_id,
          root_entry_id: @second_reply.id,
          parent_id: @second_reply.id
        )
        @fourth_reply = DiscussionEntry.create!(
          message: "4th level reply",
          discussion_topic_id: @third_reply.discussion_topic_id,
          user_id: @third_reply.user_id,
          root_entry_id: @third_reply.id,
          parent_id: @third_reply.id
        )
      end

      context "When split screen preference is on - Split Screen View" do
        before :once do
          @student.preferences[:discussions_splitscreen_view] = true
          @student.save!
        end

        before do
          user_session(@student)
          get "/courses/#{@course.id}/discussion_topics/#{@threaded_topic.id}"
        end

        it "replies correctly to discussion topic" do
          f("button[data-testid='discussion-topic-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to topic")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Verify new entry data is correct
          expect(new_reply.depth).to eq 1
          expect(new_reply.parent_id).to be_nil
          expect(new_reply.discussion_topic_id).to eq @threaded_topic.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@first_reply.summary})")).to be_present
        end

        it "replies correctly to first_reply" do
          f("button[data-testid='threading-toolbar-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 1st level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Verify new entry data is correct
          expect(new_reply.depth).to eq 2
          expect(new_reply.parent_id).to eq @first_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@second_reply.summary})")).to be_present
        end

        it "replies correctly to second reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          ff("button[data-testid='threading-toolbar-reply']")[2].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 2nd level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 3
          expect(new_reply.parent_id).to eq @second_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@third_reply.summary})")).to be_present
        end

        it "replies correctly to third reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          ff("button[data-testid='expand-button']")[2].click
          wait_for_ajaximations
          ff("button[data-testid='threading-toolbar-reply']")[2].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 3rd level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Replies to entries at level 3 sets the parent id to be the parent's parent

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 3
          expect(new_reply.parent_id).to eq @second_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@third_reply.summary})")).to be_present
          # Verify that the correct @mentions is created

          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\" data-reactroot=\"\">@#{@third_reply.author_name}</span>replying to 3rd level reply</p>"
        end

        it "replies correctly to fourth reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          ff("button[data-testid='expand-button']")[2].click
          wait_for_ajaximations
          ff("button[data-testid='expand-button']")[1].click
          wait_for_ajaximations
          ff("button[data-testid='threading-toolbar-reply']")[2].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 4th level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Replies to entries deeper than 3 levels, sets the parent to be the root_entry

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 2
          expect(new_reply.parent_id).to eq @first_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@second_reply.summary})")).to be_present
          # Verify that the correct @mentions is created
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\" data-reactroot=\"\">@#{@fourth_reply.author_name}</span>replying to 4th level reply</p>"
        end

        describe "when quoting" do
          it "quotes first_reply correctly" do
            f("button[data-testid='thread-actions-menu']").click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@first_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 1st level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last
            # Verify new entry data is correct
            expect(new_reply.depth).to eq 2
            expect(new_reply.parent_id).to eq @first_reply.id
            expect(new_reply.quoted_entry_id).to eq @first_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@first_reply.summary}')")).to be_present
          end

          it "quotes second_reply correctly" do
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            ff("button[data-testid='thread-actions-menu']")[2].click
            f("span[data-testid='quote']").click
            wait_for_ajaximations
            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@second_reply.summary}')")).to be_present

            type_in_tiny("textarea", "Quoting 2nd level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last
            # Verify new entry data is correct
            expect(new_reply.depth).to eq 3
            expect(new_reply.parent_id).to eq @second_reply.id
            expect(new_reply.quoted_entry_id).to eq @second_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@second_reply.summary}')")).to be_present
          end

          it "quotes third_reply correctly" do
            # Open split-screen view
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            # Open second level replies
            ff("button[data-testid='expand-button']").last.click
            wait_for_ajaximations
            # Quote the 3rd level reply
            ff("button[data-testid='thread-actions-menu']").last.click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@third_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 3rd level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last

            # Verify new entry data is correct
            expect(new_reply.depth).to eq 3
            expect(new_reply.parent_id).to eq @second_reply.id
            expect(new_reply.quoted_entry_id).to eq @third_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@third_reply.summary}')")).to be_present
            # Verify that the correct @mentions is created
            expect(new_reply.message).to include "<p><span class=\"mceNonEditable mention\""
            expect(new_reply.message).to include "data-mention=\"#{@third_reply.user_id}\" data-reactroot=\"\">"
            expect(new_reply.message).to include "@#{@third_reply.author_name}</span>quoting 3rd level reply</p>"
          end

          it "quotes fourth_reply correctly" do
            # Open split-screen view
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            # Open second level replies
            ff("button[data-testid='expand-button']").last.click
            wait_for_ajaximations
            # Open third level replies
            ff("button[data-testid='expand-button']").last.click
            wait_for_ajaximations
            # Quotes the fourst level reply
            ff("button[data-testid='thread-actions-menu']").last.click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@fourth_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 4th level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last

            # Verify new entry data is correct
            expect(new_reply.depth).to eq 2
            expect(new_reply.parent_id).to eq @first_reply.id
            expect(new_reply.quoted_entry_id).to eq @fourth_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@fourth_reply.summary}')")).to be_present
            # Verify that the correct @mentions is created
            expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\" data-reactroot=\"\">@#{@fourth_reply.author_name}</span>quoting 4th level reply</p>"
          end
        end
      end

      context "When split screen preference is off - Inline View" do
        before :once do
          @student.preferences[:discussions_splitscreen_view] = false
          @student.save!
        end

        before do
          user_session(@student)
          get "/courses/#{@course.id}/discussion_topics/#{@threaded_topic.id}"
        end

        it "expands and collapses all correctly" do
          f("button[data-testid='ExpandCollapseThreads-button']").click
          wait_for_ajaximations

          expect(fj("div:contains('1st level reply')")).to be_present
          expect(fj("div:contains('2nd level reply')")).to be_present
          expect(fj("div:contains('3rd level reply')")).to be_present
          expect(fj("div:contains('4th level reply')")).to be_present

          f("button[data-testid='ExpandCollapseThreads-button']").click
          wait_for_ajaximations

          expect(f("body")).not_to contain_jqcss("div:contains('2nd level reply')")
          expect(f("body")).not_to contain_jqcss("div:contains('3rd level reply')")
          expect(f("body")).not_to contain_jqcss("div:contains('4th level reply')")
        end

        it "replies correctly to discussion topic" do
          f("button[data-testid='discussion-topic-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to topic")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Verify new entry data is correct
          expect(new_reply.depth).to eq 1
          expect(new_reply.parent_id).to be_nil
          expect(new_reply.discussion_topic_id).to eq @threaded_topic.id
          expect(new_reply.quoted_entry_id).to be_nil
          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@first_reply.summary})")).to be_present
        end

        it "replies correctly to first_reply" do
          f("button[data-testid='threading-toolbar-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 1st level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Verify new entry data is correct
          expect(new_reply.depth).to eq 2
          expect(new_reply.parent_id).to eq @first_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@second_reply.summary})")).to be_present
        end

        it "replies correctly to second reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          wait_for(method: nil, timeout: 5) { ff("button[data-testid='threading-toolbar-reply']").length >= 3 }
          ff("button[data-testid='threading-toolbar-reply']")[2].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 2nd level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 3
          expect(new_reply.parent_id).to eq @second_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@third_reply.summary})")).to be_present
        end

        it "replies correctly to third reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          wait_for(method: nil, timeout: 5) { ff("button[data-testid='threading-toolbar-reply']").length >= 3 }
          ff("button[data-testid='threading-toolbar-reply']")[2].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 3rd level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Replies to entries at level 3 sets the parent id to be the parent's parent

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 3
          expect(new_reply.parent_id).to eq @second_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@third_reply.summary})")).to be_present
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\" data-reactroot=\"\">@#{@third_reply.author_name}</span>replying to 3rd level reply</p>"
        end

        it "replies correctly to fourth reply" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          wait_for_ajaximations
          wait_for(method: nil, timeout: 5) { ff("button[data-testid='threading-toolbar-reply']").length >= 4 }
          ff("button[data-testid='threading-toolbar-reply']")[3].click
          wait_for_ajaximations
          type_in_tiny("textarea", "replying to 4th level reply")
          f("button[data-testid='DiscussionEdit-submit'").click
          wait_for_ajaximations

          new_reply = DiscussionEntry.last
          # Replies to entries deeper than 3 levels, sets the parent to be the root_entry

          # Verify new entry data is correct
          expect(new_reply.depth).to eq 2
          expect(new_reply.parent_id).to eq @first_reply.id
          expect(new_reply.quoted_entry_id).to be_nil

          # Verify that the correct level is opened
          expect(fj("div:contains(#{new_reply.summary})")).to be_present
          expect(fj("div:contains(#{@second_reply.summary})")).to be_present
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\" data-reactroot=\"\">@#{@fourth_reply.author_name}</span>replying to 4th level reply</p>"
        end

        describe "when quoting" do
          it "quotes first_reply correctly" do
            f("button[data-testid='thread-actions-menu']").click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@first_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 1st level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last
            # Verify new entry data is correct
            expect(new_reply.depth).to eq 2
            expect(new_reply.parent_id).to eq @first_reply.id
            expect(new_reply.quoted_entry_id).to eq @first_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@first_reply.summary}')")).to be_present
          end

          it "quotes second_reply correctly" do
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 2 }
            ff("button[data-testid='thread-actions-menu']")[1].click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@second_reply.summary}')")).to be_present

            type_in_tiny("textarea", "Quoting 2nd level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last

            # Verify new entry data is correct
            expect(new_reply.depth).to eq 3
            expect(new_reply.parent_id).to eq @second_reply.id
            expect(new_reply.quoted_entry_id).to eq @second_reply.id

            # Verify that the correct quote is created after submission
            wait_for(method: nil, timeout: 5) { fj("div[data-testid='reply-preview']:contains('#{@second_reply.summary}')").displayed? }
            expect(fj("div[data-testid='reply-preview']:contains('#{@second_reply.summary}')")).to be_present
          end

          it "quotes third_reply correctly" do
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 3 }
            ff("button[data-testid='thread-actions-menu']")[2].click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@third_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 3rd level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last

            # Verify new entry data is correct
            expect(new_reply.depth).to eq 3
            expect(new_reply.parent_id).to eq @second_reply.id
            expect(new_reply.quoted_entry_id).to eq @third_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@third_reply.summary}')")).to be_present
            expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\" data-reactroot=\"\">@#{@third_reply.author_name}</span>quoting 3rd level reply</p>"
          end

          it "quotes fourth_reply correctly" do
            f("button[data-testid='expand-button']").click
            wait_for_ajaximations
            wait_for_ajaximations
            wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 4 }
            ff("button[data-testid='thread-actions-menu']")[3].click
            f("span[data-testid='quote']").click
            wait_for_ajaximations

            # Verify that it says it'll quote the correct entry
            expect(fj("div[data-testid='reply-preview']:contains('#{@fourth_reply.summary}')")).to be_present

            type_in_tiny("textarea", "quoting 4th level reply")
            f("button[data-testid='DiscussionEdit-submit'").click
            wait_for_ajaximations

            new_reply = DiscussionEntry.last

            # Verify new entry data is correct
            expect(new_reply.depth).to eq 2
            expect(new_reply.parent_id).to eq @first_reply.id
            expect(new_reply.quoted_entry_id).to eq @fourth_reply.id

            # Verify that the correct quote is created after submission
            expect(fj("div[data-testid='reply-preview']:contains('#{@fourth_reply.summary}')")).to be_present
            expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\" data-reactroot=\"\">@#{@fourth_reply.author_name}</span>quoting 4th level reply</p>"
          end
        end
      end
    end

    it "replies with iframe element" do
      user_session(@teacher)

      entry_text = "<iframe src='https://example.com'></iframe>"
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      f('[data-btn-id="rce-edit-btn"]').click
      editor_switch_button = f('[data-btn-id="rce-editormessage-btn"]')
      if editor_switch_button.text == "Switch to raw HTML Editor"
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
        student_enrollment.send(:conclude)
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
      expect(fj("span:contains('Deleted by teacher')")).to be_present
      expect(entry.workflow_state).to eq "deleted"
    end

    it "replies to 3rd level stay 3rd level" do
      topic = create_discussion("flatten 3rd level replies", "threaded")
      first_reply = topic.discussion_entries.create!(
        user: @student,
        message: "1st level reply"
      )
      second_reply = DiscussionEntry.create!(
        message: "2nd level reply",
        discussion_topic_id: first_reply.discussion_topic_id,
        user_id: first_reply.user_id,
        root_entry_id: first_reply.id,
        parent_id: first_reply.id
      )
      third_entry = DiscussionEntry.create!(
        message: "3rd level reply",
        discussion_topic_id: second_reply.discussion_topic_id,
        user_id: second_reply.user_id,
        root_entry_id: second_reply.id,
        parent_id: second_reply.id
      )
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      expect(fj("div:contains('flatten 3rd level replies')")).to be_present
      expect(f("body")).not_to contain_jqcss("div:contains('2nd level reply')")
      f("button[data-testid='expand-button']").click
      wait_for_ajaximations
      wait_for(method: nil, timeout: 5) { ff("button[data-testid='threading-toolbar-reply']").length >= 3 }
      ff("button[data-testid='threading-toolbar-reply']")[2].click
      wait_for_ajaximations
      type_in_tiny("textarea", "replying to 3rd level reply")
      f("button[data-testid='DiscussionEdit-submit'").click
      wait_for_ajaximations
      flattened_reply = DiscussionEntry.last
      expect(flattened_reply.parent_id).to eq third_entry.parent_id
      expect(flattened_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{third_entry.user_id}\" data-reactroot=\"\">@#{third_entry.author_name}</span>replying to 3rd level reply</p>"
    end

    context "replies reporting" do
      it "lets users report replies" do
        skip "FOO-3823"
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

        # make sure nil_participant_entries do not cause the page to 500 and continues to
        # load the good entries instead
        nil_participant = student_in_course(course: @course, name: "Mr Nil", active_all: true).user
        anon_topic.discussion_entries.create!(
          user: nil_participant,
          message: "this a nil participant entry"
        )
        DiscussionTopicParticipant.where(discussion_topic_id: anon_topic.id, user_id: [nil_participant.id]).delete_all

        user_session(@teacher)
        get "/courses/#{@course.id}/discussion_topics/#{anon_topic.id}"
        expect(fj("span[data-testid='non-graded-discussion-info'] span:contains('Anonymous Discussion')")).to be_present

        author_spans = ff("span[data-testid='author_name']")
        authors = author_spans.map(&:text)
        expect(student_entry.author_name).to include "Anonymous "
        expect(authors).to include("teacher", "TA", "Designer", student_entry.author_name)
        expect(authors).not_to include("student")
        expect(authors).not_to include("Mr Nil")
      end
    end

    context "users must post before seeing replies" do
      it "requires a post before seeing replies for students" do
        topic = create_discussion("must see replies", "threaded")
        topic.require_initial_post = true
        topic.save!
        topic.reload
        topic.discussion_entries.create!(
          user: @teacher,
          message: "students can only see this if they reply"
        )
        user_session(@student)
        get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
        expect(fj("div:contains('You must post before seeing replies. Edit history will be available to instructors.')")).to be_present
        expect(f("body")).not_to contain_jqcss("div:contains('students can only see this if they reply')")
        f("button[data-testid='discussion-topic-reply']").click
        type_in_tiny("textarea", "student here")
        fj("button:contains('Reply')").click
        wait_for_ajaximations
        expect(f("body")).to contain_jqcss("div:contains('students can only see this if they reply')")
        expect(f("body")).to contain_jqcss("div:contains('student here')")
      end
    end

    context "locked for comments" do
      it "displays message for students in a discussion that is closed for comments" do
        @topic.lock!
        @topic.message = "This is visible"
        @topic.save!
        user_session(@student)

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(fj("span:contains('#{@topic.message}')")).to be_present
      end
    end
  end
end
