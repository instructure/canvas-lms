# frozen_string_literal: true

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

require_relative "../helpers/conversations_common"

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    add_students(3)
    @teacher.update_attribute(:name, "Teacher")
  end

  # the js errors caught in here are captured by VICE-2507
  context "react_inbox", :ignore_js_errors do
    it "shows no conversations selected ui" do
      get "/conversations"
      expect(fj("span:contains('No Conversations to Show')")).to be_present
      expect(fj("span:contains('No Conversations Selected')")).to be_present
    end

    context "with an existing conversation" do
      before do
        @participant = conversation(@teacher, @s[0], @s[1], body: "hi there", workflow_state: "unread")
        @convo = @participant.conversation
        @convo.update_attribute(:subject, "test")
        @convo.add_message(@teacher, "second Message")
      end

      it "returns to conversations list on button click" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        fj("button:contains('Return to test in Conversation List')").click
        wait_for_ajaximations
        expect(fj("button:contains('Open Conversation')")).to be_present
      end

      it "forwards conversations via the top bar menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("span[data-testid='desktop-message-action-header'] button[data-testid='settings']").click
        fj("li:contains('Forward')").click
        f("input[aria-label='To']").click
        fj("div[data-testid='address-book-item']:contains('Users')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[2].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 3
        expect(messages[0].text).to include @teacher.name
        expect(messages[0].text).to include @s[2].name
        expect(messages[0].text).not_to include @s[0].name.to_s
        expect(messages[0].text).not_to include @s[1].name.to_s
      end

      it "forwards conversations via the conversation header menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("button[data-testid='more-options']").click
        fj("li:contains('Forward')").click

        # Verify that the thread is being forwarded
        expect(fj("span:contains('second Message')")).to be_present
        expect(fj("span:contains('hi there')")).to be_present

        f("input[aria-label='To']").click
        fj("div[data-testid='address-book-item']:contains('Users')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[2].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 3
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[2].name}"
        expect(messages[0].text).not_to include @s[0].name.to_s
        expect(messages[0].text).not_to include @s[1].name.to_s

        # Verify that the shown forwarded messages were sent correctly
        user_session(@s[2])
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 3
        expect(fj("span:contains('forwarding to you')")).to be_present
        expect(fj("span:contains('second Message')")).to be_present
        expect(fj("span:contains('hi there')")).to be_present
      end

      it "forwards conversations via the individual message menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("button[data-testid='message-more-options']").click
        fj("li:contains('Forward')").click

        # Verify that only the selected message is shown as being forwarded
        expect(fj("span:contains('second Message')")).to be_present
        expect(f("span[data-testid='compose-modal-desktop']")).not_to contain_jqcss("span:contains('hi there')")

        f("input[aria-label='To']").click
        fj("div[data-testid='address-book-item']:contains('Users')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[2].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 3
        expect(messages[0].text).to include @teacher.name
        expect(messages[0].text).to include @s[2].name
        expect(messages[0].text).not_to include @s[0].name.to_s
        expect(messages[0].text).not_to include @s[1].name.to_s

        # Verify that the shown forwarded messages were sent correctly
        user_session(@s[2])
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(fj("span:contains('forwarding to you')")).to be_present
        expect(fj("span:contains('second Message')")).to be_present
        expect(f("body")).not_to contain_jqcss("span:contains('hi there')")
      end

      it "archives and unarchives a conversation via conversation header menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        f("button[data-testid='more-options']").click
        fj("li:contains('Archive')").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(f("body")).not_to contain_jqcss "div[data-testid='conversation']"

        f("input[title='Inbox']").click
        fj("li:contains('Archived')").click
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        f("button[data-testid='more-options']").click
        fj("li:contains('Unarchive')").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(f("body")).not_to contain_jqcss "div[data-testid='conversation']"
      end

      it "archives convo then checks availability after a new message" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        f("button[data-testid='more-options']").click
        fj("li:contains('Archive')").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(f("body")).not_to contain_jqcss "div[data-testid='conversation']"

        @convo.add_message(@s[0], "second Message")
        @convo.save!
        get "/conversations"
        wait_for_ajaximations
        expect(f("body")).to contain_jqcss "div[data-testid='conversation']"
      end

      it "does not have archive options button when in sent scope" do
        get "/conversations#filter=type=sent"
        f("div[data-testid='conversation']").click
        expect(f("button[data-testid='archive']")).to be_disabled
        f("button[data-testid='more-options']").click
        expect(f("body")).not_to contain_jqcss("li:contains('Archive')")
      end

      it "stars and unstars a conversation via conversation header menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        expect(f("button[data-testid='visible-not-starred']")).to be_present

        f("button[data-testid='more-options']").click
        fj("li:contains('Star')").click
        wait_for_ajaximations
        expect(f("button[data-testid='visible-starred']")).to be_present

        f("button[data-testid='more-options']").click
        fj("li:contains('Unstar')").click
        wait_for_ajaximations
        expect(f("button[data-testid='visible-not-starred']")).to be_present
      end

      it "archives / unarchives a convo properly in the starred scope" do
        @participant.starred = true
        @participant.save!

        get "/conversations"
        f("input[title='Inbox']").click
        fj("li:contains('Starred')").click
        f("div[data-testid='conversation']").click
        f("button[data-testid='more-options']").click
        fj("li:contains('Archive')").click
        driver.switch_to.alert.accept
        expect(fj("span:contains('Message archived!')")).to be_present
        f("button[data-testid='more-options']").click
        fj("li:contains('Unarchive')").click
        driver.switch_to.alert.accept
        expect(fj("span:contains('Message unarchived!')")).to be_present
      end

      it "hides selected message while loading" do
        other_student = User.create!(name: "Luke Skywalker")
        @course.enroll_student(other_student).update_attribute(:workflow_state, "active")

        conversation = other_student.initiate_conversation(
          [@teacher],
          nil,
          subject: "Hello!",
          context_type: "Course",
          context_id: @course.id
        )
        conversation.add_message("Test")

        get "/conversations"
        ff("div[data-testid='conversation']")[0].click
        f("input[data-testid='mailbox-select']").click
        f("span[value='sent']").click

        expect(fj("span:contains('No Conversations Selected')")).to be_present
      end
    end

    context "conversation with a message from a hard-deleted user" do
      before do
        user_to_delete = User.create!(name: "Student To Be Deleted")
        user_to_delete_enrollment = @course.enroll_student(user_to_delete)
        user_to_delete_enrollment.update_attribute(:workflow_state, "active")
        @participant = conversation(@teacher, @s[0], user_to_delete, body: "hi there", workflow_state: "unread")
        @convo = @participant.conversation
        @convo.update_attribute(:subject, "testing conversation with deleted users")
        @convo.add_message(user_to_delete, "message from deleted user")
        user_to_delete.destroy
        user_to_delete_enrollment.reload.destroy_permanently!
        user_to_delete.destroy_permanently!
      end

      it "displays message list correctly" do
        get "/conversations"
        conversation_list_item = f("div[data-testid='conversation']")
        conversation_list_item.click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")

        expect(conversation_list_item.text).to include "DELETED USER,"
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "DELETED USER, #{@s[0].name}"
      end
    end

    context "conversation participant with a null conversation" do
      before do
        @participant = conversation(@teacher, @s[0], @s[1], body: "hi there", workflow_state: "unread")
        @convo = @participant.conversation
        @convo.update_attribute(:subject, "test")
        @conversation_participants = @convo.conversation_participants
        @convo.conversation_messages[0].conversation_message_participants.delete_all
        @convo.conversation_messages[0].delete
        @convo.delete
      end

      it "does not crash when opening inbox" do
        get "/conversations"

        # The page should load with no conversations
        expect(fj("span:contains('No Conversations Selected')")).to be_present

        # Verify that the orphaned state exists
        expect(@conversation_participants[0].reload).to be_truthy
        expect(@conversation_participants[0].conversation_id).to be_truthy
        expect { Conversation.find(@conversation_participants[0].conversation_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "course selection" do
      it "resets the course selection when the reset button is clicked" do
        get "/conversations"
        f("[data-testid='course-select']").click
        wait_for_ajaximations

        f("##{@course.asset_string}").click
        wait_for_ajaximations
        expect(f("[data-testid='course-select']").attribute("value")).to eq @course.name
        force_click("[data-testid='delete-course-button'] > button")
        wait_for_ajaximations
        expect(f("[data-testid='course-select']").attribute("value")).to eq ""
      end
    end

    context "when react_inbox_labels feature flag is ON" do
      before do
        Account.site_admin.set_feature_flag! :react_inbox_labels, "on"
      end

      it "shows the Manage labels button" do
        get "/conversations"
        expect(f('button[data-testid="manage-labels"]')).to be_displayed
      end

      context "in the Manage labels modal" do
        before do
          @teacher.preferences[:inbox_labels] = ["Test 1", "Test 2", "Test 3"]
          @teacher.save!

          user_session(@teacher)
          get "/conversations"

          f('button[data-testid="manage-labels"]').click
          wait_for_ajaximations
        end

        it "shows the user's labels" do
          labels = ff("tr[data-testid='label']")

          expect(labels.count).to eq 3
          expect(labels[0].text).to eq "Test 1\nRemove Label"
          expect(labels[1].text).to eq "Test 2\nRemove Label"
          expect(labels[2].text).to eq "Test 3\nRemove Label"
        end

        it "removes the Test 1 label from user's labels" do
          delete_label_buttons = ff("button[data-testid='delete-label']")
          expect(delete_label_buttons.count).to eq 3

          delete_label_buttons[0].click
          fj("button:contains('Save')").click
          wait_for_ajaximations

          keep_trying_until { expect(User.find(@teacher.id).inbox_labels).to eq ["Test 2", "Test 3"] }
        end

        it "adds the Test 4 label to user's labels" do
          f("input[placeholder='Label Name']").send_keys "Test 4"
          f("button[data-testid='add-label']").click
          fj("button:contains('Save')").click
          wait_for_ajaximations

          expect(User.find(@teacher.id).inbox_labels).to eq ["Test 1", "Test 2", "Test 3", "Test 4"]
        end
      end
    end

    context "when react_inbox_labels feature flag is OFF" do
      before do
        Account.site_admin.set_feature_flag! :react_inbox_labels, "off"
      end

      it "does not shows the Manage labels button" do
        get "/conversations"
        expect(f("body")).not_to contain_jqcss('button[data-testid="manage-labels"]')
      end
    end
  end
end
