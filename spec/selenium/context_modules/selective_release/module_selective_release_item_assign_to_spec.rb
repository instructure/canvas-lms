# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/module_item_selective_release_assign_to_shared_examples"

describe "selective_release module item assign to tray" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before(:once) do
    course_with_teacher(active_all: true)

    @course.enable_feature! :quizzes_next
    @course.context_external_tools.create!(
      name: "Quizzes.Next",
      consumer_key: "test_key",
      shared_secret: "test_secret",
      tool_id: "Quizzes 2",
      url: "http://example.com/launch"
    )
    @course.root_account.settings[:provision] = { "lti" => "lti url" }
    @course.root_account.save!
  end

  context "using assign to tray for newly created items" do
    before(:once) do
      @course.context_modules.create!(name: "module1")
    end

    before do
      user_session(@teacher)
    end

    it "shows the correct icon type and title a new assignment" do
      go_to_modules
      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Assignment")).to be true
      expect(item_type_text.text).to eq("Assignment")
    end

    it "shows the correct icon type and title for a classic quiz" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        f("label[for=classic_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "shows the correct icon type and title for an NQ quiz" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "An NQ Quiz") do
        f("label[for=new_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "shows the correct icon type and title for a classic quiz after indent" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        f("label[for=classic_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_indent(module_item)
      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "shows the assign to option for newly-created items that a teacher can manage" do
      go_to_modules
      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      item = ContentTag.last
      manage_module_item_button(item).click
      expect(module_item(item.id)).to include_text("Assign To...")

      RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
      go_to_modules
      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      item = ContentTag.last
      manage_module_item_button(item).click
      expect(module_item(item.id)).not_to include_text("Assign To...")
    end
  end

  context "assign to tray values" do
    before(:once) do
      module_setup
      @section1 = @course.course_sections.create!(name: "section1")
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module_item2 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment2.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it "shows tray and Everyone pill when accessing tray for an item that has no overrides" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      expect(item_tray_exists?).to be true
      expect(module_item_assign_to_card[0]).to be_displayed
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
    end

    it "shows points possible only when present", :ignore_js_errors do
      @assignment1.update!(points_possible: 10)
      @assignment2.update!(points_possible: nil)
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      expect(item_type_text.text).to include("10 pts")

      click_cancel_button
      manage_module_item_button(@module_item2).click
      click_manage_module_item_assign_to(@module_item2)
      expect(item_type_text.text).not_to include("pts")
    end

    it "changes pills when new card is added" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      keep_trying_for_attempt_times(attempts: 3, sleep_interval: 0.5) do
        click_add_assign_to_card
        expect(element_exists?(assign_to_in_tray_selector("Remove Everyone"))).to be_falsey
      end

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    end

    it "changes first card pill to Everyone when second card deleted" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      keep_trying_for_attempt_times(attempts: 3, sleep_interval: 0.5) do
        click_add_assign_to_card
        expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      end

      click_delete_assign_to_card(1)
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
    end

    it "first card pill changes to Everyone else when student added to first card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      select_module_item_assignee(0, @student1.name)

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "second card selection does not contain student when student added to first card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      select_module_item_assignee(0, @student1.name)

      click_add_assign_to_card
      option_elements = INSTUI_Select_options(module_item_assignee[1])
      option_names = option_elements.map(&:text)
      expect(option_names).not_to include(@student1.name)
      expect(option_names).to include(@student2.name)
    end

    it "shows existing enrollments when accessing module item tray" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      expect(module_item_assign_to_card[0]).to be_displayed
      expect(module_item_assign_to_card[1]).to be_displayed

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "allows for item assignment for newly-created module item" do
      go_to_modules

      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      latest_module_item = ContentTag.last

      manage_module_item_button(latest_module_item).click
      click_manage_module_item_assign_to(latest_module_item)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      expect(module_item_assign_to_card[0]).to be_displayed
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed

      select_module_item_assignee(0, @student1.name)
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "can remove a student from a card with two students" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student2)

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      assign_to_in_tray("Remove #{@student2.name}")[0].click
      expect(element_exists?(assign_to_in_tray_selector("Remove #{@student2.name}"))).to be_falsey
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "deletes individual cards" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)
      @module_item1.assignment.assignment_overrides.second.assignment_override_students.create!(user: @student2)
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      expect(module_item_assign_to_card.count).to be(3)
      click_delete_assign_to_card(2)
      expect(module_item_assign_to_card.count).to be(2)
    end

    context "differentiation tags" do
      before :once do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: true }
          a.save!
        end

        @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
        @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
        @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)

        @diff_tag1.add_user(@student1)
        @diff_tag2.add_user(@student2)
      end

      it "can add differentiation tag to a card and persist the override" do
        go_to_modules
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        click_add_assign_to_card
        select_module_item_assignee(1, @diff_tag1.name)
        expect(module_item_assign_to_card.count).to be(2)

        click_save_button
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        expect(module_item_assign_to_card.count).to be(2)
        expect(assign_to_in_tray("Remove #{@diff_tag1.name}")[0]).to be_displayed
      end

      it "Displays inherrited differentiation tags from module" do
        # Create a module override for differentiation tag
        go_to_modules
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio
        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, @diff_tag1.name.to_s)
        click_settings_tray_update_module_button

        # Open the item assign to tray
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        expect(module_item_assign_to_card.count).to be(1)
        expect(assign_to_in_tray("Remove #{@diff_tag1.name}")[0]).to be_displayed
        expect(f('[data-testid="context-module-text"]').text).to eq("Inherited from Module 1")
      end

      it "can override an inherited module override for differentiation tags" do
        go_to_modules

        # Add diff tag module override
        @module = ContextModule.find(@module_item1.context_module_id)
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio
        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")
        click_settings_tray_update_module_button

        # Open item from module
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        expect(f('[data-testid="context-module-text"]').text).to eq("Inherited from Module 1")
        expect(assign_to_due_date(0).attribute("value")).to eq("")
        expect(assign_to_due_time(0).attribute("value")).to eq("")

        # Select a due date for the inherited override
        update_due_date(0, "12/31/2022")
        update_due_time(0, "11:59 PM")
        click_save_button

        # Open item from module again and see that it is no longer inherited
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        expect(module_item_assign_to_card.count).to be(1)
        expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
        expect(assign_to_due_time(0).attribute("value")).to eq("11:59 PM")
      end

      context "differentiation tag rollback" do
        before do
          # Enable Checkpoints for these tests
          @course.account.enable_feature!(:discussion_checkpoints)
          @course.account.save!

          @diff_tag_module = @course.context_modules.create!(name: "Diff Tag Rollback", workflow_state: "active")
          @diff_tag_assignment = @course.assignments.create!(title: "Assignment")
          @diff_tag_quiz = @course.quizzes.create!(title: "Quiz").publish!
          @diff_tag_discussion = @course.discussion_topics.create!(title: "Discussion")
          @diff_tag_graded_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "Graded Discussion")
          @diff_tag_wiki = @course.wiki_pages.create!(title: "Wiki Page", body: "Wiki Body")

          # Checkpointed discussion
          @diff_tag_checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "Checkpointed Discussion")
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @diff_tag_checkpointed_discussion,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: {},
            points_possible: 10
          )
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @diff_tag_checkpointed_discussion,
            checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
            dates: {},
            points_possible: 10
          )

          # Add everything to module
          @diff_tag_module.add_item type: "assignment", id: @diff_tag_assignment.id
          @diff_tag_module.add_item type: "quiz", id: @diff_tag_quiz.id
          @diff_tag_module.add_item type: "discussion_topic", id: @diff_tag_discussion.id
          @diff_tag_module.add_item type: "discussion_topic", id: @diff_tag_graded_discussion.id
          @diff_tag_module.add_item type: "discussion_topic", id: @diff_tag_checkpointed_discussion.id
          @diff_tag_module.add_item type: "wiki_page", id: @diff_tag_wiki.id
        end

        shared_examples_for "Convertable in Assign To Tray" do
          def update_date_for_card(date, time, card_index, date_label)
            if date_label == :due_at
              update_due_date(card_index, date)
              update_due_time(card_index, time)
            elsif date_label == :unlock_at
              update_available_date(card_index, date, true)
              update_available_time(card_index, time, true)
            end

            click_save_button
          end

          it "displays error message if differentiation tags exist after account setting is turned off" do
            go_to_modules

            # Add diff tag override to module item
            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            click_add_assign_to_card
            select_module_item_assignee(1, @diff_tag1.name)
            update_date_for_card("12/31/2022", "11:59 PM", 1, date_label)

            # Disable differentiation tags in account settings
            @course.account.tap do |a|
              a.settings[:allow_assign_to_differentiation_tags] = { value: false }
              a.save!
            end

            # Refresh the page
            go_to_modules

            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            # Check that warning box with 'convert tags' button is displayed
            expect(f("[data-testid='convert-differentiation-tags-button']")).to be_displayed
          end

          it "removes error message when user manually removes all differentiation tag overrides and can save" do
            go_to_modules

            # Add diff tag override to module item
            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            click_add_assign_to_card
            select_module_item_assignee(1, @diff_tag1.name)
            update_date_for_card("12/31/2022", "11:59 PM", 1, date_label)

            # Disable differentiation tags in account settings
            @course.account.tap do |a|
              a.settings[:allow_assign_to_differentiation_tags] = { value: false }
              a.save!
            end

            # Refresh the page
            go_to_modules

            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            expect(f("[data-testid='convert-differentiation-tags-button']")).to be_displayed

            # Manually remove the differentiation tag override
            click_delete_assign_to_card(1)

            # Check that warning box is no longer displayed
            expect(element_exists?("[data-testid='convert-differentiation-tags-button']")).to be_falsey

            click_save_button
          end

          it "converts differentiation tags to adhoc student overrides when 'Convert Tags' button is clicked" do
            go_to_modules

            # Add diff tag override to module item
            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            click_add_assign_to_card
            select_module_item_assignee(1, @diff_tag1.name)
            update_date_for_card("12/31/2022", "11:59 PM", 1, date_label)

            # Disable differentiation tags in account settings
            @course.account.tap do |a|
              a.settings[:allow_assign_to_differentiation_tags] = { value: false }
              a.save!
            end

            # Refresh the page
            go_to_modules

            manage_module_item_button(module_item).click
            click_manage_module_item_assign_to(module_item)

            convert_tags_button = f("[data-testid='convert-differentiation-tags-button']")
            convert_tags_button.click

            # Check that the warning box is no longer displayed
            expect(element_exists?("[data-testid='convert-differentiation-tags-button']")).to be_falsey

            # Check that the differentiation tag is now an adhoc override
            expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
          end
        end

        context "Assignment" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "Assignment", content_id: @diff_tag_assignment.id) }
            let(:date_label) { :due_at }
          end
        end

        context "Quiz" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "Quizzes::Quiz", content_id: @diff_tag_quiz.id) }
            let(:date_label) { :due_at }
          end
        end

        context "Discussion" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "DiscussionTopic", content_id: @diff_tag_discussion.id) }
            let(:date_label) { :unlock_at }
          end
        end

        context "Graded Discussion" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "DiscussionTopic", content_id: @diff_tag_graded_discussion.id) }
            let(:date_label) { :due_at }
          end
        end

        context "Checkpointed Discussion" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "DiscussionTopic", content_id: @diff_tag_checkpointed_discussion.id) }
            let(:date_label) { :unlock_at }
          end
        end

        context "Wiki Page" do
          it_behaves_like "Convertable in Assign To Tray" do
            let(:module_item) { ContentTag.find_by(context_id: @course.id, context_module_id: @diff_tag_module.id, content_type: "WikiPage", content_id: @diff_tag_wiki.id) }
            let(:date_label) { :unlock_at }
          end
        end
      end
    end

    context "due date validations" do
      it "can fill out due dates and times on card" do
        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_due_date(0, "12/31/2022")
        update_due_time(0, "5:00 PM")
        update_available_date(0, "12/27/2022")
        update_available_time(0, "8:00 AM")
        update_until_date(0, "1/7/2023")
        update_until_time(0, "9:00 PM")

        expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
        expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
        expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
        expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
        expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
        expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
      end

      it "does not display an error when user uses other English locale" do
        @user.update! locale: "en-GB"

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_due_date(0, "15 April 2024")
        # Blurs the due date input
        assign_to_due_time(0).click

        expect(assign_to_date_and_time[0].text).not_to include("Invalid date")
      end

      it "does not display an error when user uses other language" do
        @user.update! locale: "es"

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_due_date(0, "15 de abr. de 2024")
        # Blurs the due date input
        assign_to_due_time(0).click

        expect(assign_to_date_and_time[0].text).not_to include("Fecha no válida")
      end

      it "displays an error when due date is invalid" do
        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_due_date(0, "wrongdate")
        # Blurs the due date input
        assign_to_due_time(0).click

        expect(assign_to_date_and_time[0].text).to include("Invalid date")
      end

      it "displays an error when the availability date is after the due date" do
        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_due_date(0, "12/31/2022")
        update_available_date(0, "1/1/2023")

        expect(assign_to_date_and_time[1].text).to include("Unlock date cannot be after due date")
      end

      it "displays due date errors before term start date" do
        start_at = 2.months.from_now.to_date
        @term = Account.default.enrollment_terms.create(name: "Fall", start_at:)
        @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        long_due_date = 1.month.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[0].text).to include("Due date cannot be before term start")
      end

      it "displays due date errors past term end date" do
        end_at = 1.month.from_now.to_date
        @term = Account.default.enrollment_terms.create(name: "Fall", end_at:)
        @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        long_due_date = 2.months.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).to include("Due date cannot be after term end")
      end

      it "displays availability errors before term start date" do
        start_at = 2.months.from_now.to_date
        @term = Account.default.enrollment_terms.create(name: "Fall", start_at:)
        @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        available_date = 1.month.from_now.to_date
        update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[1].text).to include("Unlock date cannot be before term start")
      end

      it "displays lock date errors past term end date" do
        end_at = 1.month.from_now.to_date
        @term = Account.default.enrollment_terms.create(name: "Fall", end_at:)
        @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        available_date = 2.months.from_now.to_date

        update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[2].text).to include("Lock date cannot be after term end")
      end

      it "displays due date errors before course start date" do
        @course.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        long_due_date = 1.month.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).to include("Due date cannot be before course start")
      end

      it "displays due date errors past course end date" do
        @course.update!(conclude_at: 1.month.from_now.to_date, restrict_enrollments_to_course_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        long_due_date = 2.months.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).to include("Due date cannot be after course end")
      end

      it "displays available from date errors before course start date" do
        @course.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        available_date = 1.month.from_now.to_date
        update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[1].text).to include("Unlock date cannot be before course start")
      end

      it "displays lock date errors past course end date" do
        @course.update!(conclude_at: 1.month.from_now.to_date, restrict_enrollments_to_course_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        available_date = 2.months.from_now.to_date

        update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[2].text).to include("Lock date cannot be after course end")
      end

      it "displays due date errors before section start date" do
        @section1.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        select_module_item_assignee(0, @section1.name)

        long_due_date = 1.month.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).to include("Due date cannot be before section start")
      end

      it "displays due date errors past section end date" do
        @section1.update!(end_at: 1.month.from_now.to_date, restrict_enrollments_to_section_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }
        select_module_item_assignee(0, @section1.name)

        long_due_date = 2.months.from_now.to_date

        update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).to include("Due date cannot be after section end")
      end

      it "displays available from errors before section start date" do
        @section1.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        select_module_item_assignee(0, @section1.name)

        available_date = 1.month.from_now.to_date
        update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[1].text).to include("Unlock date cannot be before section start")
      end

      it "displays lock date errors past section end date" do
        @section1.update!(end_at: 1.month.from_now.to_date, restrict_enrollments_to_section_dates: true)

        go_to_modules

        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }
        select_module_item_assignee(0, @section1.name)

        available_date = 2.months.from_now.to_date

        update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
        expect(assign_to_date_and_time[2].text).to include("Lock date cannot be after section end")
      end

      it "allows section due date that is outside of course date range" do
        @course.update!(start_at: 1.month.from_now.to_date, conclude_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)
        @section1.update!(start_at: 2.months.from_now.to_date, end_at: 4.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

        go_to_modules
        manage_module_item_button(@module_item1).click
        click_manage_module_item_assign_to(@module_item1)
        keep_trying_until { expect(item_tray_exists?).to be_truthy }
        select_module_item_assignee(0, @section1.name)

        section_due_date = 3.months.from_now.to_date
        update_due_date(0, format_date_for_view(section_due_date, "%-m/%-d/%Y"))

        expect(assign_to_date_and_time[0].text).not_to include("Due date cannot be before course start")
      end
    end
  end

  context "assign to tray focus validation" do
    before(:once) do
      module_setup
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module_item2 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment2.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it "focus assignees field if there is no selection after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      assign_to_in_tray("Remove Everyone")[0].click
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "12/27/2022")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/7/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: A student or section must be selected
      check_element_has_focus module_item_assignee[0]
    end

    it "focus date field if is invalid after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "1/1/2023")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/2/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: Unlock date cannot be after due date
      check_element_has_focus assign_to_available_from_date(0)
    end

    it "focus date field if is un-parseable after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "wrongdate")
      update_available_date(0, "1/1/2023")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/2/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: Invalid date
      check_element_has_focus assign_to_due_date(0)
    end

    it "focuses on on trash can button on newly created card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      click_add_assign_to_card

      check_element_has_focus delete_card_button[1]
    end

    it "focuses on previous card trashcan when middle first card is deleted" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      click_add_assign_to_card
      select_module_item_assignee(1, @student1.name)
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed

      click_add_assign_to_card

      click_delete_assign_to_card(1)
      check_element_has_focus delete_card_button[0]
      # expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    end

    it "focuses Add Card button when only one card remains after delete" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      click_add_assign_to_card

      click_delete_assign_to_card(1)
      check_element_has_focus add_assign_to_card[0]
      # expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
      expect(element_exists?(delete_card_button_selector)).to be_falsey
    end

    it "focuses Add Card button when first card is deleted and replaced with next" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      click_add_assign_to_card
      select_module_item_assignee(1, @student1.name)
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed

      click_delete_assign_to_card(0)
      check_element_has_focus add_assign_to_card[0]
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
      expect(element_exists?(delete_card_button_selector)).to be_falsey
    end
  end

  context "item assign to tray saves", :ignore_js_errors do
    before(:once) do
      @course.enable_feature! :quizzes_next
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!

      module_setup
      @course.update!(default_view: "modules")
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module item assign to tray", :context_modules
    it_behaves_like "module item assign to tray", :course_homepage
  end

  context "item assign to tray saves for canvas for elementary", :ignore_js_errors do
    before(:once) do
      teacher_setup
      @subject_course.enable_feature! :quizzes_next
      @subject_course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @subject_course.root_account.settings[:provision] = { "lti" => "lti url" }
      @subject_course.root_account.save!

      module_setup(@subject_course)
      @module_item1 = ContentTag.find_by(context_id: @subject_course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @subject_course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @subject_course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module item assign to tray", :canvas_for_elementary
  end

  context "permissions" do
    before(:once) do
      module_setup
    end

    before do
      user_session(@teacher)
    end

    def assert_permission_toggles_item_visibility(item, permission)
      go_to_modules
      manage_module_item_button(item).click
      expect(module_item(item.id)).to include_text("Assign To...")

      RoleOverride.create!(context: @course.account, permission:, role: teacher_role, enabled: false)
      go_to_modules
      manage_module_item_button(item).click
      expect(module_item(item.id)).not_to include_text("Assign To...")
    end

    it "shows assign to option for assignment module items based off manage_assignments_edit permission" do
      item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      assert_permission_toggles_item_visibility(item, "manage_assignments_edit")
    end

    it "shows assign to option for quiz module items based off manage_assignments_edit permission" do
      item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Quizzes::Quiz", content_id: @quiz.id)
      assert_permission_toggles_item_visibility(item, "manage_assignments_edit")
    end

    it "shows assign to option for page module items based off manage_wiki_update permission" do
      item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "WikiPage", content_id: @wiki.id)
      assert_permission_toggles_item_visibility(item, "manage_wiki_update")
    end

    it "shows assign to option for graded discussion module items based off moderate_forum permission" do
      item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "DiscussionTopic", content_id: @discussion.id)
      assert_permission_toggles_item_visibility(item, "moderate_forum")
    end
  end
end
