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

require_relative "../helpers/context_modules_common"
require_relative "../helpers/public_courses_context"
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"
require_relative "../helpers/items_assign_to_tray"
require_relative "shared_examples/context_modules_teacher_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)
      # have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(title: "quiz assignment", submission_types: "online_quiz")
      @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
      @assignment2 = @course.assignments.create!(title: "assignment 2",
                                                 submission_types: "online_text_entry",
                                                 due_at: 2.days.from_now,
                                                 points_possible: 10)
      @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")

      @ag1 = @course.assignment_groups.create!(name: "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(name: "Assignment Group 2")
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "context modules for teachers"

    context "with modules page rewrite feature flag enabled" do
      before do
        @course.root_account.enable_feature!(:modules_page_rewrite)
        module_1 = @course.context_modules.create!(name: "Module 1")
        assignment_1 = @course.assignments.create!(name: "Assignment 1")
        module_1.add_item({ id: assignment_1.id, type: "assignment" })
      end

      it "page renders", :ignore_js_errors do
        get "/courses/#{@course.id}/modules"
        expect(f("[data-testid='modules-rewrite-container']")).to be_present
      end
    end

    context "expanding/collapsing modules" do
      before do
        @mod = create_modules(2, true)
        @mod[0].add_item({ id: @assignment.id, type: "assignment" })
        @mod[1].add_item({ id: @assignment2.id, type: "assignment" })
        get "/courses/#{@course.id}/modules"
      end

      def assert_collapsed
        expect(expand_module_link(@mod[0].id)).to be_displayed
        expect(module_content(@mod[0].id)).not_to be_displayed
        expect(expand_module_link(@mod[1].id)).to be_displayed
        expect(module_content(@mod[1].id)).not_to be_displayed
      end

      def assert_expanded
        expect(f("#context_module_#{@mod[0].id} span.collapse_module_link")).to be_displayed
        expect(f("#context_module_#{@mod[0].id} .content")).to be_displayed
        expect(f("#context_module_#{@mod[1].id} span.collapse_module_link")).to be_displayed
        expect(f("#context_module_#{@mod[1].id} .content")).to be_displayed
      end

      it "displays collapse all button at top of page" do
        button = f("button#expand_collapse_all")
        expect(button).to be_displayed
        expect(button.attribute("data-expand")).to eq("false")
      end

      it "collapses and expand all modules when clicked and persist after refresh" do
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_collapsed
        expect(button.text).to eq("Expand All")
        refresh_page
        assert_collapsed
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_expanded
        expect(button.text).to eq("Collapse All")
        refresh_page
        assert_expanded
      end

      it "collapses all after collapsing individually" do
        f("#context_module_#{@mod[0].id} span.collapse_module_link").click
        wait_for_ajaximations
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_collapsed
        expect(button.text).to eq("Expand All")
      end
    end

    context "moving newly added module items" do
      before do
        @course.root_account.disable_feature!(:modules_page_rewrite)
        @module1 = @course.context_modules.create!(name: "Module 1")
        @module2 = @course.context_modules.create!(name: "Module 2")
        get "/courses/#{@course.id}/modules"
      end

      it "allows moving a newly added module item without page refresh" do
        add_new_module_item(@module1, "assignment", @assignment.title)
        wait_for_ajaximations

        new_item = @module1.content_tags.last
        manage_module_item_button(new_item).click
        click_module_item_move(new_item)

        expect(module_item_move_tray).to be_displayed
      end
    end

    context "peer review info display" do
      before(:once) do
        @course.root_account.disable_feature!(:modules_page_rewrite)
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @module = @course.context_modules.create!(name: "Test Module")
        @assignment = @course.assignments.create!(
          title: "Peer Review Assignment",
          submission_types: "online_text_entry",
          due_at: 2.days.from_now,
          points_possible: 100,
          peer_reviews: true,
          peer_review_count: 2,
          automatic_peer_reviews: false
        )
        @pr_subassignment = PeerReview::PeerReviewCreatorService.call(
          parent_assignment: @assignment,
          points_possible: 10,
          due_at: 9.days.from_now
        )
        @module.add_item({ id: @assignment.id, type: "assignment" })

        @new_peer_review_assignment = @course.assignments.create!(
          title: "New Peer Review Assignment",
          submission_types: "online_text_entry",
          due_at: 3.days.from_now,
          points_possible: 50,
          peer_reviews: true,
          peer_review_count: 3,
          automatic_peer_reviews: false
        )
        @new_pr_subassignment = PeerReview::PeerReviewCreatorService.call(
          parent_assignment: @new_peer_review_assignment,
          points_possible: 15,
          due_at: 10.days.from_now
        )
      end

      before do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations
      end

      it "displays peer review info for assignments with peer reviews" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item).to include_text("Assignment:")
        expect(module_item).to include_text("Peer Reviews (2):")
      end

      it "shows assignment and peer review due dates" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        assignment_due = format_date_for_view(@assignment.due_at, :short)
        peer_review_due = format_date_for_view(@pr_subassignment.due_at, :short)
        expect(module_item).to include_text(assignment_due)
        expect(module_item).to include_text(peer_review_due)
      end

      it "does not show availability dates" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item.text).not_to include("Available")
        expect(module_item.text).not_to include("Closed")
      end

      it "shows points possible" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item).to include_text("100 pts")
        expect(module_item).to include_text("10 pts")
      end

      it "displays peer review info when adding assignment to module" do
        f("#context_module_#{@module.id} .ig-header-admin .al-trigger").click
        f("#context_module_#{@module.id} .add_module_item_link").click
        wait_for_ajaximations
        select_module_item("#add_module_item_select", "Assignment")
        wait_for_ajaximations
        select_module_item("#assignments_select .module_item_select", @new_peer_review_assignment.title)
        fj(".add_item_button:visible").click
        wait_for_ajaximations

        new_module_item = ffj(".context_module_item:visible").last
        expect(new_module_item).to include_text("Assignment:")
        expect(new_module_item).to include_text("Peer Reviews (3):")
        expect(new_module_item).to include_text("50 pts")
        expect(new_module_item).to include_text("15 pts")
      end

      it "displays regular due date and points for non-peer-review assignments" do
        regular_assignment = @course.assignments.create!(
          title: "Regular Assignment",
          submission_types: "online_text_entry",
          due_at: 5.days.from_now,
          points_possible: 25
        )
        @module.add_item({ id: regular_assignment.id, type: "assignment" })
        refresh_page
        wait_for_ajaximations

        module_item = f("#context_module_item_#{@module.content_tags.last.id}")
        expect(module_item).not_to include_text("Assignment:")
        expect(module_item).not_to include_text("Peer Reviews")
        expect(module_item).to include_text(format_date_for_view(regular_assignment.due_at, :short))
        expect(module_item).to include_text("25 pts")
      end
    end

    context "peer review info with multiple due dates" do
      before(:once) do
        @course.root_account.disable_feature!(:modules_page_rewrite)
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @module = @course.context_modules.create!(name: "Test Module")
        @section1 = @course.course_sections.create!(name: "Section 1")
        @section2 = @course.course_sections.create!(name: "Section 2")

        @multi_date_assignment = @course.assignments.create!(
          title: "Multi Date Assignment",
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 2,
          automatic_peer_reviews: false
        )

        @pr_subassignment = PeerReview::PeerReviewCreatorService.call(
          parent_assignment: @multi_date_assignment,
          points_possible: 10,
          due_at: 9.days.from_now
        )

        @multi_date_assignment.assignment_overrides.create!(
          set: @section1,
          due_at: 2.days.from_now
        )
        @multi_date_assignment.assignment_overrides.create!(
          set: @section2,
          due_at: 4.days.from_now
        )

        @module.add_item({ id: @multi_date_assignment.id, type: "assignment" })
      end

      before do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations
      end

      it "displays 'Multiple Due Dates' link for assignments with multiple dates" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item).to include_text("Multiple Due Dates")
      end

      it "does not display 'Multiple Dates' link" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item.text).not_to match(/Multiple Dates(?! Dates)/)
      end
    end

    context "assignments without peer reviews" do
      before(:once) do
        @course.root_account.disable_feature!(:modules_page_rewrite)
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @module = @course.context_modules.create!(name: "Test Module")
        @regular_assignment = @course.assignments.create!(
          title: "Regular Assignment",
          submission_types: "online_text_entry",
          due_at: 2.days.from_now,
          points_possible: 50
        )
        @module.add_item({ id: @regular_assignment.id, type: "assignment" })
      end

      before do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations
      end

      it "displays regular due date and points without peer review info" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item.text).not_to include("Peer Review")
        expect(module_item.text).not_to include("Assignment:")
      end
    end

    context "peer review info with feature flag disabled" do
      before(:once) do
        @course.root_account.disable_feature!(:modules_page_rewrite)
        @course.disable_feature!(:peer_review_allocation_and_grading)
        @module = @course.context_modules.create!(name: "Test Module")
        @peer_review_assignment = @course.assignments.create!(
          title: "Peer Review Assignment",
          submission_types: "online_text_entry",
          due_at: 2.days.from_now,
          points_possible: 100,
          peer_reviews: true,
          peer_review_count: 2,
          automatic_peer_reviews: false
        )
        @module.add_item({ id: @peer_review_assignment.id, type: "assignment" })
      end

      before do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations
      end

      it "does not display peer review info component" do
        module_item = f("#context_module_item_#{@module.content_tags.first.id}")
        expect(module_item.text).not_to include("Assignment:")
        expect(module_item.text).not_to include("Peer Reviews (2):")
      end

      it "displays regular due date and points displays" do
        f("#context_module_item_#{@module.content_tags.first.id}")
        expect(f("#context_module_item_#{@module.content_tags.first.id} .due_date_display")).to be_displayed
        expect(f("#context_module_item_#{@module.content_tags.first.id} .points_possible_display")).to be_displayed
      end
    end
  end
end
