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

require_relative "../common"
require_relative "../helpers/outcome_common"
require_relative "pages/improved_outcome_management_page"
require "feature_flag_helper"

describe "outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon
  include ImprovedOutcomeManagementPage
  include FeatureFlagHelper

  let(:account) { Account.create(name: "sub account from default account", parent_account: Account.default) }
  let(:outcome_url) { "/accounts/#{account.id}/outcomes" }
  let(:who_to_login) { "admin" }

  describe "sub-account outcomes" do
    before do
      course_with_admin_logged_in
    end

    describe "with improved_outcome_management disabled" do
      before do
        mock_feature_flag_on_account(:improved_outcomes_management, false)
      end

      context "create/edit/delete outcomes" do
        it "creates a learning outcome with a new rating (root level)", priority: "2" do
          should_create_a_learning_outcome_with_a_new_rating_root_level
        end

        it "creates a learning outcome (nested)", priority: "2" do
          should_create_a_learning_outcome_nested
        end

        it "edits a learning outcome and delete a rating", priority: "2" do
          should_edit_a_learning_outcome_and_delete_a_rating
        end

        it "deletes a learning outcome", priority: "2" do
          skip_if_safari(:alert)
          should_delete_a_learning_outcome
        end

        it "validates decaying average_range", priority: "2" do
          should_validate_decaying_average_range "not a valid value for this calculation method"
        end

        it "validates n mastery_range", priority: "2" do
          should_validate_n_mastery_range
        end
      end

      context "create/edit/delete outcome groups" do
        it "creates an outcome group (root level)", priority: "1" do
          should_create_an_outcome_group_root_level
        end

        it "creates an outcome group (nested)", priority: "1" do
          should_create_an_outcome_group_nested
        end

        it "edits an outcome group", priority: "1" do
          should_edit_an_outcome_group
        end

        it "deletes an outcome group", priority: "1" do
          skip_if_safari(:alert)
          should_delete_an_outcome_group
        end
      end

      describe "find/import dialog" do
        it "does not allow importing top level groups", priority: "1" do
          get outcome_url
          wait_for_ajaximations
          f(".find_outcome").click
          wait_for_ajaximations
          groups = ff(".outcome-group")
          expect(groups.size).to eq 2
          groups.each do |g|
            g.click
            expect(f(".ui-dialog-buttonpane .btn-primary")).not_to be_displayed
          end
        end
      end
    end

    describe "with improved_outcome_management enabled" do
      before do
        mock_feature_flag_on_account(:improved_outcomes_management, true)
      end

      it "creates an initial outcome in the sub-account level as an admin" do
        get outcome_url
        create_outcome("Test Outcome")
        run_jobs
        get outcome_url
        expect(tree_browser_outcome_groups.count).to eq(2)
        group_text = tree_browser_outcome_groups[0].text.split("\n")[0]
        expect(group_text).to eq("sub account from default account")
        add_new_group_text = tree_browser_outcome_groups[1].text
        expect(add_new_group_text).to eq("Create New Group")
        expect(LearningOutcome.find_by(context_id: account.id).short_description).to eq("Test Outcome")
      end

      it "edits an existing outcome in the course level as an admin" do
        create_bulk_outcomes_groups(account, 1, 1)
        get outcome_url
        select_outcome_group_with_text(account.name).click
        expect(nth_individual_outcome_title(0)).to eq("outcome 0")
        individual_outcome_kabob_menu(0).click
        edit_outcome_button.click
        edit_outcome_title("Edited Title")
        click_save_edit_modal
        expect(nth_individual_outcome_title(0)).to eq("Edited Title")
      end

      it "removes a single outcome in the course level as an admin" do
        create_bulk_outcomes_groups(account, 1, 1)
        get outcome_url
        select_outcome_group_with_text(account.name).click
        expect(nth_individual_outcome_title(0)).to eq("outcome 0")
        individual_outcome_kabob_menu(0).click
        click_remove_outcome_button
        click_confirm_remove_button
        expect(no_outcomes_billboard.present?).to be(true)
      end

      it "moves an outcome into a newly created outcome group as an admin" do
        create_bulk_outcomes_groups(account, 1, 1)
        get outcome_url
        select_outcome_group_with_text(account.name).click
        individual_outcome_kabob_menu(0).click
        click_move_outcome_button
        click_create_new_group_in_move_modal_button
        insert_new_group_name_in_move_modal("New group")
        click_confirm_new_group_in_move_modal_button
        tree_browser_root_group.click
        select_drilldown_outcome_group_with_text("New group").click
        force_click(confirm_move_button)
        # Verify through AR to save time
        keep_trying_until do
          new_group_children = LearningOutcomeGroup.find_by(title: "New group").child_outcome_links
          expect(new_group_children.count).to eq(1)
          expect(new_group_children.first.title).to eq("outcome 0")
        end
      end

      it "bulk removes outcomes at the course level as an admin" do
        create_bulk_outcomes_groups(account, 1, 5)
        get outcome_url
        select_outcome_group_with_text(account.name).click
        force_click(select_nth_outcome_for_bulk_action(0))
        force_click(select_nth_outcome_for_bulk_action(1))
        force_click(select_nth_outcome_for_bulk_action(2))
        force_click(select_nth_outcome_for_bulk_action(3))
        click_remove_button
        click_confirm_remove_button
        expect(nth_individual_outcome_title(0)).to eq("outcome 4")
      end

      # Can't reproduce the js error locally
      it "bulk moves outcomes at the course level as an admin", :ignore_js_errors do
        create_bulk_outcomes_groups(account, 1, 3)
        get outcome_url
        select_outcome_group_with_text(account.name).click
        force_click(select_nth_outcome_for_bulk_action(0))
        force_click(select_nth_outcome_for_bulk_action(1))
        click_move_button
        click_create_new_group_in_move_modal_button
        insert_new_group_name_in_move_modal("New group")
        click_confirm_new_group_in_move_modal_button
        select_drilldown_outcome_group_with_text("New group").click
        force_click(confirm_move_button)
        # Verify through AR to save time
        new_group_children = LearningOutcomeGroup.find_by(title: "New group").child_outcome_links
        expect(new_group_children.count).to eq(2)
        expect(new_group_children.pluck(:title).sort).to eq(["outcome 0", "outcome 1"])
      end

      describe "with account_level_mastery_scales disabled" do
        it "creates an outcome with a friendly description present" do
          get outcome_url
          create_outcome_with_friendly_desc("Outcome", "Standard Desc", "Friendly Desc")
          # Have to verify model creation with AR to save time since the creation => appearance flow is a little slow
          # Small delay between button click and model population in db
          keep_trying_until do
            outcome = LearningOutcome.find_by(context: account, short_description: "Outcome", description: "<p>Standard Desc</p>")
            fd = OutcomeFriendlyDescription.find_by(context: account, learning_outcome: outcome, description: "Friendly Desc")
            expect(fd).to be_truthy
          end
        end

        it "edits an outcome's friendly description" do
          create_bulk_outcomes_groups(account, 1, 1)
          outcome_title = "outcome 0"
          outcome = LearningOutcome.find_by(context: account, short_description: outcome_title)
          outcome.update!(description: "long description")
          OutcomeFriendlyDescription.find_or_create_by!(learning_outcome_id: outcome, context: account, description: "FD")
          get outcome_url
          select_outcome_group_with_text(account.name).click
          expect(nth_individual_outcome_title(0)).to eq(outcome_title)
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          insert_friendly_description("FD - Edited")
          click_save_edit_modal
          expect(nth_individual_outcome_title(0)).to eq(outcome_title)
          expect(nth_individual_outcome_text(0)).not_to match(/Friendly Description.*FD/m)
          expand_outcome_description_button(0).click
          expect(nth_individual_outcome_text(0)).to match(/Friendly Description.*FD - Edited/m)
        end

        it "creates an outcome with default ratings and calculation method" do
          get outcome_url
          create_outcome("Outcome with Individual Ratings")
          # Verify through AR to save time
          keep_trying_until do
            outcome = LearningOutcome.find_by(context: account, short_description: "Outcome with Individual Ratings")
            ratings = outcome.data[:rubric_criterion][:ratings]
            mastery_points = outcome.data[:rubric_criterion][:mastery_points]
            points_possible = outcome.data[:rubric_criterion][:points_possible]
            expect(outcome.nil?).to be(false)
            expect(ratings.length).to eq(5)
            expect(ratings[0][:description]).to eq("Exceeds Mastery")
            expect(ratings[0][:points]).to eq(4)
            expect(ratings[1][:description]).to eq("Mastery")
            expect(ratings[1][:points]).to eq(3)
            expect(ratings[2][:description]).to eq("Near Mastery")
            expect(ratings[2][:points]).to eq(2)
            expect(ratings[3][:description]).to eq("Below Mastery")
            expect(ratings[3][:points]).to eq(1)
            expect(ratings[4][:description]).to eq("No Evidence")
            expect(ratings[4][:points]).to eq(0)
            expect(mastery_points).to eq(3)
            expect(points_possible).to eq(4)
            expect(outcome.calculation_method).to eq("decaying_average")
            expect(outcome.calculation_int).to eq(65)
          end
        end

        it "edits an outcome and changes calculation method" do
          create_bulk_outcomes_groups(account, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(account.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # change calculation method
          edit_individual_outcome_calculation_method("n Number of Times")
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: account, short_description: "outcome 0")
          expect(outcome.calculation_method).to eq("n_mastery")
        end

        it "edits an outcome and changes calculation int" do
          create_bulk_outcomes_groups(account, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(account.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # change calculation int
          edit_individual_outcome_calculation_int(55)
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: account, short_description: "outcome 0")
          expect(outcome.calculation_int).to eq(55)
        end

        it "edits an outcome and adds individual rating" do
          create_bulk_outcomes_groups(account, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(account.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # add new rating
          add_individual_outcome_rating("new", 5)
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: account, short_description: "outcome 0")
          ratings = outcome.data[:rubric_criterion][:ratings]
          expect(ratings.length).to eq(3)
          expect(ratings[0][:description]).to eq("new")
          expect(ratings[0][:points]).to eq(5)
        end

        it "edits an outcome and deletes individual rating" do
          create_bulk_outcomes_groups(account, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(account.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # delete last rating
          delete_nth_individual_outcome_rating
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: account, short_description: "outcome 0")
          ratings = outcome.data[:rubric_criterion][:ratings]
          expect(ratings.length).to eq(1)
        end

        context "alignment summary tab" do
          before do
            context_outcome(account, 3)
            @assignment = assignment_model(course: @course)
            @aligned_outcome = LearningOutcome.find_by(context: account, short_description: "outcome 0")
            @aligned_outcome.align(@assignment, account)
          end

          it "there is no alignments tab" do
            get outcome_url
            tabs = ff("*[role='tablist'] *[role='tab']")
            expect(tabs.count).to eq 1
          end
        end
      end
    end
  end
end
