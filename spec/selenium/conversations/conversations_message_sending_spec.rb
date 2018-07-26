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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

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

  describe "message sending" do
    it "should show error messages when no recipient is entered", priority: "1", test_id: 351236 do
      get '/conversations'
      move_to_click('.icon-compose')
      click_send
      errors = ff('.error_text')
      expect(errors[2].text).to include('Invalid recipient name.')
      expect(errors[1].text).to include('Required field')
    end

    it "should start a group conversation when there is only one recipient", priority: "2", test_id: 201499 do
      skip_if_chrome('fragile in chrome')
      conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('single recipient')
      expect(c.private?).to be_falsey
    end

    it "should start a group conversation when there is more than one recipient", priority: "2", test_id: 201500 do
      skip_if_chrome('fragile in chrome')
      conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('multiple recipients')
      expect(c.private?).to be_falsey
      expect(c.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
    end

    it "should allow admins with read_roster permission to send a message without picking a context", priority: "1", test_id: 138677 do
      user = account_admin_user
      user_logged_in({:user => user})
      conversations
      compose to: [@s1], subject: 'context-free', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq 'context-free'
      expect(c.context).to eq Account.default
    end

    it "should not allow admins without read_roster permission to send a message without picking a context", priority: "1" do
      user = account_admin_user
      RoleOverride.manage_role_override(Account.default, Role.get_built_in_role('AccountAdmin'), 'read_roster', override: false, locked: false)
      user_logged_in({:user => user})
      conversations
      fj('#compose-btn').click
      wait_for_animations
      expect(fj('#recipient-row')).to have_attribute(:style, 'display: none;')
    end

    it "should not allow non-admins to send a message without picking a context", priority: "1", test_id: 138678 do
      conversations
      fj('#compose-btn').click
      wait_for_animations
      expect(fj('#recipient-row')).to have_attribute(:style, 'display: none;')
    end

    it "should allow non-admins to send a message to an account-level group", priority: "2", test_id: 201506 do
      @group = Account.default.groups.create(:name => "the group")
      @group.add_user(@s1)
      @group.add_user(@s2)
      @group.save
      user_logged_in({:user => @s1})
      conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@group, true)
      add_message_recipient @s2
      write_message_subject('blah')
      write_message_body('bluh')
      click_send
      run_jobs
      conv = @s2.conversations.last.conversation
      expect(conv.subject).to eq 'blah'
    end

    it "should allow messages to be sent individually for account-level groups", priority: "2", test_id: 201506 do
      @group = Account.default.groups.create(:name => "the group")
      @group.add_user(@s1)
      @group.add_user(@s2)
      @group.save
      user_logged_in({:user => @s1})
      conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@group, true)
      add_message_recipient @s2
      f("#bulk_message").click
      write_message_subject('blah')
      write_message_body('bluh')
      click_send
      run_jobs
      conv = @s2.conversations.last.conversation
      expect(conv.subject).to eq 'blah'
    end

    it "should allow admins to message users from their profiles", priority: "2", test_id: 201940 do
      user = account_admin_user
      user_logged_in({:user => user})

      get "/accounts/#{Account.default.id}/users"
      wait_for_ajaximations
      fj('[data-automation="users list"] tr a:has([name="IconMessage"])').click
      wait_for_ajaximations
      expect(f('.ac-token')).not_to be_nil
    end

    it "should allow selecting multiple recipients in one search", priority: "2", test_id: 201941 do
      skip_if_chrome('fragile in chrome')
      conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@course)
      message_recipients_input.send_keys('student')
      driver.action.key_down(modifier).perform
      fj(".ac-result:contains('first student')").click
      driver.action.key_up(modifier).perform
      fj(".ac-result:contains('second student')").click
      expect(ff('.ac-token').count).to eq 2
    end

    it "should not send the message on shift-enter", priority: "1", test_id: 206019 do
      skip_if_chrome('fragile in chrome')
      conversations
      compose course: @course, to: [@s1], subject: 'context-free', body: 'hallo!', send: false
      driver.action.key_down(:shift).perform
      message_body_input.send_keys(:enter)
      driver.action.key_up(:shift).perform
      expect(fj('#compose-new-message:visible')).not_to be_nil
    end

    context "with date-restricted course" do
      before(:each) do
        @course.restrict_enrollments_to_course_dates = true
        @course.restrict_student_past_view = true
        @course.restrict_student_future_view = true
        @course.save!
        user_logged_in(user: @s1)
      end

      it "should show course when in valid dates", priority: "1", test_id: 478993 do
        @course.conclude_at = 1.day.from_now
        @course.start_at = 1.day.ago
        @course.save!

        get '/conversations'
        move_to_click('.icon-compose')
        expect(fj("#compose-message-course option:contains('#{@course.name}')")).to be
      end

      it "should not show course before begin date", priority: "1", test_id: 478994 do
        @course.conclude_at = 2.days.from_now
        @course.start_at = 1.day.from_now
        @course.save!

        get '/conversations'
        move_to_click('.icon-compose')
        expect(f("#compose-message-course")).not_to contain_jqcss("option:contains('#{@course.name}')")
      end

      it "should not show course after end date", priority: "1", test_id: 478995 do
        @course.conclude_at = 1.day.ago
        @course.start_at = 2.days.ago
        @course.save!

        get '/conversations'
        move_to_click('.icon-compose')
        expect(f("#compose-message-course")).not_to contain_jqcss("option:contains('#{@course.name}')")
      end
    end

    #
    context "bulk_message locking" do
      before do
        # because i'm too lazy to create more users
        allow(Conversation).to receive(:max_group_conversation_size).and_return(1)
      end

      it "should check and lock the bulk_message checkbox when over the max size", priority: "2", test_id: 206022 do
        skip('COMMS-1164')
        conversations
        compose course: @course, subject: 'lockme', body: 'hallo!', send: false

        f("#recipient-search-btn").click
        wait_for_ajaximations
        f("li.everyone").click # send to everybody in the course
        wait_for_ajaximations

        selector = "#bulk_message"
        bulk_cb = f(selector)

        expect(bulk_cb).to be_disabled
        expect(is_checked(selector)).to be_truthy

        hover_and_click('.ac-token-remove-btn') # remove the token
        wait_for_ajaximations

        expect(bulk_cb).not_to be_disabled
        expect(is_checked(selector)).to be_falsey # should be unchecked
      end

      it "should leave the value the same as before after unlocking", priority: "2", test_id: 206023 do
        skip_if_chrome('fragile in chrome')
        conversations
        compose course: @course, subject: 'lockme', body: 'hallo!', send: false

        selector = "#bulk_message"
        bulk_cb = f(selector)
        move_to_click(selector)

        f("#recipient-search-btn").click
        wait_for_ajaximations
        f("li.everyone").click # send to everybody in the course
        wait_for_ajaximations
        hover_and_click('.ac-token-remove-btn') # remove the token

        expect(bulk_cb).not_to be_disabled
        expect(is_checked(selector)).to be_truthy # should still be checked
      end

      it "can compose a message to a single user", priority: "1", test_id: 117958 do
        conversations
        goto_compose_modal
        fj('.btn.dropdown-toggle :contains("Select course")').click
        wait_for_ajaximations

        expect(f('.dropdown-menu.open')).to be_truthy

        fj('.message-header-input .text:contains("Unnamed Course")').click
        wait_for_ajaximations

        # check for auto complete to fill in 'first student'
        f('.ac-input-cell .ac-input').send_keys('first st')
        expect(f('.result-name')).to include_text('first student')

        f('.result-name').click

        expect(f('.ac-token')).to include_text('first student')

        f('#compose-message-subject').send_keys('Hello out there all you happy people')
        f('.message-body textarea').send_keys("I'll pay you Tuesday for a hamburger today")
        click_send

        expect_flash_message :success, "Message sent!"
      end

      context "Message Address Book" do
        before(:each) do
          @t1_name = 'teacher1'
          @t2_name = 'teacher2'
          @t1 = user_factory(name: @t1_name, active_user: true)
          @t2 = user_factory(name: @t2_name, active_user: true)
          [@t1, @t2].each { |s| @course.enroll_teacher(s) }

          conversations
          goto_compose_modal
          fj('.btn.dropdown-toggle :contains("Select course")').click
          wait_for_ajaximations

          f('.dropdown-menu.open')

          fj('.message-header-input .text:contains("Unnamed Course")').click
          wait_for_ajaximations

          f('.message-header-input .icon-address-book').click
          wait_for_ajaximations
        end

        it "contains categories for teachers, students, and groups", priority: "1", test_id: 138899 do
          assert_result_names(true, ['Teachers', 'Students', 'Student Groups'])
        end

        it "categorizes enrolled teachers", priority: "1", test_id: 476933 do
          skip_if_chrome('fails in chrome')
          assert_categories('Teachers')
          assert_result_names(true, [@t1_name, @t2_name])
          assert_result_names(false, [@s1.name, @s2.name])
        end

        it "categorizes enrolled students", priority: "1", test_id: 476934 do
          skip_if_chrome('fails in chrome')
          assert_categories('Students')
          assert_result_names(false, [@t1_name, @t2_name])
          assert_result_names(true, [@s1.name, @s2.name])
        end

        it "categorizes enrolled students in groups", priority: "1", test_id: 476935 do
          skip_if_chrome('fails in chrome')
          assert_categories('Student Groups')
          assert_categories('the group')
          assert_result_names(false, [@t1_name, @t2_name])
          assert_result_names(true, [@s1.name, @s2.name])
        end
      end
    end
  end

  def assert_result_names(tf, names)
    names.each do |name|
      if tf
        expect(fj(".ac-result-container .result-name:contains(#{name})")).to be_truthy
      else
        expect(f(".ac-result-container")).not_to contain_jqcss(".result-name:contains(#{name})")
      end
    end
  end

  def assert_categories(container)
    fj(".ac-result-container .result-name:contains(#{container})").click
  end

  def goto_compose_modal
    fln('Inbox').click
    wait_for_ajaximations
    move_to_click('.icon-compose')
    wait_for_ajaximations
    f("#compose-new-message")
  end

end
