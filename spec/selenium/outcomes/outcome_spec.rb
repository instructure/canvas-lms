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

require_relative "../helpers/outcome_common"
require_relative "pages/improved_outcome_management_page"

describe "outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon
  include ImprovedOutcomeManagementPage

  let(:who_to_login) { "teacher" }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  describe "course outcomes" do
    before do
      course_with_teacher_logged_in
    end

    def save_without_error(value = 4, title = "New Outcome")
      replace_content(f(".outcomes-content input[name=title]"), title)
      replace_content(f("input[name=calculation_int]"), value)
      f(".submit_button").click
      wait_for_ajaximations
      expect(f(".title").text).to include(title)
      expect(f("#calculation_int").text.to_i).to eq(value)
    end

    context "create/edit/delete outcomes" do
      it "creates a learning outcome with a new rating (root level)", priority: "1" do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "creates a learning outcome (nested)", priority: "1" do
        should_create_a_learning_outcome_nested
      end

      it "edits a learning outcome and delete a rating", priority: "1" do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "deletes a learning outcome", priority: "1" do
        skip_if_safari(:alert)
        should_delete_a_learning_outcome
      end

      context "validate decaying average" do
        before do
          get outcome_url
          f(".add_outcome_link").click
        end

        it "validates default values", priority: "1" do
          expect(f("#calculation_method")).to have_value("decaying_average")
          expect(f("#calculation_int")).to have_value("65")
          expect(f("#calculation_int_example")).to include_text("Most recent result counts as 65% " \
                                                                "of mastery weight, average of all other results count " \
                                                                "as 35% of weight. If there is only one result, the single score " \
                                                                "will be returned.")
        end

        it "validates decaying average_range", priority: "2" do
          should_validate_decaying_average_range
        end

        it "validates calculation int accepatble values", priority: "1" do
          save_without_error(1)
          f(".edit_button").click
          save_without_error(99)
        end

        it "retains the settings after saving", priority: "1" do
          save_without_error(rand(1..99), "Decaying Average")
          expect(f("#calculation_method").text).to include("Decaying Average")
        end
      end

      context "validate n mastery" do
        before do
          get outcome_url
          f(".add_outcome_link").click
        end

        it "validates default values", priority: "1" do
          click_option("#calculation_method", "n Number of Times")
          expect(f("#calculation_int")).to have_value("5")
          expect(f("#mastery_points")).to have_value("3")
          expect(f("#calculation_int_example")).to include_text("Must achieve mastery at least 5 times. " \
                                                                "Scores above mastery will be averaged " \
                                                                "to calculate final score")
        end

        it "validates n mastery_range", priority: "2" do
          should_validate_n_mastery_range
        end

        it "validates calculation int acceptable range values", priority: "1" do
          click_option("#calculation_method", "n Number of Times")
          save_without_error(2)
          f(".edit_button").click
          save_without_error(5)
        end

        it "retains the settings after saving", priority: "1" do
          click_option("#calculation_method", "n Number of Times")
          save_without_error(3, "n Number of Times")
          refresh_page
          fj(".outcomes-sidebar .outcome-level:first li").click
          expect(f("#calculation_int").text).to eq("3")
          expect(f("#calculation_method").text).to include("n Number of Times")
        end
      end

      context "create/edit/delete outcome groups" do
        it "creates an outcome group (root level)", priority: "2" do
          should_create_an_outcome_group_root_level
        end

        it "creates an outcome group (nested)", priority: "1" do
          should_create_an_outcome_group_nested
        end

        it "edits an outcome group", priority: "2" do
          should_edit_an_outcome_group
        end

        it "deletes an outcome group", priority: "2" do
          skip_if_safari(:alert)
          should_delete_an_outcome_group
        end

        it "drags and drop an outcome to an outcome group", priority: "2" do
          group = @course.learning_outcome_groups.create!(title: "groupage")
          group2 = @course.learning_outcome_groups.create!(title: "groupage2")
          group.adopt_outcome_group(group2)
          group2.add_outcome @course.created_learning_outcomes.create!(title: "o1")
          get "/courses/#{@course.id}/outcomes"
          f(".ellipsis[title='groupage2']").click
          wait_for_ajaximations

          # make sure the outcome group 'groupage2' and outcome 'o1' are on different frames
          expect(ffj(".outcome-level:first .outcome-group .ellipsis")[0]).to have_attribute("title", "groupage2")
          expect(ffj(".outcome-level:last .outcome-link .ellipsis")[0]).to have_attribute("title", "o1")
          drag_and_drop_element(ffj(".outcome-level:last .outcome-link .ellipsis")[0], ffj(" .outcome-level")[0])
          wait_for_ajaximations

          # after the drag and drop, the outcome and the group are on a same screen
          expect(ffj(".outcome-level:last .outcome-group .ellipsis")[0]).to have_attribute("title", "groupage2")
          expect(ffj(".outcome-level:last .outcome-link .ellipsis")[0]).to have_attribute("title", "o1")

          # assert there is only one frame now after the drag and drop
          expect(ffj(" .outcome-level:first")).to eq ffj(" .outcome-level:last")
        end
      end
    end

    context "actions" do
      it "does not render an HTML-escaped title in outcome directory while editing", priority: "2" do
        title = "escape & me <<->> if you dare"
        @context = (who_to_login == "teacher") ? @course : account
        outcome_model
        get outcome_url
        wait_for_ajaximations
        fj(".outcomes-sidebar .outcome-level:first li").click
        wait_for_ajaximations
        f(".edit_button").click

        # pass in the unescaped version of the title:
        replace_content f(".outcomes-content input[name=title]"), title
        f(".submit_button").click
        wait_for_ajaximations

        # the "readable" version should be rendered in directory browser
        li_el = fj(".outcomes-sidebar .outcome-level:first li:first")
        expect(li_el).to be_truthy # should be present
        expect(li_el.text).to eq title

        # the "readable" version should be rendered in the view:
        expect(f(".outcomes-content .title").text).to eq title

        # and the escaped version should be stored!
        # expect(LearningOutcome.where(short_description: escaped_title)).to be_exists
        # or not, looks like it isn't being escaped
        expect(LearningOutcome.where(short_description: title)).to be_exists
      end
    end

    context "#show" do
      it "shows rubrics as aligned items", priority: "2" do
        outcome_with_rubric

        get "/courses/#{@course.id}/outcomes/#{@outcome.id}"
        wait_for_ajaximations

        expect(f("#alignments").text).to match(/#{@rubric.title}/)
      end
    end

    describe "with improved_outcome_management enabled" do
      before do
        enable_improved_outcomes_management(Account.default)
        enable_account_level_mastery_scales(Account.default)
      end

      it "creates an initial outcome in the course level as a teacher" do
        get outcome_url
        create_outcome("Test Outcome")
        run_jobs
        get outcome_url
        # Initial Group is created as well as a Create New Group button
        expect(tree_browser_outcome_groups.count).to eq(2)
        group_text = tree_browser_outcome_groups[0].text.split("\n")[0]
        expect(group_text).to eq(@course.name)
        add_new_group_text = tree_browser_outcome_groups[1].text
        # Verify through AR to save time
        expect(add_new_group_text).to eq("Create New Group")
        expect(LearningOutcome.where(context_id: @course.id).count).to eq(1)
        expect(LearningOutcome.find_by(context_id: @course.id).short_description).to eq("Test Outcome")
      end

      it "edits an existing outcome in the course level as a teacher" do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        expect(nth_individual_outcome_title(0)).to eq("outcome 0")
        individual_outcome_kabob_menu(0).click
        edit_outcome_button.click
        edit_outcome_title("Edited Title")
        click_save_edit_modal
        expect(nth_individual_outcome_title(0)).to eq("Edited Title")
      end

      it "removes a single outcome in the course level as a teacher" do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        expect(nth_individual_outcome_title(0)).to eq("outcome 0")
        individual_outcome_kabob_menu(0).click
        click_remove_outcome_button
        click_confirm_remove_button
        expect(no_outcomes_billboard.present?).to be(true)
      end

      it "moves an outcome into a newly created outcome group as a teacher" do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        individual_outcome_kabob_menu(0).click
        click_move_outcome_button
        click_create_new_group_in_move_modal_button
        insert_new_group_name_in_move_modal("New group")
        click_confirm_new_group_in_move_modal_button
        tree_browser_root_group.click
        select_drilldown_outcome_group_with_text("New group").click
        force_click(confirm_move_button)
        # Verify through AR to save time
        new_group_children = LearningOutcomeGroup.find_by(title: "New group").child_outcome_links
        expect(new_group_children.count).to eq(1)
        expect(new_group_children.first.title).to eq("outcome 0")
      end

      it "bulk removes outcomes at the course level as a teacher" do
        create_bulk_outcomes_groups(@course, 1, 5)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        force_click(select_nth_outcome_for_bulk_action(0))
        force_click(select_nth_outcome_for_bulk_action(1))
        force_click(select_nth_outcome_for_bulk_action(2))
        force_click(select_nth_outcome_for_bulk_action(3))
        click_remove_button
        click_confirm_remove_button
        expect(nth_individual_outcome_title(0)).to eq("outcome 4")
      end

      # Can't reproduce the js error locally
      it "bulk moves outcomes at the course level as a teacher", :ignore_js_errors do
        create_bulk_outcomes_groups(@course, 1, 3)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
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

      it "imports account outcomes into a course via Find modal" do
        create_bulk_outcomes_groups(Account.default, 1, 10)
        get outcome_url
        open_find_modal
        select_outcome_group_with_text("Account Standards").click
        select_outcome_group_with_text("Default Account").click
        job_count = Delayed::Job.count
        outcome0_title = nth_find_outcome_modal_item_title(0)
        add_button_nth_find_outcome_modal_item(0).click
        click_done_find_modal

        # ImportOutcomes operations enqueue jobs that will need to be manually processed
        expect(Delayed::Job.count).to eq(job_count + 1)
        run_jobs

        # Verify by titles that the outcomes are imported into current root account
        course_outcomes = LearningOutcomeGroup.find_by(context_id: @course.id, context_type: "Course", title: "group 0").child_outcome_links
        # Since the outcomes existed already and are just imported into a new group, we're checking the new content tags
        expect(course_outcomes[0].title).to eq(outcome0_title)
      end

      describe "with account_level_mastery_scales disabled" do
        before do
          enable_improved_outcomes_management(Account.default)
          disable_account_level_mastery_scales(Account.default)
        end

        describe "with friendly_description enabled" do
          before do
            enable_friendly_description
          end

          it "creates an outcome with a friendly description present" do
            get outcome_url
            create_outcome_with_friendly_desc("Outcome", "Standard Desc", "Friendly Desc")
            # Have to verify model creation with AR to save time since the creation => appearance flow is a little slow
            outcome = LearningOutcome.find_by(context: @course, short_description: "Outcome", description: "<p>Standard Desc</p>")
            # Small delay between button click and model population in db
            keep_trying_until do
              fd = OutcomeFriendlyDescription.find_by(context: @course, learning_outcome: outcome, description: "Friendly Desc")
              expect(fd).to be_truthy
            end
          end

          it "edits an outcome's friendly description" do
            # disable_account_level_mastery_scales(Account.default)
            create_bulk_outcomes_groups(@course, 1, 1)
            outcome_title = "outcome 0"
            outcome = LearningOutcome.find_by(context: @course, short_description: outcome_title)
            outcome.update!(description: "long description")
            OutcomeFriendlyDescription.find_or_create_by!(learning_outcome_id: outcome, context: @course, description: "FD")
            get outcome_url
            select_outcome_group_with_text(@course.name).click
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
        end

        it "creates an outcome with default ratings and calculation method" do
          get outcome_url
          create_outcome("Outcome with Individual Ratings")
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: @course, short_description: "Outcome with Individual Ratings")
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

        it "edits an outcome and changes calculation method" do
          create_bulk_outcomes_groups(@course, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(@course.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # change calculation method
          edit_individual_outcome_calculation_method("n Number of Times")
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: @course, short_description: "outcome 0")
          expect(outcome.calculation_method).to eq("n_mastery")
        end

        it "edits an outcome and changes calculation int" do
          create_bulk_outcomes_groups(@course, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(@course.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # change calculation int
          edit_individual_outcome_calculation_int(55)
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: @course, short_description: "outcome 0")
          expect(outcome.calculation_int).to eq(55)
        end

        it "edits an outcome and adds individual rating" do
          create_bulk_outcomes_groups(@course, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(@course.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # add new rating
          add_individual_outcome_rating("new", 5)
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: @course, short_description: "outcome 0")
          ratings = outcome.data[:rubric_criterion][:ratings]
          expect(ratings.length).to eq(3)
          expect(ratings[0][:description]).to eq("new")
          expect(ratings[0][:points]).to eq(5)
        end

        it "edits an outcome and deletes individual rating" do
          create_bulk_outcomes_groups(@course, 1, 1, valid_outcome_data)
          get outcome_url
          select_outcome_group_with_text(@course.name, 1).click
          individual_outcome_kabob_menu(0).click
          edit_outcome_button.click
          # delete last rating
          delete_nth_individual_outcome_rating
          click_save_edit_modal
          # Verify through AR to save time
          outcome = LearningOutcome.find_by(context: @course, short_description: "outcome 0")
          ratings = outcome.data[:rubric_criterion][:ratings]
          expect(ratings.length).to eq(1)
        end
      end

      context "alignment summary tab" do
        before do
          context_outcome(@course, 3)
          @assignment = assignment_model(course: @course)
          @aligned_outcome = LearningOutcome.find_by(context: @course, short_description: "outcome 0")
          @aligned_outcome.align(@assignment, @course)
        end

        it "shows outcomes with and without alignments" do
          get outcome_url
          click_alignments_tab
          expect(alignment_summary_outcomes_list.length).to eq(3)
          expect(alignment_summary_outcome_alignments(0)).to eq("1")
          expect(alignment_summary_outcome_alignments(1)).to eq("0")
          expect(alignment_summary_outcome_alignments(2)).to eq("0")
        end

        it "shows list of alignments when aligned outcome is expanded" do
          get outcome_url
          click_alignments_tab
          alignment_summary_expand_outcome_description_button(0).click
          expect(alignment_summary_outcome_alignments_list.length).to eq(1)
        end

        it "filters outcomes with and without alignments" do
          get outcome_url
          click_alignments_tab
          expect(alignment_summary_outcomes_list.length).to eq(3)
          # filters outcomes with alignments
          click_option(alignment_summary_filter_all_input, "With Alignments")
          expect(alignment_summary_outcomes_list.length).to eq(1)
          expect(alignment_summary_outcome_alignments(0)).to eq("1")
          # filters outcomes without alignments
          click_option(alignment_summary_filter_with_alignments_input, "Without Alignments")
          expect(alignment_summary_outcomes_list.length).to eq(2)
          expect(alignment_summary_outcome_alignments(0)).to eq("0")
          expect(alignment_summary_outcome_alignments(1)).to eq("0")
        end

        it "shows alignment summary statistics" do
          get outcome_url
          click_alignments_tab
          expect(alignment_summary_alignment_stat_name(0)).to eq("3 OUTCOMES")
          expect(alignment_summary_alignment_stat_percent(0)).to eq("33%")
          expect(alignment_summary_alignment_stat_type(0)).to eq("Coverage")
          expect(alignment_summary_alignment_stat_average(0)).to eq("0.3")
          expect(alignment_summary_alignment_stat_description(0)).to eq("Avg. Alignments per Outcome")
          expect(alignment_summary_alignment_stat_name(1)).to eq("1 ASSESSABLE ARTIFACT")
          expect(alignment_summary_alignment_stat_percent(1)).to eq("100%")
          expect(alignment_summary_alignment_stat_type(1)).to eq("With Alignments")
          expect(alignment_summary_alignment_stat_average(1)).to eq("1.0")
          expect(alignment_summary_alignment_stat_description(1)).to eq("Avg. Alignments per Artifact")
        end
      end
    end
  end
end
