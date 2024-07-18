# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../common"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "pages/discussion_page"
require_relative "../../helpers/selective_release_common"

describe "Discussion Topic Show" do
  include SelectiveReleaseCommon
  include_context "in-process server selenium tests"

  context "when Discussions Redesign feature flag is ON" do
    before :once do
      Account.default.enable_feature!(:react_discussions_post)
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
      mod = @course.context_modules.create! name: "module 1"
      mod.add_item(type: "discussion_topic", id: @topic.id)
    end

    before do
      user_session(@teacher)
    end

    it "removes canvas headers when embedded within mobile apps" do
      resize_screen_to_mobile_width
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}?embed=true"
      expect(f("body")).not_to contain_jqcss("header#mobile-header")
      expect(f("body")).not_to contain_jqcss("header#header")
      expect(f("input[placeholder='Search entries or author...']")).to be_present
      expect(f("body")).not_to contain_jqcss("div#module_sequence_footer")
    end

    it "shows the correct number of rubrics in the find rubric option" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment:
      )

      rubric = rubric_model({ context: @course })
      rubric.associate_with(assignment, @course, purpose: "grading")

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Show Rubric')").click
      f(".find_rubric_link").click

      expect(fj(".select_rubric_link:contains(#{rubric.title})")).to be_present
      expect(ffj(".rubrics_dialog_rubric:visible").count).to eq 1
    end

    it "displays properly for a teacher" do
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("input[placeholder='Search entries or author...']")).to be_present
      expect(fj("span[data-testid='author_name']:contains('teacher')")).to be_present
      expect(ff("ul[data-testid='pill-container'] li").collect(&:text)).to eq ["AUTHOR", "TEACHER"]
      f("button[data-testid='discussion-post-menu-trigger']").click
      expect(fj("span:contains('Mark All as Read')")).to be_present
      expect(fj("span:contains('Edit')")).to be_present
      expect(fj("span:contains('Delete')")).to be_present
      expect(fj("span:contains('Close for Comments')")).to be_present
      expect(fj("span:contains('Send To...')")).to be_present
      expect(fj("span:contains('Copy To...')")).to be_present
      expect(f("body")).not_to contain_css(Discussion.summarize_button_selector)
    end

    context "group discussions in a course context" do
      it "loads without errors" do
        @group_discussion_topic = group_discussion_assignment
        get "/courses/#{@course.id}/discussion_topics/#{@group_discussion_topic.id}"
        f("button[data-testid='groups-menu-btn']").click

        # NOTE: this is not 10 Unread, it's 2 sibling elements, 1 is group 1, the other is 0 Unread
        fj("a:contains('group 10 Unread')").click
        wait_for_ajaximations
        expect(fj("h1:contains('topic - group 1')")).to be_present
        expect_no_flash_message :error
      end

      it "truncates long group names in the middle" do
        group_category = @course.group_categories.create!(name: "category")
        group1 = @course.groups.create!(name: "justasmalltowngirllivinginalonelyworldshetookthemidnighttraingoinganywhere first", group_category:)
        group2 = @course.groups.create!(name: "justasmalltowngirllivinginalonelyworldshetookthemidnighttraingoinganywhere second", group_category:)
        topic = @course.discussion_topics.build(title: "topic")
        topic.group_category = group_category
        topic.save!

        get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
        f("button[data-testid='groups-menu-btn']").click
        menu_items = ff("[data-testid='groups-menu-item']")
        truncated_menu_items = ["justasmall…here first\n0 Unread", "justasmal…e second\n0 Unread"]
        menu_items.each do |item|
          expect(truncated_menu_items).to include item.text
          hover(item)
          # check tooltip text
          expect(fj("span:contains('#{group1.name}')")).to be_present if item.text.include? "first"
          expect(fj("span:contains('#{group2.name}')")).to be_present if item.text.include? "second"
        end
      end
    end

    it "Displays when all features are turned on" do
      Account.site_admin.enable_feature! :react_discussions_post
      @course.root_account.enable_feature! :discussions_reporting
      Account.site_admin.enable_feature! :discussion_checkpoints

      gc = @course.account.group_categories.create(name: "Group Category")
      group = group_model(name: "Group", group_category: gc, context: @course.account)
      group_membership_model(group:, user: @teacher)
      topic = discussion_topic_model(context: group)

      get "/groups/#{group.id}/discussion_topics/#{topic.id}"
      expect(fj("h1:contains('value for title')")).to be_present
    end

    it "has a module progression section when applicable" do
      module1 = @course.context_modules.create!(name: "module1")
      item1 = @course.assignments.create!(
        name: "First Item",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      module1.add_item(id: item1.id, type: "assignment")
      item2 = @course.discussion_topics.create!(
        title: "Second Item",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
      module1.add_item(id: item2.id, type: "discussion_topic")
      get "/courses/#{@course.id}/discussion_topics/#{item2.id}"
      expect(f("a[aria-label='Previous Module Item']")).to be_present
    end

    it "displays module prerequisites" do
      student_in_course(active_all: true)
      user_session(@student)
      module1 = @course.context_modules.create!(name: "module1")
      module1.unlock_at = Time.now + 1.day

      topic = @course.discussion_topics.create!(
        title: "Ya Ya Ding Dong",
        user: @teacher,
        message: "By Will Ferrell and My Marianne",
        workflow_state: "published"
      )
      module1.add_item(type: "discussion_topic", id: topic.id)
      module1.save!

      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      wait_for_ajaximations

      expect(fj("span:contains('This topic is part of the module #{module1.name}, which is locked')")).to be_present
    end

    it "open Find Outcome dialog when adding a rubric" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment:
      )

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Add Rubric')").click
      fj("a.add_rubric_link:contains('Add Rubric')").click
      f("a#add_learning_outcome_link").click

      expect(fj("span.ui-dialog-title:contains('Find Outcomes')")).to be_present
    end

    it "Able to reply to a group discussion" do
      gc = @course.account.group_categories.create(name: "Group Category")
      group = group_model(name: "Group", group_category: gc, context: @course.account)
      group_membership_model(group:, user: @teacher)
      topic = discussion_topic_model(context: group, type: "Announcement")

      get "/groups/#{group.id}/discussion_topics/#{topic.id}"

      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      type_in_tiny "textarea", "Test Reply"
      fj("button:contains('Reply')").click
      wait_for_ajaximations
      expect(fj("p:contains('Test Reply')")).to be_present
    end

    context "checkpoints" do
      before :once do
        Account.default.enable_feature!(:discussion_checkpoints)
        student_in_course(active_all: true)

        @due_at = 2.days.from_now
        @replies_required = 2
        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: @due_at }],
          points_possible: 6
        )
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: @due_at }],
          points_possible: 7,
          replies_required: @replies_required
        )
      end

      it "lets students see the checkpoints tray" do
        user_session(@student)
        get "/courses/#{@course.id}/discussion_topics/#{@checkpointed_discussion.id}"

        fj("button:contains('View Due Dates')").click
        wait_for_ajaximations
        expect(fj("span:contains('Due Dates')")).to be_present
        reply_to_topic_contents = f("span[data-testid='reply_to_topic_section']").text
        expect(reply_to_topic_contents).to include("Reply to Topic")
        expect(reply_to_topic_contents).to include(format_date_for_view(@due_at))

        reply_to_entry_contents = f("span[data-testid='reply_to_entry_section']").text
        expect(reply_to_entry_contents).to include("Additional Replies Required: #{@replies_required}")
        expect(reply_to_entry_contents).to include(format_date_for_view(@due_at))
      end

      it "lets students see the checkpoints tray with completed status on initial page load" do
        root_entry = @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to topic")

        @replies_required.times { |i| @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to entry #{i}", parent_entry: root_entry) }

        user_session(@student)
        get "/courses/#{@course.id}/discussion_topics/#{@checkpointed_discussion.id}"

        fj("button:contains('View Due Dates')").click
        wait_for_ajaximations
        reply_to_topic_contents = f("span[data-testid='reply_to_topic_section']").text
        expect(reply_to_topic_contents).to include("Completed #{format_date_for_view(root_entry.created_at)}")
        reply_to_entry_contents = f("span[data-testid='reply_to_entry_section']").text
        expect(reply_to_entry_contents).to include("Completed")
        expect(reply_to_topic_contents).to include("Completed #{format_date_for_view(@checkpointed_discussion.discussion_entries.last.created_at)}")
      end

      it "lets students see completed status for reply to topic as soon as they successfully reply to topic" do
        user_session(@student)
        get "/courses/#{@course.id}/discussion_topics/#{@checkpointed_discussion.id}"

        fj("button:contains('View Due Dates')").click
        wait_for_ajaximations
        reply_to_topic_contents = f("span[data-testid='reply_to_topic_section']").text
        expect(reply_to_topic_contents).not_to include("Completed")
        fj("button:contains('Close')").click

        f("button[data-testid='discussion-topic-reply']").click
        wait_for_ajaximations
        type_in_tiny "textarea", "Test Reply"
        fj("button:contains('Reply')").click
        wait_for_ajaximations
        fj("button:contains('View Due Dates')").click
        reply_to_topic_contents = f("span[data-testid='reply_to_topic_section']").text
        expect(reply_to_topic_contents).to include("Completed #{format_date_for_view(@checkpointed_discussion.reload.discussion_entries.last.created_at)}")
      end

      it "lets teachers see checkpoints tray" do
        user_session(@teacher)
        get "/courses/#{@course.id}/discussion_topics/#{@checkpointed_discussion.id}"

        fj("button:contains('View Due Dates')").click
        wait_for_ajaximations
        expect(fj("span:contains('Due Dates')")).to be_present
        reply_to_topic_contents = f("span[data-testid='reply_to_topic_section']").text
        expect(reply_to_topic_contents).to include("Reply to Topic")
        expect(reply_to_topic_contents).to include(format_date_for_view(@due_at))

        reply_to_entry_contents = f("span[data-testid='reply_to_entry_section']").text
        expect(reply_to_entry_contents).to include("Additional Replies Required: #{@replies_required}")
        expect(reply_to_entry_contents).to include(format_date_for_view(@due_at))
      end
    end

    context "Assign To option" do
      include ItemsAssignToTray
      include ContextModulesCommon

      before :once do
        differentiated_modules_on
        @discussion = @course.discussion_topics.create!(
          title: "Discussion 1",
          discussion_type: "threaded",
          posted_at: "2017-07-09 16:32:34",
          user: @teacher
        )
      end

      it "renders Assign To option" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"

        Discussion.click_assign_to_button
        expect(icon_type_exists?("Discussion")).to be true
        expect(tray_header.text).to eq("Discussion 1")
      end

      it "saves and shows override updates when tray reaccessed" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"

        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_available_date(0, "12/27/2024")
        update_available_time(0, "8:00 AM")

        click_save_button
        keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2024")
        expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
      end

      it "does not show due date inputs on ungraded discussion" do
        dt = @course.discussion_topics.create!(
          title: "Ungraded Discussion",
          discussion_type: "threaded",
          posted_at: "2024-02-09 16:32:34",
          user: @teacher
        )
        get "/courses/#{@course.id}/discussion_topics/#{dt.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner
        expect(module_item_assign_to_card.last).not_to contain_css(due_date_input_selector)
        expect(module_item_assign_to_card.last).not_to contain_css(reply_to_topic_due_date_input_selector)
        expect(module_item_assign_to_card.last).not_to contain_css(required_replies_due_date_input_selector)
      end

      it "shows due date inputs on graded discussion" do
        assignment = @course.assignments.create!(
          name: "Assignment",
          submission_types: ["online_text_entry"],
          points_possible: 20
        )
        dt = @course.discussion_topics.create!(
          title: "Graded Discussion",
          discussion_type: "threaded",
          posted_at: "2017-07-09 16:32:34",
          user: @teacher,
          assignment:
        )
        get "/courses/#{@course.id}/discussion_topics/#{dt.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner
        expect(module_item_assign_to_card.last).to contain_css(due_date_input_selector)
      end

      it "does not show the button when the user does not have the moderate_forum permission" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"
        expect(element_exists?(Discussion.assign_to_button_selector)).to be_truthy

        RoleOverride.create!(context: @course.account, permission: "moderate_forum", role: teacher_role, enabled: false)
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"
        expect(element_exists?(Discussion.assign_to_button_selector)).to be_falsey
      end

      it "does not show mastery paths in the assign to list when ungraded" do
        @course.conditional_release = true
        @course.save!

        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        option_elements = INSTUI_Select_options(module_item_assignee[0])
        option_names = option_elements.map(&:text)
        expect(option_names).not_to include("Mastery Paths")
      end

      it "does show mastery paths in the assign to list when graded" do
        @course.conditional_release = true
        @course.save!

        assignment = @course.assignments.create!(
          name: "Assignment",
          submission_types: ["online_text_entry"],
          points_possible: 20
        )
        dt = @course.discussion_topics.create!(
          title: "Graded Discussion",
          discussion_type: "threaded",
          posted_at: "2017-07-09 16:32:34",
          user: @teacher,
          assignment:
        )

        get "/courses/#{@course.id}/discussion_topics/#{dt.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        option_elements = INSTUI_Select_options(module_item_assignee[0])
        option_names = option_elements.map(&:text)
        expect(option_names).to include("Mastery Paths")
      end
    end

    context "student availability" do
      before :once do
        student_in_course(active_all: true)
        @topic.update!(message: "a very cool discussion")
      end

      before do
        user_session(@student)
      end

      it "shows discussion body for unlocked discussions" do
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(Discussion.discussion_page_body).to include_text("a very cool discussion")
      end

      it "shows lock indication for discussions locked by discussion's unlock_at date" do
        @topic.update!(unlock_at: 1.day.from_now)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(Discussion.discussion_page_body).to include_text("This topic is locked until")
        expect(Discussion.discussion_page_body).not_to include_text("a very cool discussion")
      end

      it "shows lock indication for discussions locked by discussion's lock_at date" do
        @topic.update!(lock_at: 1.day.ago)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(Discussion.discussion_page_body).to include_text("This topic is closed for comments")
        expect(Discussion.discussion_page_body).to include_text("a very cool discussion")
      end

      it "shows lock indication for discussions locked by student override unlock_at" do
        ao = @topic.assignment_overrides.create!(unlock_at: 1.day.from_now, unlock_at_overridden: true)
        ao.assignment_override_students.create!(user: @student)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(Discussion.discussion_page_body).to include_text("This topic is locked until")
        expect(Discussion.discussion_page_body).not_to include_text("a very cool discussion")
      end

      it "shows lock indication for discussions locked by student override lock_at" do
        ao = @topic.assignment_overrides.create!(lock_at: 1.day.ago, lock_at_overridden: true)
        ao.assignment_override_students.create!(user: @student)
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        expect(Discussion.discussion_page_body).to include_text("This topic is closed for comments")
        expect(Discussion.discussion_page_body).to include_text("a very cool discussion")
      end
    end

    context "when Discussion Summary feature flag is ON" do
      before do
        Account.default.enable_feature!(:discussion_summary)

        @inst_llm = double("InstLLM::Client")
        allow(InstLLMHelper).to receive(:client).and_return(@inst_llm)

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      end

      it "allows a teacher to summarize a discussion" do
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        Discussion.click_summarize_button

        expect(Discussion.summary_text).to include_text("refined_summary_1")
        expect(Discussion.summary_like_button).to be_present
        expect(Discussion.summary_dislike_button).to be_present
        expect(Discussion.summary_generate_button).to be_present
        expect(Discussion.summary_disable_button).to be_present
        expect(f("body")).not_to contain_css(Discussion.summarize_button_selector)

        Discussion.click_summary_like_button
        Discussion.click_summary_dislike_button
        Discussion.click_summary_disable_button

        expect(f("body")).not_to contain_css(Discussion.summary_text_selector)
        expect(Discussion.summarize_button).to be_present
      end

      it "generates a new summary if discussion has changed" do
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        Discussion.click_summarize_button

        expect(Discussion.summary_text).to include_text("refined_summary_1")

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

        expect(Discussion.summary_text).to include_text("refined_summary_1")

        @topic.discussion_entries.create!(user: @student, message: "reply to topic")

        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_2" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_2" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

        expect(Discussion.summary_text).to include_text("refined_summary_2")
      end

      it "generates a new summary if locale has changed" do
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        Discussion.click_summarize_button

        expect(Discussion.summary_text).to include_text("refined_summary_1")

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

        expect(Discussion.summary_text).to include_text("refined_summary_1")

        @teacher.update!(locale: "es")

        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_2" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

        expect(Discussion.summary_text).to include_text("refined_summary_2")
      end

      it "allows teacher to generate a summary with user input" do
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_1" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        Discussion.click_summarize_button

        expect(Discussion.summary_text).to include_text("refined_summary_1")

        user_input = "focus on student feedback"
        Discussion.update_summary_user_input(user_input)

        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary_2" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary_2" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        Discussion.click_summary_generate_button

        expect(Discussion.summary_text).to include_text("refined_summary_2")
      end

      it "shows an error message when summarization fails" do
        expect(@inst_llm).to receive(:chat).and_raise(InstLLM::ThrottlingError)

        Discussion.click_summarize_button

        expect(Discussion.summary_error).to include_text("Sorry, the service is currently busy. Please try again later.")
      end
    end
  end
end
