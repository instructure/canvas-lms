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
  context "when react_inbox feature flag is ON", ignore_js_errors: true do
    before do
      Account.default.set_feature_flag! :react_inbox, "on"
    end

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
      end

      it "forwards conversations via the top bar menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 1
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("span[data-testid='desktop-message-action-header'] button[data-testid='settings']").click
        fj("li:contains('Forward')").click
        ff("input[aria-label='Address Book']")[1].click
        fj("div[data-testid='address-book-item']:contains('Students')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[2].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[2].name}"
        expect(messages[0].text).not_to include @s[0].name.to_s
        expect(messages[0].text).not_to include @s[1].name.to_s
      end

      it "forwards conversations via the conversation header menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 1
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("button[data-testid='more-options']").click
        fj("li:contains('Forward')").click
        ff("input[aria-label='Address Book']")[1].click
        fj("div[data-testid='address-book-item']:contains('Students')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[0].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}"
        expect(messages[0].text).not_to include @s[1].name.to_s
        expect(messages[0].text).not_to include @s[2].name.to_s
      end

      it "forwards conversations via the individual message menu" do
        get "/conversations"
        f("div[data-testid='conversation']").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 1
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[0].name}, #{@s[1].name}"
        f("button[data-testid='message-more-options']").click
        fj("li:contains('Forward')").click
        ff("input[aria-label='Address Book']")[1].click
        fj("div[data-testid='address-book-item']:contains('Students')").click
        fj("div[data-testid='address-book-item']:contains('#{@s[1].name}')").click
        f("textarea[data-testid='message-body']").send_keys "forwarding to you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        messages = ff("span[data-testid='message-detail-item-desktop']")
        expect(messages.count).to eq 2
        expect(messages[0].text).to include "#{@teacher.name}, #{@s[1].name}"
        expect(messages[0].text).not_to include @s[0].name.to_s
        expect(messages[0].text).not_to include @s[2].name.to_s
      end
    end
  end

  context "when react_inbox feature flag is off" do
    before do
      Account.default.set_feature_flag! :react_inbox, "off"
    end

    it "has correct elements on the page when composing a new message", priority: "2" do
      skip_if_chrome("fragile in chrome")
      # For testing media comments button, we need to double Kaltura
      stub_kaltura
      conversations
      f("#compose-btn").click
      wait_for_ajaximations

      # Modal displays
      expect(f("#compose-new-message")).to be_displayed
      # Close button displays in titlebar
      expect(f(".ui-dialog-titlebar-close")).to be_displayed
      # Course Dropdown displays and defaults to Select course
      expect(f('.btn.dropdown-toggle[data-id="compose-message-course"]')).to include_text("Select course")

      # Selects course for rest of elements to display
      select_message_course(@course.name.to_s)
      wait_for_ajaximations

      # To field displays
      expect(f("#compose-message-recipients")).to be_displayed
      # Address Book/Recipient button displays
      expect(f(".ac-search-btn#recipient-search-btn")).to be_displayed
      # Subject field displays
      expect(f("#compose-message-subject")).to be_displayed
      # Send Individual messages checkbox displays and is unchecked
      expect(f("#bulk_message").selected?).to be_falsey
      # Message field displays
      expect(f(".conversation_body")).to be_displayed
      # Attachment button displays
      expect(f("#add-message-attachment-button")).to be_displayed
      # Media Comment button displays
      expect(f(".ui-button.attach-media")).to be_displayed
      # Cancel button displays
      expect(fj('.ui-button.ui-widget:visible:contains("Cancel")')).to be_displayed
      # Send button displays
      expect(fj(".btn-primary.send-message:visible")).to be_displayed
    end

    it "does not show an XSS alert when XSS script is typed into a new conversation's message subject and body", priority: "1" do
      skip_if_chrome("fragile in chrome")
      conversations
      script = "<IMG SRC=j&#X41vascript:alert('test2')> or <script>alert('xss');</script>"
      compose course: @course, to: [@s[0], @s[1]], subject: script, body: script
      wait_for_ajaximations
      dismiss_flash_messages
      expect(alert_present?).to be_falsey
      select_view("sent")
      expect(alert_present?).to be_falsey
      click_message(0)
      expect(alert_present?).to be_falsey
    end

    context "conversations ui" do
      before do
        conversations
      end

      it "has a courses dropdown", priority: "1" do
        f("[data-id = 'course-filter']").click
        wait_for_ajaximations

        # Verify course filter is open
        expect(f(".course-filter.open")).to be_truthy

        # Verify course filter names
        dropdown_array = ff("#course-filter-bs .text")
        expect(dropdown_array[0]).to include_text("All Courses")
        expect(dropdown_array[1]).to include_text("Favorite Courses")
        dropdown_array[1].click
        expect(f('.dropdown-menu .inner [role="group"] .text')).to include_text(@course.name)
      end

      it "has a type dropdown", priority: "1" do
        element = view_filter
        element.click
        wait_for_ajaximations

        # Verify type filter is open
        expect(element.enabled?).to be true

        # Verify type filter names and order
        options = element.find_elements(tag_name: "option")
        expect(options[0].text).to eq "Inbox"
        expect(options[1].text).to eq "Unread"
        expect(options[2].text).to eq "Starred"
        expect(options[3].text).to eq "Sent"
        expect(options[4].text).to eq "Archived"
        expect(options[5].text).to eq "Submission Comments"
      end

      it "has action buttons", priority: "1" do
        expect(f("#conversation-actions #compose-btn")).to be
        expect(f("#conversation-actions #reply-btn")).to be
        expect(f("#conversation-actions #reply-all-btn")).to be
        expect(f("#conversation-actions #archive-btn")).to be
        expect(f("#conversation-actions #delete-btn")).to be
        expect(f(".inline-block")).to be
      end

      it "has a search box with address book", priority: "1" do
        # Click on the address book
        f(".recipient-finder .icon-address-book").click
        wait_for_ajaximations
        indicator = f(".paginatedLoadingIndicator")
        keep_trying_until { expect(indicator["style"]).to include("none") }

        # Verify the names of the course and all students and teachers appear
        expect(f(".ac-result-contents .context .result-name")).to include_text(@course.name)
        users = @course.users.collect(&:name)
        users.each do |u|
          expect(fj(".ac-result-contents .result-name:contains('#{u}')")).to be
        end
      end

      it "displays a no messages image", priority: "1" do
        # Verify Text and Icon Class
        expect(f(".no-messages")).to include_text("No Conversations Selected")
        expect(f(".no-messages .icon-email")).to be
      end
    end

    describe "message list" do
      before do
        @participant = conversation(@teacher, @s[0], @s[1], body: "hi there", workflow_state: "unread")
        @convo = @participant.conversation
        @convo.update_attribute(:subject, "test")
      end

      it "displays relevant information for messages", priority: "1" do
        # Normalizes time zone to be safe, in case user object and browser are not matching. Must do this
        # before page renders
        @teacher.time_zone = "America/Juneau"
        @teacher.save!
        conversations
        expect(conversation_elements.size).to eq 1
        expect(f("li .author")).to include_text("#{@teacher.name}, #{@s[0].name}")
        expect(f("ul .read-state")).to be_present
        expect(f("li .subject")).to include_text("test")
        expect(f("li .summary")).to include_text("hi there")

        # We're interested in the element's attribute datetime for matching the timestamp
        rendered_time = f("time").attribute("datetime")

        # Gotta parse the times so they match, which includes removing the milliseconds by
        # converting both to integer
        # We do all this to test the time rendered on screen against the time the object was created
        expect(Time.zone.parse(rendered_time).to_i).to match(@participant.last_message_at.to_i)
      end

      it "forwards messages", priority: "1" do
        conversations
        message_count = @convo.conversation_messages.length
        click_message(0)

        # Tests forwarding messages via the top level More Options gear menu
        click_more_options(admin: true)
        forward_message(@s[2])
        expect(ff(".message-item-view").length).to eq message_count += 1

        # Tests forwarding messages via the conversation level More Options gear menu
        click_more_options(convo: true)
        forward_message(@s[0])
        expect(ff(".message-item-view").length).to eq message_count += 1

        # Tests forwarding messages via the message level More Options gear menu
        click_more_options({ message: true }, 0)
        forward_message(@s[1])
        expect(ff(".message-item-view").length).to eq message_count + 1
      end

      it "displays message count", priority: "1" do
        conversations
        expect(f(".message-count")).to include_text("1")

        select_view("sent")
        select_message(0)
        reply_to_message
        expect(f(".message-count")).to include_text("2")
        dismiss_flash_messages
        reply_to_message
        expect(f(".message-count")).to include_text("3")
      end

      it "shows starred messages in the starred filter", priority: "1" do
        conversations
        unstarred_elt = conversation_elements.first

        hover_over_message(unstarred_elt)
        click_star_icon(unstarred_elt)
        expect(f(".active", unstarred_elt)).to be_present
        expect(@participant.reload.starred).to be_truthy
        select_view("starred")
        expect(conversation_elements.size).to eq 1
      end

      it "shows a flash message when deleting a message via Trash Button", priority: "1" do
        skip_if_safari(:alert)
        conversations

        click_message(0)
        f("#delete-btn").click

        driver.switch_to.alert.accept
        expect_flash_message :success, "Message Deleted!"
      end

      it "shows a flash message when deleting a message via cog dropdown", priority: "1" do
        skip_if_safari(:alert)
        conversations

        click_message(0)
        # Clicks the title-level more options gear menu
        click_more_options(convo: true)
        f(".delete-btn.ui-corner-all").click
        driver.switch_to.alert.accept
        expect_flash_message :success, "Message Deleted!"
      end

      it "archives a message via the admin archive button", priority: "1" do
        skip_if_safari(:alert)
        conversations

        click_message(0)
        click_archive_button
        # Archiving messages requires jobs to run to complete
        run_progress_job
        select_view("archived")
        expect(conversation_elements.size).to eq 1
      end

      it "archives a message via the cog dropdown", priority: "1" do
        skip_if_safari(:alert)
        conversations

        click_message(0)
        # Clicks the title-level more options gear menu
        click_more_options(convo: true)
        click_archive_menu_item
        # Archiving messages requires jobs to run to complete
        run_progress_job
        select_view("archived")
        expect(conversation_elements.size).to eq 1
      end

      it "is not able to archive a sent message via the admin archive button" do
        conversations

        select_view("sent")
        click_message(0)
        expect(f("#archive-btn")).to be_disabled
      end

      it "is not able to archive a sent message via the cog dropdown" do
        conversations

        select_view("sent")
        click_message(0)
        # Clicks the title-level more options gear menu
        click_more_options(convo: true)
        expect(f("#content")).not_to contain_css(".archive-btn.ui-corner-all")
      end

      context "in archive view" do
        before do
          @participant.update_attribute(:workflow_state, "archived")
          conversation(@teacher, @s[0], @s[1], workflow_state: "archived")
          conversations
          select_view("archived")
          click_message(0)
        end

        it "unarchives a message via the admin unarchive button", priority: "1" do
          skip_if_safari(:alert)
          click_archive_button
          # Unarchiving messages requires jobs to run to complete
          run_progress_job
          select_view("inbox")
          expect(conversation_elements.size).to eq 1
        end

        it "unarchives a message via the cog dropdown", priority: "1" do
          skip_if_safari(:alert)
          # Clicks the title-level more options gear menu
          click_more_options(convo: true)
          click_archive_menu_item
          # Unarchiving messages requires jobs to run to complete
          run_progress_job
          select_view("inbox")
          expect(conversation_elements.size).to eq 1
        end

        it "unarchives multiple messages via the admin unarchive button", priority: "1" do
          # Selects both messages using the shift key. First was selected in before loop
          driver.action.key_down(:shift).perform
          click_message(1)
          driver.action.key_up(:shift).perform

          click_archive_button
          # Unarchiving messages requires jobs to run to complete
          run_progress_job

          select_view("inbox")
          expect(conversation_elements.size).to eq 2
        end
      end
    end

    describe "view filter" do
      before do
        conversation(@teacher, @s[0], @s[1], workflow_state: "unread")
        conversation(@teacher, @s[0], @s[1], workflow_state: "read", starred: true)
        conversation(@teacher, @s[0], @s[1], workflow_state: "archived", starred: true)
      end

      it "defaults to inbox view", priority: "1" do
        conversations
        expect(selected_view_filter).to eq "inbox"
        expect(conversation_elements.size).to eq 2
      end

      it "has an unread view", priority: "1" do
        conversations
        select_view("unread")
        expect(selected_view_filter).to eq "unread"
        expect(conversation_elements.size).to eq 1
      end

      it "has an starred view", priority: "1" do
        conversations
        select_view("starred")
        expect(selected_view_filter).to eq "starred"
        expect(conversation_elements.size).to eq 2
      end

      it "has an sent view", priority: "1" do
        conversations
        select_view("sent")
        expect(selected_view_filter).to eq "sent"
        expect(conversation_elements.size).to eq 3
      end

      it "has an archived view", priority: "1" do
        conversations
        select_view("archived")
        expect(selected_view_filter).to eq "archived"
        expect(conversation_elements.size).to eq 1
      end

      it "defaults to all courses context", priority: "1" do
        conversations
        expect(bootstrap_select_value(course_filter)).to eq ""
        expect(conversation_elements.size).to eq 2
      end

      it "truncates long course names", priority: "2" do
        @course.name = "this is a very long course name that will be truncated"
        @course.save!
        conversations
        select_course(@course.id)
        button_text = f(".filter-option", course_filter).text
        expect(button_text).not_to eq @course.name
        expect(button_text[0...5]).to eq @course.name[0...5]
        expect(button_text[-5..]).to eq @course.name[-5..]
      end

      it "filters by course", priority: "1" do
        conversations
        select_course(@course.id)
        expect(conversation_elements.size).to eq 2
      end

      it "filters by course plus view", priority: "1" do
        conversations
        select_course(@course.id)
        select_view("unread")
        expect(conversation_elements.size).to eq 1
      end

      it "hides the spinner after deleting the last conversation", priority: "1" do
        skip_if_safari(:alert)
        conversations
        select_view("archived")
        expect(conversation_elements.size).to eq 1
        conversation_elements[0].click
        wait_for_ajaximations
        f("#delete-btn").click
        driver.switch_to.alert.accept
        expect(f(".messages")).not_to contain_css("li")
        expect(f(".message-list")).not_to contain_jqcss(".paginatedLoadingIndicator:visible")
        expect(ff(".actions .btn-group button:disabled").size).to eq 4
      end
    end

    describe "starred" do
      before do
        @conv_unstarred = conversation(@teacher, @s[0], @s[1])
        @conv_starred = conversation(@teacher, @s[0], @s[1])
        @conv_starred.starred = true
        @conv_starred.save!
      end

      it "stars via star icon", priority: "1" do
        conversations
        unstarred_elt = conversation_elements[1]
        # make star button visible via mouse over
        hover_over_message(unstarred_elt)

        star_btn = f(".star-btn", unstarred_elt)
        expect(star_btn).to be_present
        expect(unstarred_elt).not_to contain_css(".active")

        click_star_icon(unstarred_elt, star_btn)
        expect(f(".active", unstarred_elt)).to be_present
        expect(@conv_unstarred.reload.starred).to be_truthy
      end

      it "unstars via star icon", priority: "1" do
        conversations
        starred_elt = conversation_elements[0]
        star_btn = f(".star-btn", starred_elt)
        expect(star_btn).to be_present
        expect(f(".active", starred_elt)).to be_present

        star_btn.click
        wait_for_ajaximations
        expect(starred_elt).not_to contain_css(".active")
        expect(@conv_starred.reload.starred).to be_falsey
      end

      it "stars via gear menu", priority: "1" do
        conversations
        unstarred_elt = conversation_elements[1]
        unstarred_elt.click
        wait_for_ajaximations
        click_star_toggle_menu_item
        expect(f(".active", unstarred_elt)).to be_present
        expect(f(".star-btn", unstarred_elt)["aria-checked"]).to eq "true"
        run_progress_job
        expect(@conv_unstarred.reload.starred).to be_truthy
      end

      it "unstars via gear menu", priority: "1" do
        conversations
        starred_elt = conversation_elements[0]
        starred_elt.click
        wait_for_ajaximations
        click_star_toggle_menu_item
        expect(starred_elt).not_to contain_css(".active")
        run_progress_job
        expect(@conv_starred.reload.starred).to be_falsey
      end
    end
  end
end
