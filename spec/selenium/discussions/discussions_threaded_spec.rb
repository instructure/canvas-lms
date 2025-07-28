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
require_relative "../rcs/pages/rce_next_page"

describe "threaded discussions", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before :once do
    Account.site_admin.enable_feature! :discussion_create
    course_with_teacher(active_course: true, active_all: true, name: "teacher")
    @topic_title = "threaded discussion topic"
    @topic = create_discussion(@topic_title, "threaded")
    @student = student_in_course(course: @course, name: "student", active_all: true).user
  end

  before do
    stub_rcs_config
  end

  context "not-threaded discussion" do
    before do
      user_session(@student)
      @topic = create_discussion("not_threaded discussion", "not_threaded")
      @first_reply = @topic.discussion_entries.create!(
        user: @student,
        message: "1st level reply"
      )
      Discussion.visit(@course, @topic)
    end

    it "does not display reply button in threading toolbar" do
      expect(f("body")).not_to contain_jqcss("button[data-testid='threading-toolbar-reply']:contains('Reply')")
    end
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

      it "debounces the entry creation" do
        # Click reply button
        f("button[data-testid='discussion-topic-reply']").click
        wait_for_ajaximations

        entry_count = @threaded_topic.discussion_entries.count

        # Type content
        reply_content = "This is a reply to topic that should not be lost."
        type_in_tiny("textarea", reply_content)

        # Try to submit the reply
        f("button[data-testid='DiscussionEdit-submit']")

        # Simulate multiple rapid clicks using JavaScript
        driver.execute_script(<<~JS)
          let button = document.querySelector("button[data-testid='DiscussionEdit-submit']");
          let event = new MouseEvent('click', {
            view: window,
            bubbles: true,
            cancelable: true
          });
          for (let i = 0; i < 2; i++) {
            button.dispatchEvent(event);
          }
        JS

        wait_for_ajaximations

        expect(@threaded_topic.discussion_entries.count).to eq entry_count + 1
      end

      describe "Discussion replies with network interruptions" do
        after do
          turn_on_network
        end

        it "preserves reply content to discussion topic reply when network is interrupted" do
          # Click reply button
          f("button[data-testid='discussion-topic-reply']").click
          wait_for_ajaximations

          # Type content
          reply_content = "This is a reply to topic that should not be lost."
          type_in_tiny("textarea", reply_content)

          # Simulate offline mode
          turn_off_network

          # Try to submit the reply
          f("button[data-testid='DiscussionEdit-submit']").click

          # Expect error to occur
          expect(fj("div:contains('There was an unexpected error creating the discussion entry.')")).to be_present
          # Expect RCE to still be open
          expect(f("div[data-testid='DiscussionEdit-container']")).to be_present
          # Expect the typed content to still be there
          in_frame f(".tox-editor-container iframe")["id"] do
            expect(f("body")).to include_text("This is a reply to topic that should not be lost.")
          end
        end

        it "preserves reply content to discussion entry reply when network is interrupted" do
          f("button[data-testid='threading-toolbar-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "This is a reply to a 1st level reply that should not be lost.")

          # Simulate offline mode
          turn_off_network

          # Try to submit the reply
          f("button[data-testid='DiscussionEdit-submit']").click

          # Expect error to occur
          expect(fj("div:contains('There was an unexpected error creating the discussion entry.')")).to be_present
          # Expect RCE to still be open
          expect(f("div[data-testid='DiscussionEdit-container']")).to be_present
          # Expect the typed content to still be there
          in_frame f(".tox-editor-container iframe")["id"] do
            expect(f("body")).to include_text("This is a reply to a 1st level reply that should not be lost.")
          end
        end

        it "preserves edit content to discussion entry edit when network is interrupted" do
          f("button[data-testid='expand-button']").click
          wait_for_ajaximations
          ff("button[data-testid='thread-actions-menu']").second.click
          f("span[data-testid='edit']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "This is an edit that should not be lost.")

          # Simulate offline mode
          turn_off_network

          # Try to submit the reply
          f("button[data-testid='DiscussionEdit-submit']").click

          # Expect error to occur
          expect(fj("div:contains('There was an unexpected error while updating the reply.')")).to be_present
          # Expect RCE to still be open
          expect(f("div[data-testid='DiscussionEdit-container']")).to be_present
          # Expect the typed content to still be there
          in_frame f(".tox-editor-container iframe")["id"] do
            expect(f("body")).to include_text(@first_reply.message + "This is an edit that should not be lost.")
          end
        end
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

        expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\">@#{@third_reply.author_name}</span>replying to 3rd level reply</p>"
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
        expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\">@#{@fourth_reply.author_name}</span>replying to 4th level reply</p>"
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
          expect(new_reply.message).to include "data-mention=\"#{@third_reply.user_id}\""
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
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\">@#{@fourth_reply.author_name}</span>quoting 4th level reply</p>"
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

      describe "Discussion replies with network interruptions" do
        after do
          turn_on_network
        end

        it "preserves reply content to 1st level discussion entry reply that has no existing subEntries when network is interrupted" do
          @second_first_level_reply = @threaded_topic.discussion_entries.create!(
            user: @student,
            message: "2nd - 1st level reply"
          )
          get "/courses/#{@course.id}/discussion_topics/#{@threaded_topic.id}"

          ff("button[data-testid='threading-toolbar-reply']")[0].click
          wait_for_ajaximations
          type_in_tiny("textarea", "This is a reply to a 1st level reply that should not be lost.")

          # Simulate offline mode
          turn_off_network

          # Try to submit the reply
          f("button[data-testid='DiscussionEdit-submit']").click

          # Expect error to occur
          expect(fj("div:contains('There was an unexpected error creating the discussion entry.')")).to be_present
          # Expect RCE to still be open
          expect(f("div[data-testid='DiscussionEdit-container']")).to be_present
          # Expect the typed content to still be there
          in_frame f(".tox-editor-container iframe")["id"] do
            expect(f("body")).to include_text("This is a reply to a 1st level reply that should not be lost.")
          end
        end

        it "preserves reply content to discussion entry reply when network is interrupted" do
          f("button[data-testid='threading-toolbar-reply']").click
          wait_for_ajaximations
          type_in_tiny("textarea", "This is a reply to a 1st level reply that should not be lost.")

          # Simulate offline mode
          turn_off_network

          # Try to submit the reply
          f("button[data-testid='DiscussionEdit-submit']").click

          # Expect error to occur
          expect(fj("div:contains('There was an unexpected error creating the discussion entry.')")).to be_present
          # Expect RCE to still be open
          expect(f("div[data-testid='DiscussionEdit-container']")).to be_present
          # Expect the typed content to still be there
          in_frame f(".tox-editor-container iframe")["id"] do
            expect(f("body")).to include_text("This is a reply to a 1st level reply that should not be lost.")
          end
        end
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
        wait_for(method: nil, timeout: 7) { ff("button[data-testid='threading-toolbar-reply']").length >= 3 }
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
        expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\">@#{@third_reply.author_name}</span>replying to 3rd level reply</p>"
      end

      it "replies correctly to fourth reply" do
        f("button[data-testid='expand-button']").click
        wait_for_ajaximations
        wait_for_ajaximations
        wait_for(method: nil, timeout: 7) { ff("button[data-testid='threading-toolbar-reply']").length >= 4 }
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
        expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\">@#{@fourth_reply.author_name}</span>replying to 4th level reply</p>"
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
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@third_reply.user_id}\">@#{@third_reply.author_name}</span>quoting 3rd level reply</p>"
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
          expect(new_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{@fourth_reply.user_id}\">@#{@fourth_reply.author_name}</span>quoting 4th level reply</p>"
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
    fj("[class*=menuItem__label]:contains('Edit')").click
    wait_for_ajaximations
    type_in_tiny("textarea", edit_text)
    fj("button:contains('Save')").click
    wait_for_ajax_requests
    expect(entry.reload.message).to match(edit_text)
    expect(f("span[data-testid='editedByText']").text).to include "Edited by teacher"
  end

  it "can show edited replies without edited by in anonymous discussions" do
    @topic.anonymous_state = "full_anonymity"
    @topic.save!

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
    fj("[class*=menuItem__label]:contains('Edit')").click
    wait_for_ajaximations
    type_in_tiny("textarea", edit_text)
    fj("button:contains('Save')").click
    wait_for_ajax_requests
    expect(fj("div:contains('Last edited')")).to be_present
    expect(f("body")).not_to contain_jqcss("span[data-testid='editedByText']")
  end

  it "preserves quoted reply when editing a reply" do
    user_session(@teacher)

    entry = @topic.discussion_entries.create!(
      user: @teacher,
      message: "new reply from teacher"
    )
    response = @topic.discussion_entries.create!(
      user: @teacher,
      message: "quoted reply from teacher",
      parent_entry: entry,
      quoted_entry: entry
    )
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations
    wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 2 }
    ff("button[data-testid='thread-actions-menu']")[1].click
    f("span[data-testid='edit']").click
    wait_for_ajaximations

    edit_text = "edit message"
    type_in_tiny("textarea", edit_text)
    fj("button:contains('Save')").click
    wait_for_ajaximations

    response.reload
    expect(response.message).to match(edit_text)
    expect(response.quoted_entry_id).to eq(entry.id)
  end

  it "preserves quoted reply when editing an anonymous reply" do
    @topic.anonymous_state = "full_anonymity"
    @topic.save!

    user_session(@teacher)

    entry = @topic.discussion_entries.create!(
      user: @student,
      message: "new reply from teacher"
    )
    response = @topic.discussion_entries.create!(
      user: @student,
      message: "quoted reply from teacher",
      parent_entry: entry,
      quoted_entry: entry
    )
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations
    wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 2 }
    ff("button[data-testid='thread-actions-menu']")[1].click
    f("span[data-testid='edit']").click
    wait_for_ajaximations

    edit_text = "edit message"
    type_in_tiny("textarea", edit_text)
    fj("button:contains('Save')").click
    wait_for_ajaximations

    response.reload
    expect(response.message).to match(edit_text)
    expect(response.quoted_entry_id).to eq(entry.id)

    expect(f("div[data-testid='reply-preview']").text).to include("Anonymous")
  end

  it "allows users to remove quote from reply when editing" do
    user_session(@teacher)

    entry = @topic.discussion_entries.create!(
      user: @teacher,
      message: "new reply from teacher"
    )
    response = @topic.discussion_entries.create!(
      user: @teacher,
      message: "quoted reply from teacher",
      parent_entry: entry,
      quoted_entry: entry
    )
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations
    wait_for(method: nil, timeout: 5) { ff("button[data-testid='thread-actions-menu']").length >= 2 }
    ff("button[data-testid='thread-actions-menu']")[1].click
    f("span[data-testid='edit']").click
    wait_for_ajaximations

    # The toggle to include quoted reply, I cannot click the input directly, as a random
    # span intercepts the click event and selenium raises an error....
    f("svg[name='IconCheck']").click

    fj("button:contains('Save')").click

    wait_for_ajaximations

    response.reload
    expect(response.quoted_entry_id).to be_nil
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
      expect(f("body")).not_to contain_jqcss("[class*=menuItem__label]:contains('Edit')")
      expect(f("body")).not_to contain_jqcss("[class*=menuItem__label]:contains('Delete')")
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
    expect(f("body")).not_to contain_jqcss("[class*=menuItem__label]:contains('Edit')")
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
    fj("[class*=menuItem__label]:contains('Delete')").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    entry.reload
    expect(fj("span:contains('Deleted by teacher')")).to be_present
    expect(entry.workflow_state).to eq "deleted"
  end

  it "deletes a reply and checks data for Initial Post Required discussion" do
    skip_if_safari(:alert)
    @topic.require_initial_post = true
    entry = @topic.discussion_entries.create!(
      user: @student,
      message: "new threaded reply from student"
    )
    user_session(@student)

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(fj("span:contains('1 Reply')")).to be_present
    f("button[data-testid='thread-actions-menu']").click
    fj("[class*=menuItem__label]:contains('Delete')").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    entry.reload
    expect do
      fj("span:contains('1 Reply')")
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError) # rubocop:disable Specs/NoNoSuchElementError
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
    expect(flattened_reply.message).to eq "<p><span class=\"mceNonEditable mention\" data-mention=\"#{third_entry.user_id}\">@#{third_entry.author_name}</span>replying to 3rd level reply</p>"
  end

  context "replies reporting" do
    it "lets users report replies" do
      @course.root_account.enable_feature! :discussions_reporting
      @topic.discussion_entries.create!(
        user: @student,
        message: "this is offensive content"
      )
      user_session(@teacher)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("button[data-testid='thread-actions-menu']").click
      fj("[class*=menuItem__label]:contains('Report')").click
      expect(fj("h2:contains('Report Reply')")).to be_present

      # side test, click away from modal and make sure it closes
      move_to_click("input[data-testid='search-filter']")
      expect(f("body")).not_to contain_jqcss("h2:contains('Report Reply')")

      # resume main test
      move_to_click("button[data-testid='thread-actions-menu']")
      fj("[class*=menuItem__label]:contains('Report')").click
      move_to_click("input[value='offensive']")
      f("button[data-testid='report-reply-submit-button']").click
      wait_for_ajaximations
      move_to_click("button[data-testid='thread-actions-menu']")
      expect(fj("[class*=menuItem__label]:contains('Reported')")).to be_present
    end
  end

  context "fully anonymous discussions" do
    it "shows deleted entries as anonymous" do
      anon_topic = @course.discussion_topics.create!(
        user: @teacher,
        title: "Fully Anonymous Topic",
        message: "Teachers, TAs and Designers are anonymized",
        workflow_state: "published",
        anonymous_state: "full_anonymity"
      )

      student_entry_student_deleted = anon_topic.discussion_entries.create!(
        user: @student,
        message: "this a student entry student deleted"
      )

      student_entry_student_deleted.editor_id = @student.id
      student_entry_student_deleted.destroy

      student_entry_teacher_deleted = anon_topic.discussion_entries.create!(
        user: @student,
        message: "this a student entry teacher deleted"
      )

      student_entry_teacher_deleted.editor_id = @teacher.id
      student_entry_teacher_deleted.destroy

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{anon_topic.id}"
      expect(fj("div:contains('Deleted by Anonymous')")).to be_present
      expect(fj("div:contains('Deleted by teacher')")).to be_present
    end

    it "shows edited entries as anonymous" do
      anon_topic = @course.discussion_topics.create!(
        user: @teacher,
        title: "Fully Anonymous Topic",
        message: "Teachers, TAs and Designers are anonymized",
        workflow_state: "published",
        anonymous_state: "full_anonymity"
      )

      student_entry_student_edited = anon_topic.discussion_entries.create!(
        user: @student,
        message: "this a student entry student edited"
      )

      student_entry_student_edited.editor_id = @student.id
      student_entry_student_edited.save!

      student_entry_teacher_edited = anon_topic.discussion_entries.create!(
        user: @student,
        message: "this a student entry teacher edited"
      )

      student_entry_teacher_edited.editor_id = @teacher.id
      student_entry_teacher_edited.save!

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{anon_topic.id}"

      # for anonymous discussion entries, we never show who edited
      expect(ff("span[data-testid='author_name']")[0].text).to eq "teacher"
      expect(ff("span[data-testid='author_name']")[1].text).to include "Anonymous"
      expect(ff("span[data-testid='author_name']")[2].text).to include "Anonymous"
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

    it "allows liking" do
      @teacher.preferences[:discussions_splitscreen_view] = false
      @teacher.save!

      anon_topic = @course.discussion_topics.create!(
        user: @teacher,
        title: "Fully Anonymous Topic",
        message: "Teachers, TAs and Designers are anonymized",
        workflow_state: "published",
        anonymous_state: "full_anonymity",
        allow_rating: true
      )

      @first_reply = anon_topic.discussion_entries.create!(
        user: @teacher,
        message: "1st level reply"
      )

      @second_reply = DiscussionEntry.create!(
        message: "2nd level reply",
        discussion_topic_id: @first_reply.discussion_topic_id,
        user_id: @student.id,
        root_entry_id: @first_reply.id,
        parent_id: @first_reply.id
      )

      expect(@second_reply.rating_sum).to be_nil
      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{anon_topic.id}"
      wait_for_ajaximations

      f(".discussion-expand-btn").click
      wait_for_ajaximations
      expect(fj("div:contains('2nd level reply')")).to be_truthy

      ff("[data-testid='like-button']")[1].click
      wait_for_ajaximations
      expect(@second_reply.reload.rating_sum).to eq(1)

      ff("[data-testid='like-button']")[1].click
      wait_for_ajaximations
      expect(fj("div:contains('2nd level reply')")).to be_truthy
      expect(@second_reply.reload.rating_sum).to eq(0)
    end
  end

  context "partially anonymous discussions" do
    def ui_entry_author_name
      f("div[data-testid='discussion-root-entry-container'] span[data-testid='author_name']").text
    end

    before :once do
      @partially_anon_topic = @course.discussion_topics.create!(
        user: @teacher,
        title: "Partially Anonymous Topic",
        message: "feel free to be anonymous, or not",
        workflow_state: "published",
        anonymous_state: "partial_anonymity"
      )
    end

    it "lets students post replies as themselves" do
      message = "Real Name was used"
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@partially_anon_topic.id}"

      f("button[data-testid='discussion-topic-reply']").click

      force_click_native("span[data-testid='anonymous-response-selector'] input")
      fj("li:contains('#{@student.name}')").click
      type_in_tiny "textarea", message
      f("button[data-testid='DiscussionEdit-submit'").click

      # optimistic response
      expect(ui_entry_author_name).to eq @student.name

      # graphql response
      wait_for_ajaximations
      expect(ui_entry_author_name).to eq @student.name
    end

    it "lets students post replies anonymously" do
      message = "Anonymous Name was used"
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@partially_anon_topic.id}"

      f("button[data-testid='discussion-topic-reply']").click

      force_click_native("span[data-testid='anonymous-response-selector'] input")
      type_in_tiny "textarea", message
      f("button[data-testid='DiscussionEdit-submit'").click

      # optimistic response
      expect(ui_entry_author_name).to start_with "Anonymous"
      # graphql response
      wait_for_ajaximations
      expect(ui_entry_author_name).to start_with "Anonymous"
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
      f("button[data-testid='DiscussionEdit-submit']").click
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

  it "shows the correct entry counts for graded group discussions" do
    topic = create_graded_discussion(@course)

    group = @course.groups.create!(name: "Group 1")
    group.add_user(@student)

    topic.group_category = @course.group_categories.create!(name: "Group Category")
    topic.save!

    subtopic = topic.child_topics.build(title: "Subtopic 1", context: group)
    subtopic_assignment = @course.assignments.build(submission_types: "discussion_topic", title: subtopic.title)
    subtopic_assignment.infer_times
    subtopic_assignment.saved_by = :discussion_topic
    subtopic.assignment = subtopic_assignment
    subtopic.group_category = topic.group_category
    subtopic.save

    root_entry = topic.discussion_entries.create!(user: @teacher, message: "root entry")
    topic.discussion_entries.create!(user: @teacher, message: "sub entry", root_entry_id: root_entry.id, parent_id: root_entry.id)

    user_session(@teacher)

    get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

    expect(ff("div[data-testid='replies-counter']")[1]).to include_text("1 Reply")
  end

  it "should show alert when discussion has sub assignments but the checkpoints feature flag is disabled" do
    Account.site_admin.enable_feature! :discussion_checkpoints

    discussion_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
    due_at = 2.days.from_now
    replies_required = 2

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic:,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [{ type: "everyone", due_at: }],
      points_possible: 5
    )

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic:,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: [{ type: "everyone", due_at: }],
      points_possible: 10,
      replies_required:
    )

    Account.site_admin.disable_feature! :discussion_checkpoints

    user_session(@teacher)

    get "/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}"
    expect(fj("div:contains('This discussion includes graded checkpoints, but the Discussion Checkpoints feature flag is currently disabled. To enable this functionality, please contact an administrator to activate the feature flag.')")).to be_present
  end

  it "should not show alert when discussion has sub assignments but the checkpoints feature flag is disabled to students" do
    Account.site_admin.enable_feature! :discussion_checkpoints

    discussion_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
    due_at = 2.days.from_now
    replies_required = 2

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic:,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [{ type: "everyone", due_at: }],
      points_possible: 5
    )

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic:,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: [{ type: "everyone", due_at: }],
      points_possible: 10,
      replies_required:
    )

    Account.site_admin.disable_feature! :discussion_checkpoints

    user_session(@student)

    get "/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}"
    expect(f("body")).not_to contain_jqcss("div:contains('This discussion includes graded checkpoints, but the Discussion Checkpoints feature flag is currently disabled. To enable this functionality, please contact an administrator to activate the feature flag.')")
  end

  context "NO header stickiness" do
    before do
      @topic = create_discussion("Discussion With Sticky Hheader", "threaded")
      5.times do |i|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "root entry #{i + 1}"
        )
      end
      user_session(@teacher)
    end

    it "should not have sticky header when checkpoints is enabled since we are not in speedgrader" do
      @course.account.enable_feature! :discussion_checkpoints
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("body")).not_to contain_css("div[data-testid='sticky-toolbar']")
    end
  end
end
