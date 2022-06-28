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

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    @s3 = user_factory(name: "third student")
    [@s1, @s2, @s3].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, "active") }
    cat = @course.group_categories.create(name: "the groups")
    @group = cat.groups.create(name: "the group", context: @course)
    @group.users = [@s1, @s2]
    @t2 =  user_factory(name: "second teacher", active_user: true)
    @course.enroll_teacher(@t2)
  end

  describe "message sending" do
    context "when react_inbox feature flag is off" do
      before do
        Account.default.set_feature_flag! :react_inbox, "off"
      end

      it "shows error messages when no recipient is entered", priority: "1" do
        get "/conversations"
        move_to_click(".icon-compose")
        click_send
        errors = ff(".error_text")
        expect(errors[2].text).to include("Invalid recipient name.")
        expect(errors[1].text).to include("Required field")
      end

      it "starts a group conversation when there is only one recipient", priority: "2" do
        conversations
        compose course: @course, to: [@s1], subject: "single recipient", body: "hallo!"
        c = @s1.conversations.last.conversation
        expect(c.subject).to eq("single recipient")
      end

      it "starts a group conversation when there is more than one recipient", priority: "2" do
        conversations
        compose course: @course, to: [@s1, @s2], subject: "multiple recipients", body: "hallo!"
        c = @s1.conversations.last.conversation
        expect(c.subject).to eq("multiple recipients")
        expect(c.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
      end

      it "allows admins with read_roster permission to send a message without picking a context", priority: "1" do
        user = account_admin_user
        user_logged_in({ user: user })
        conversations
        compose to: [@s1], subject: "context-free", body: "hallo!"
        c = @s1.conversations.last.conversation
        expect(c.subject).to eq "context-free"
        expect(c.context).to eq Account.default
      end

      it "does not allow admins without read_roster permission to send a message without picking a context", priority: "1" do
        user = account_admin_user
        RoleOverride.manage_role_override(Account.default, admin_role, "read_roster", override: false, locked: false)
        user_logged_in({ user: user })
        conversations
        f("#compose-btn").click
        wait_for_animations
        expect(f("#recipient-row")).to have_attribute(:style, "display: none;")
      end

      it "does not allow non-admins to send a message without picking a context", priority: "1" do
        conversations
        f("#compose-btn").click
        wait_for_animations
        expect(f("#recipient-row")).to have_attribute(:style, "display: none;")
      end

      it "allows non-admins to send a message to an account-level group", priority: "2" do
        @group = Account.default.groups.create(name: "the group")
        @group.add_user(@s1)
        @group.add_user(@s2)
        @group.save
        user_logged_in({ user: @s1 })
        conversations
        f("#compose-btn").click
        wait_for_ajaximations
        select_message_course(@group, true)
        add_message_recipient @s2
        write_message_subject("blah")
        write_message_body("bluh")
        click_send
        run_jobs
        conv = @s2.conversations.last.conversation
        expect(conv.subject).to eq "blah"
      end

      it "allows messages to be sent individually for account-level groups", priority: "2" do
        account_level_group = Account.default.groups.create(name: "account level group")
        account_level_group.add_user(@s1)
        account_level_group.add_user(@s2)
        account_level_group.save
        user_logged_in({ user: @s1 })
        conversations
        f("#compose-btn").click
        wait_for_ajaximations
        select_message_course(account_level_group, true)
        add_message_recipient @s2
        f("#bulk_message").click
        write_message_subject("blah")
        write_message_body("bluh")
        click_send
        run_jobs
        conv = @s2.conversations.last.conversation
        expect(conv.subject).to eq "blah"
      end

      it "allows selecting multiple recipients in one search", priority: "2" do
        conversations
        f("#compose-btn").click
        wait_for_ajaximations
        select_message_course(@course)
        message_recipients_input.send_keys("student")
        driver.action.key_down(modifier).perform
        fj(".ac-result:contains('first student')").click
        driver.action.key_up(modifier).perform
        fj(".ac-result:contains('second student')").click
        expect(ff(".ac-token").count).to eq 2
      end

      it "does not send the message on shift-enter", priority: "1" do
        conversations
        compose course: @course, to: [@s1], subject: "context-free", body: "hallo!", send: false
        message_body_input.send_keys([:shift, :enter])
        expect(fj("#compose-new-message:visible")).not_to be_nil
      end

      context "with date-restricted course" do
        before do
          @course.restrict_enrollments_to_course_dates = true
          @course.restrict_student_past_view = true
          @course.restrict_student_future_view = true
          @course.save!
        end

        context "teacher inbox" do
          before do
            user_logged_in(user: @teacher)
          end

          it "shows course when in valid dates", priority: "1" do
            @course.conclude_at = 1.day.from_now
            @course.start_at = 1.day.ago
            @course.save!

            get "/conversations"
            move_to_click(".icon-compose")
            expect(fj("#compose-message-course option:contains('#{@course.name}')")).to be_present
          end

          context "before course start date" do
            it "shows course before begin date", priority: "1" do
              @course.conclude_at = 2.days.from_now
              @course.start_at = 1.day.from_now
              @course.save!

              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).to contain_jqcss("option:contains('#{@course.name}')")
            end
          end

          context "soft concluded course" do
            it "shows course after end date", priority: "1" do
              @course.conclude_at = 1.day.ago
              @course.start_at = 2.days.ago
              @course.save!

              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).to contain_jqcss("option:contains('#{@course.name}')")
            end
          end

          context "hard concluded course" do
            it "does not show course after Hard Conclusion", priority: "1" do
              @course.complete!
              @course.save!

              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).not_to contain_jqcss("option:contains('#{@course.name}')")
            end
          end
        end

        context "student inbox" do
          before do
            user_logged_in(user: @s1)
          end

          it "shows course when in valid dates", priority: "1" do
            @course.conclude_at = 1.day.from_now
            @course.start_at = 1.day.ago
            @course.save!

            get "/conversations"
            move_to_click(".icon-compose")
            expect(fj("#compose-message-course option:contains('#{@course.name}')")).to be_present
          end

          context "before course start date" do
            it "does not show course before begin date", priority: "1" do
              @course.conclude_at = 2.days.from_now
              @course.start_at = 1.day.from_now
              @course.save!

              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).not_to contain_jqcss("option:contains('#{@course.name}')")
            end
          end

          context "soft concluded course" do
            before do
              @course.conclude_at = 1.day.ago
              @course.start_at = 2.days.ago
              @course.save!
            end

            it "shows course after end date", priority: "1" do
              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).to contain_jqcss("option:contains('#{@course.name}')")
            end

            it "shows other students as recipient options after end date", priority: "1" do
              get "/conversations"
              f("#compose-btn").click
              wait_for_ajaximations

              select_message_course(@course)
              wait_for_ajaximations

              message_recipients_input.send_keys("student")
              wait_for_ajaximations

              expect(ffj(".ac-result").count).to eq(@course.students.count)
            end
          end

          context "hard concluded course" do
            it "does not show course after Hard Conclusion", priority: "1" do
              @course.complete!
              @course.save!

              get "/conversations"
              move_to_click(".icon-compose")
              expect(f("#compose-message-course")).not_to contain_jqcss("option:contains('#{@course.name}')")
            end
          end
        end
      end

      context "bulk_message locking" do
        before do
          # because i'm too lazy to create more users
          allow(Conversation).to receive(:max_group_conversation_size).and_return(1)
        end

        it "checks and lock the bulk_message checkbox when over the max size", priority: "2" do
          conversations
          compose course: @course, subject: "lockme", body: "hallo!", send: false

          f("#recipient-search-btn").click
          wait_for_ajaximations
          f("li.everyone").click # send to everybody in the course
          wait_for_ajaximations

          selector = "#bulk_message"
          bulk_cb = f(selector)

          expect(bulk_cb).to be_disabled
          expect(is_checked(selector)).to be_truthy

          hover_and_click(".ac-token-remove-btn") # remove the token
          wait_for_ajaximations

          expect(bulk_cb).not_to be_disabled
          expect(is_checked(selector)).to be_falsey # should be unchecked
        end

        it "leaves the value the same as before after unlocking", priority: "2" do
          conversations
          compose course: @course, subject: "lockme", body: "hallo!", send: false

          selector = "#bulk_message"
          bulk_cb = f(selector)
          move_to_click(selector)

          f("#recipient-search-btn").click
          wait_for_ajaximations
          f("li.everyone").click # send to everybody in the course
          wait_for_ajaximations
          hover_and_click(".ac-token-remove-btn") # remove the token

          expect(bulk_cb).not_to be_disabled
          expect(is_checked(selector)).to be_truthy # should still be checked
        end

        it "can compose a message to a single user", priority: "1" do
          conversations
          goto_compose_modal
          select_message_course(@course)

          # check for auto complete to fill in 'first student'
          f(".ac-input-cell .ac-input").send_keys("first st")
          expect(f(".result-name")).to include_text("first student")

          f(".result-name").click

          expect(f(".ac-token")).to include_text("first student")

          f("#compose-message-subject").send_keys("Hello out there all you happy people")
          f(".message-body textarea").send_keys("I'll pay you Tuesday for a hamburger today")
          click_send

          expect_flash_message :success, "Message sent!"
        end

        context "Message Address Book" do
          before do
            @t1_name = "teacher1"
            @t2_name = "teacher2"
            @t1 = user_factory(name: @t1_name, active_user: true)
            @t2 = user_factory(name: @t2_name, active_user: true)
            [@t1, @t2].each { |s| @course.enroll_teacher(s) }

            conversations
            goto_compose_modal
            select_message_course(@course)

            f(".message-header-input .icon-address-book").click
            wait_for_ajaximations
          end

          it "contains categories for teachers, students, and groups", priority: "1" do
            assert_result_names(true, ["Teachers", "Students", "Student Groups"])
          end

          it "categorizes enrolled teachers", priority: "1" do
            assert_categories("Teachers")
            assert_result_names(true, [@t1_name, @t2_name])
            assert_result_names(false, [@s1.name, @s2.name])
          end

          it "categorizes enrolled students", priority: "1" do
            assert_categories("Students")
            assert_result_names(false, [@t1_name, @t2_name])
            assert_result_names(true, [@s1.name, @s2.name])
          end

          it "categorizes enrolled students in groups", priority: "1" do
            assert_categories("Student Groups")
            assert_categories("the group")
            assert_result_names(false, [@t1_name, @t2_name])
            assert_result_names(true, [@s1.name, @s2.name])
          end
        end
      end
    end

    context "when react_inbox feature flag is on", ignore_js_errors: true do
      before do
        Account.default.enable_feature! :react_inbox
      end

      context "when user_id and user_name url params exist" do
        it "properly sends a message based on url params" do
          site_admin_logged_in
          get "/conversations?embed=true&&user_name=#{@s1.name}&&user_id=#{@s1.id}"
          expect(fj("h2:contains('Compose Message')")).to be_present
          expect(fj("span[data-testid='address-book-tag'] button:contains(#{@s1.name})")).to be_present
          f("textarea[data-testid='message-body']").send_keys "confirm if you get this!"
          fj("button:contains('Send')").click
          wait_for_ajaximations
          cm = ConversationMessage.last
          expect(cm.conversation_message_participants.pluck(:user_id)).to match_array [@s1.id, @admin.id]
          expect(cm.body).to eq "confirm if you get this!"

          f("button[data-testid='compose']").click
          wait_for_ajaximations
          expect(f("body")).not_to contain_jqcss("span[data-testid='address-book-tag'] button:contains(#{@s1.name})")
        end
      end

      context "shows correct address book items" do
        context "for teacher" do
          before do
            user_session(@teacher)
            get "/conversations"
            open_react_compose_modal_addressbook
          end

          it "correctly shows course options", priority: "1" do
            # back, all in course, Teachers, Students, Student Groups
            expect(ff("div[data-testid='address-book-item']").count).to eq(5)
            expect(fj("div[data-testid='address-book-item']:contains('All in #{@course.name}')")).to be_present
          end

          it "correctly shows Teachers option", priority: "1" do
            fj("div[data-testid='address-book-item']:contains('Teachers')").click
            wait_for_ajaximations
            # back, all in Teachers, @Teacher name, @t2 name
            expect(ff("div[data-testid='address-book-item']").count).to eq(4)
            expect(fj("div[data-testid='address-book-item']:contains('All in Teachers')")).to be_present
          end

          it "correctly shows students option", priority: "1" do
            fj("div[data-testid='address-book-item']:contains('Students')").click
            wait_for_ajaximations
            # back, all in Students, @s1 name, @s2 name, @s3 name
            expect(ff("div[data-testid='address-book-item']").count).to eq(5)
            expect(fj("div[data-testid='address-book-item']:contains('All in Students')")).to be_present
          end

          # There is no option to send a message to all groups
          it "correctly shows student groups option", priority: "1" do
            fj("div[data-testid='address-book-item']:contains('Student Groups')").click
            wait_for_ajaximations

            # back, @group name
            expect(ff("div[data-testid='address-book-item']").count).to eq(2)
          end

          it "correctly shows student group option", priority: "1" do
            fj("div[data-testid='address-book-item']:contains('Student Groups')").click
            wait_for_ajaximations
            fj("div[data-testid='address-book-item']:contains('#{@group.name}')").click
            wait_for_ajaximations

            # Back, all in the group, @s1, @s2
            expect(ff("div[data-testid='address-book-item']").count).to eq(4)
            expect(fj("div[data-testid='address-book-item']:contains('All in #{@group.name}')")).to be_present
          end
        end

        context "for student" do
          before do
            user_session(@s1)
            get "/conversations"
          end

          it "does not show student the all in course option by default", priority: "1" do
            # back, Teachers, Students, Student Groups
            open_react_compose_modal_addressbook
            expect(ff("div[data-testid='address-book-item']").count).to eq(4)
            expect(fj("div[data-testid='address-book-item']:contains('Back')")).to be_displayed
            expect(fj("div[data-testid='address-book-item']:contains('Teachers')")).to be_displayed
            expect(fj("div[data-testid='address-book-item']:contains('Students')")).to be_displayed
            expect(fj("div[data-testid='address-book-item']:contains('Student Groups')")).to be_displayed
          end

          it "correctly shows student the all in course option if send_messages_all is set to true", priority: "1" do
            # back, all in course, Teachers, Students, Student Groups
            @course.account.role_overrides.create!(permission: :send_messages_all, role: student_role, enabled: true)
            open_react_compose_modal_addressbook
            expect(ff("div[data-testid='address-book-item']").count).to eq(5)
            expect(fj("div[data-testid='address-book-item']:contains('All in #{@course.name}')")).to be_present
          end
        end
      end

      context "correctly sends messages to contexts as a teacher" do
        before do
          user_session(@teacher)
          get "/conversations"
          f("button[data-testid='compose']").click
          f("input[placeholder='Select Course']").click
          fj("li:contains('#{@course.name}')").click
          ff("input[aria-label='Address Book']")[1].click
        end

        it "correctly sends message to the entire course", priority: "1" do
          fj("div[data-testid='address-book-item']:contains('All in #{@course.name}')").click
          expect(fj("span[data-testid='address-book-tag']:contains('All in #{@course.name}')")).to be_present

          f("textarea[data-testid='message-body']").send_keys "hallo!"
          fj("button:contains('Send')").click
          wait_for_ajaximations

          expect(@s2.conversations.last.conversation.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @t2, @s1, @s2, @s3].collect(&:id).sort)
        end

        it "correctly sends message to all teachers", priority: "1" do
          fj("div[data-testid='address-book-item']:contains('Teachers')").click
          wait_for_ajaximations

          fj("div[data-testid='address-book-item']:contains('All in Teachers')").click
          expect(fj("span[data-testid='address-book-tag']:contains('All in Teachers')")).to be_present

          f("textarea[data-testid='message-body']").send_keys "hallo!"
          fj("button:contains('Send')").click
          wait_for_ajaximations

          expect(@t2.conversations.last.conversation.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @t2].collect(&:id).sort)
        end

        it "correctly wipes address book after cancelling compose", priority: "1" do
          fj("div[data-testid='address-book-item']:contains('Teachers')").click
          wait_for_ajaximations

          fj("div[data-testid='address-book-item']:contains('All in Teachers')").click
          expect(fj("span[data-testid='address-book-tag']:contains('All in Teachers')")).to be_present

          fj("button:contains('Cancel')").click
          wait_for_ajaximations

          f("button[data-testid='compose']").click
          expect(f("body")).not_to contain_jqcss("div[data-testid='address-book-item']:contains('All in Teachers')")
        end

        it "correctly sends message to all students", priority: "1" do
          fj("div[data-testid='address-book-item']:contains('Students')").click
          wait_for_ajaximations

          fj("div[data-testid='address-book-item']:contains('All in Students')").click
          expect(fj("span[data-testid='address-book-tag']:contains('All in Students')")).to be_present

          f("textarea[data-testid='message-body']").send_keys "hallo!"
          fj("button:contains('Send')").click
          wait_for_ajaximations

          expect(@s2.conversations.last.conversation.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2, @s3].collect(&:id).sort)
        end

        it "correctly sends message to the entire student group", priority: "1" do
          fj("div[data-testid='address-book-item']:contains('Student Groups')").click
          wait_for_ajaximations
          fj("div[data-testid='address-book-item']:contains('#{@group.name}')").click
          wait_for_ajaximations
          fj("div[data-testid='address-book-item']:contains('All in #{@group.name}')").click

          expect(fj("span[data-testid='address-book-tag']:contains('All in #{@group.name}')")).to be_present

          f("textarea[data-testid='message-body']").send_keys "hallo!"
          fj("button:contains('Send')").click
          wait_for_ajaximations

          expect(@s2.conversations.last.conversation.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
        end
      end

      it "lets admins send a message without context" do
        admin_logged_in
        get "/conversations"
        f("button[data-testid='compose']").click
        ff("input[aria-label='Address Book']")[1].click
        wait_for_ajaximations
        fj("li:contains('Students')").click
        fj("li:contains('#{@s1.name}')").click
        fj("li:contains('#{@s2.name}')").click
        f("textarea[data-testid='message-body']").send_keys "sent to both of you"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        expect(@s1.conversations.last.conversation.conversation_participants.collect(&:user_id).sort).to eq [@s1.id, @s2.id, @admin.id]
      end

      it "allows messages to be sent individually for account-level groups", priority: "2" do
        @group.destroy
        account_level_group = Account.default.groups.create(name: "the account level group")
        account_level_group.add_user(@s1)
        account_level_group.add_user(@s2)
        account_level_group.save
        user_logged_in({ user: @s1 })
        get "/conversations"
        f("button[data-testid='compose']").click
        f("input[placeholder='Select Course']").click
        wait_for_ajaximations
        fj("li:contains('#{account_level_group.name}')").click
        force_click("input[data-testid='individual-message-checkbox']")
        ff("input[aria-label='Address Book']")[1].click
        fj("li:contains('second student')").click
        f("textarea[data-testid='message-body']").send_keys "sent to everyone in the account level group"
        fj("button:contains('Send')").click
        wait_for_ajaximations
        expect(@s2.conversations.last.conversation.conversation_messages.last.body).to eq "sent to everyone in the account level group"
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
    fln("Inbox").click
    wait_for_ajaximations
    move_to_click(".icon-compose")
    wait_for_ajaximations
    f("#compose-new-message")
  end

  def open_react_compose_modal_addressbook
    # Open compose modal
    f("button[data-testid='compose']").click

    # select the only course option
    f("input[placeholder='Select Course']").click
    f("li[role='none']").click

    # Open address book
    ff("input[aria-label='Address Book']")[1].click
  end
end
