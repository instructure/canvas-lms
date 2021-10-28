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

require_relative '../helpers/conversations_common'

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "replying" do
    before do
      cp = conversation(@s1, @teacher, @s2, workflow_state: 'unread')
      @convo = cp.conversation
      @convo.update_attribute(:subject, 'homework')
      @convo.update_attribute(:context, @group)
      @convo.add_message(@s1, "What's this week's homework?")
      @convo.add_message(@s2, "I need the homework too.")
    end

    context "when react_inbox feature flag is on" do
      before do
        Account.default.set_feature_flag! :react_inbox, 'on'
      end

      it "show record / upload media ui when kaltura is enabled" do
        stub_kaltura
        get '/conversations'
        f("div[data-testid='conversation']").click
        f("button[data-testid='reply']").click
        # need to wait for background stuff to load not easily caught by wait_for_ajaximations
        # rubocop:disable Lint/NoSleep
        sleep 1
        # rubocop:enable Lint/NoSleep
        f("button[data-testid='media-upload']").click
        # make sure upload input exists
        expect(f("input[type='file']")).to be_truthy
      end
    end

    context "when react_inbox feature flag is off" do
      before do
        Account.default.set_feature_flag! :react_inbox, 'off'
      end

      it "maintains context and subject", priority: "1", test_id: 138696 do
        go_to_inbox_and_select_message
        f('#reply-btn').click
        expect(f('#compose-message-course')).to be_disabled
        expect(f('.message_course_ro').text).to eq @group.name
        expect(f('input[name=context_code]')).to have_value @group.asset_string
        expect(f('#compose-message-subject')).to be_disabled
        expect(f('#compose-message-subject')).not_to be_displayed
        expect(f('#compose-message-subject')).to have_value(@convo.subject)
        expect(f('.message_subject_ro')).to be_displayed
        expect(f('.message_subject_ro').text).to eq @convo.subject
      end

      it "adds new messages to the conversation", priority: "1", test_id: 197537 do
        initial_message_count = @convo.conversation_messages.length
        go_to_inbox_and_select_message
        f('#reply-btn').click
        write_message_body('Read chapters five and six.')
        click_send
        wait_for_ajaximations
        expect(ff('.message-item-view').length).to eq initial_message_count + 1
        @convo.reload
        expect(@convo.conversation_messages.length).to eq initial_message_count + 1
      end

      it "does not allow adding recipients to private messages", priority: "2", test_id: 1089655 do
        @convo.update_attribute(:private_hash, '12345')
        go_to_inbox_and_select_message
        f('#reply-btn').click
        expect(f('#recipient-row')).to have_attribute(:style, 'display: none;')
      end

      context "reply and reply all" do
        it "addresses replies to the most recent author by default from the icon at the top of the page", priority: "2", test_id: 197538 do
          go_to_inbox_and_select_message
          f('#reply-btn').click
          assert_number_of_recipients(1)
        end

        it "replies to all users from the reply all icon on the top of the page", priority: "2", test_id: 1070114 do
          go_to_inbox_and_select_message
          f('#reply-all-btn').click
          assert_number_of_recipients(2)
        end

        it "replies to message from the reply icon next to the message", priority: "2", test_id: 1077516 do
          go_to_inbox_and_select_message
          f('.message-detail-actions .reply-btn').click
          assert_number_of_recipients(1)
        end

        it "replies to all users from the settings icon next to the message", priority: "2", test_id: 86606 do
          go_to_inbox_and_select_message
          f('.message-detail-actions .icon-settings').click
          f('.ui-menu-item .reply-all-btn').click
          assert_number_of_recipients(2)
        end

        it "replies to message from mouse hover", priority: "2", test_id: 1069285 do
          go_to_inbox_and_select_message
          driver.action.move_to(f('.message-content .message-item-view')).perform
          f('.message-info .reply-btn').click
          assert_number_of_recipients(1)
        end

        it "replies to all from mouse hover", priority: "2", test_id: 1069836 do
          go_to_inbox_and_select_message
          driver.action.move_to(f('.message-content .message-item-view')).perform
          f('.message-info .icon-settings').click
          f('.ui-menu-item .reply-all-btn').click
          assert_number_of_recipients(2)
        end
      end

      it "does not let a student reply to a student conversation if they lose messaging permissions" do
        @convo.conversation_participants.where(:user_id => @teacher).delete_all
        @convo.update_attribute(:context, @course)
        user_session(@s1)
        go_to_inbox_and_select_message
        expect(f('#reply-btn')).to_not be_disabled

        @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)
        go_to_inbox_and_select_message
        expect(f('#reply-btn')).to be_disabled
      end

      it "lets a student reply to a conversation including a teacher even if they lose messaging permissions" do
        @convo.update_attribute(:context, @course)
        user_session(@s1)
        @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)
        go_to_inbox_and_select_message
        expect(f('#reply-btn')).to_not be_disabled
      end
    end
  end
end
