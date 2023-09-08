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

require_relative "../helpers/conversations_common"

describe "conversations index page" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, "active") }
    cat = @course.group_categories.create(name: "the groups")
    @group = cat.groups.create(name: "the group", context: @course)
    @group.users = [@s1, @s2]
  end

  # the js errors caught in here are captured by VICE-2507
  context "when react_inbox feature flag is on", :ignore_js_errors do
    before do
      Account.default.set_feature_flag! :react_inbox, "on"
    end

    it "searches by recepient name" do
      conversation(@teacher, @s1, body: "adrian")
      conversation(@teacher, @s2, body: "roberto")
      get "/conversations"
      list_items = ff("span[data-testid='conversationListItem-Item']")
      expect(list_items.count).to eq 2
      f("input[placeholder='Search...']").send_keys @s2.name
      wait_for_ajaximations
      fj("li:contains('#{@s2.name}')").click
      list_items = ff("span[data-testid='conversationListItem-Item']")
      expect(list_items.count).to eq 1
      expect(fj("span:contains('roberto')")).to be_present
    end

    context "multi-select" do
      before do
        conversation(@teacher, @s1, @s2, workflow_state: "read")
        conversation(@teacher, @s1, @s2, workflow_state: "read")
        conversation(@teacher, @s1, @s2, workflow_state: "read")
      end

      it "archives conversation by clicking on checkbox" do
        allow(InstStatsd::Statsd).to receive(:count)
        get "/conversations"
        convos = ff("[data-testid='conversation']")
        convos[0].find("input").find_element(:xpath, "..").click
        wait_for_ajaximations
        f("button[data-testid='archive']").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(ff("[data-testid='conversation']").count).to eq 2
        f("input[title='Inbox']").click
        fj("li:contains('Archived')").click
        expect(ff("[data-testid='conversation']").count).to eq 1

        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.archived.react", 1)
        expect(InstStatsd::Statsd).not_to have_received(:count).with("inbox.conversation.archived.legacy", 1)
      end

      it "deletes multiple individually selected conversations via ctrl(or command)+click" do
        get "/conversations"
        convos = ff("[data-testid='conversation']")
        convos[0].click
        driver.action.key_down(modifier).move_to(convos[2]).click.key_up(modifier).perform
        f("button[data-testid='delete']").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(ff("[data-testid='conversation']").count).to eq 1
      end

      it "stars a range of consecutive conversations using shift+click" do
        get "/conversations"
        convos = ff("[data-testid='conversation']")
        convos[0].click
        driver.action.key_down(:shift).move_to(convos[2]).click.key_up(:shift).perform
        f("button[data-testid='settings']").click
        fj("li:contains('Star')").click
        wait_for_ajaximations
        f("input[title='Inbox']").click
        fj("li:contains('Starred')").click
        wait_for_ajaximations
        expect(ff("[data-testid='conversation']").count).to eq 3
      end

      it "marks all selected conversations as unread" do
        get "/conversations"
        convos = ff("[data-testid='conversation']")
        convos[0].click
        driver.action.key_down(:shift).move_to(convos[2]).click.key_up(:shift).perform
        f("button[data-testid='settings']").click
        fj("li:contains('Mark all as unread')").click
        wait_for_ajaximations
        f("input[title='Inbox']").click
        fj("li:contains('Unread')").click
        wait_for_ajaximations
        expect(ff("[data-testid='conversation']").count).to eq 3
      end

      it "unarchives multiple conversations using shift+click" do
        2.times do |i|
          conversation(@teacher, @s1, @s2, workflow_state: "archived", body: "archived #{i}")
        end
        get "/conversations"
        f("input[title='Inbox']").click
        fj("li:contains('Archived')").click
        convos = ff("[data-testid='conversation']")
        convos[0].click
        driver.action.key_down(:shift).move_to(convos[1]).click.key_up(:shift).perform
        f("[data-testid='unarchive']").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(f("body")).not_to contain_jqcss "div[data-testid='conversation']"
      end
    end
  end

  context "when react_inbox feature flag is off" do
    before do
      Account.default.set_feature_flag! :react_inbox, "off"
    end

    describe "search" do
      before do
        @conv1 = conversation(@teacher, @s1, body: "adrian")
        @conv2 = conversation(@teacher, @s2, body: "roberto")
      end

      it "allows finding messages by recipient", priority: "1" do
        conversations
        name = @s2.name
        f("[role=main] header [role=search] input").send_keys(name)
        fj(".ac-result:contains('#{name}')").click
        expect(conversation_elements.length).to eq 1
      end
    end

    describe "multi-select" do
      before do
        @conversations = [conversation(@teacher, @s1, @s2, workflow_state: "read"),
                          conversation(@teacher, @s1, @s2, workflow_state: "read"),
                          conversation(@teacher, @s1, @s2, workflow_state: "read")]
      end

      it "selects multiple conversations", priority: "1" do
        conversations
        select_conversations(2)
        expect(ff(".messages li.active").count).to eq 2
      end

      it "selects all conversations", priority: "1" do
        conversations
        f("#content").click # Ensures focus is in the window and not on the address bar
        driver.action.key_down(modifier)
              .send_keys("a")
              .key_up(modifier)
              .perform
        expect(ff(".messages li.active").count).to eq 3
      end

      it "archives multiple conversations", priority: "1" do
        allow(InstStatsd::Statsd).to receive(:count)
        conversations
        select_conversations
        click_archive_button
        expect(f(".messages")).not_to contain_css("li")
        run_progress_job
        @conversations.each { |c| expect(c.reload).to be_archived }

        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.archived.legacy", 3)
        expect(InstStatsd::Statsd).not_to have_received(:count).with("inbox.conversation.archived.react", 3)
      end

      it "deletes multiple conversations", priority: "1" do
        conversations
        select_conversations
        f("#delete-btn").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(f(".messages")).not_to contain_css("li")
      end
    end
  end
end
