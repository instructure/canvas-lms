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

require_relative '../helpers/outcome_common'
require_relative 'pages/improved_outcome_management_page'

describe "outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon
  include ImprovedOutcomeManagementPage

  let(:who_to_login) { 'teacher' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  describe "course outcomes" do
    before(:each) do
      course_with_teacher_logged_in
    end

    def save_without_error(value = 4, title = 'New Outcome')
      replace_content(f('.outcomes-content input[name=title]'), title)
      replace_content(f('input[name=calculation_int]'), value)
      f('.submit_button').click
      wait_for_ajaximations
      expect(f('.title').text).to include(title)
      expect((f('#calculation_int').text).to_i).to eq(value)
    end

    context "create/edit/delete outcomes" do
      it "creates a learning outcome with a new rating (root level)", priority: "1", test_id: 250533 do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "creates a learning outcome (nested)", priority: "1", test_id: 250534 do
        should_create_a_learning_outcome_nested
      end

      it "edits a learning outcome and delete a rating", priority: "1", test_id: 250535 do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "deletes a learning outcome", priority: "1", test_id: 250536 do
        skip_if_safari(:alert)
        should_delete_a_learning_outcome
      end

      context "validate decaying average" do
        before do
          get outcome_url
          f('.add_outcome_link').click
        end

        it "validates default values", priority: "1", test_id: 261707 do
          expect(f('#calculation_method')).to have_value('decaying_average')
          expect(f('#calculation_int')).to have_value('65')
          expect(f('#calculation_int_example')).to include_text("Most recent result counts as 65%"\
                                                                " of mastery weight, average of all other results count"\
                                                                " as 35% of weight. If there is only one result, the single score"\
                                                                " will be returned.")
        end

        it "validates decaying average_range", priority: "2", test_id: 261708 do
          should_validate_decaying_average_range
        end

        it "validates calculation int accepatble values", priority: "1", test_id: 261709 do
          save_without_error(1)
          f('.edit_button').click
          save_without_error(99)
        end

        it "retains the settings after saving", priority: "1", test_id: 261710 do
          save_without_error(rand(99) + 1, 'Decaying Average')
          expect(f('#calculation_method').text).to include('Decaying Average')
        end
      end

      context "validate n mastery" do
        before do
          get outcome_url
          f('.add_outcome_link').click
        end

        it "validates default values", priority: "1", test_id: 261711 do
          click_option('#calculation_method', "n Number of Times")
          expect(f('#calculation_int')).to have_value('5')
          expect(f('#mastery_points')).to have_value('3')
          expect(f('#calculation_int_example')).to include_text("Must achieve mastery at least 5 times."\
                                                                " Scores above mastery will be averaged"\
                                                                " to calculate final score")
        end

        it "validates n mastery_range", priority: "2", test_id: 303711 do
          should_validate_n_mastery_range
        end

        it "validates calculation int acceptable range values", priority: "1", test_id: 261713 do
          click_option('#calculation_method', "n Number of Times")
          save_without_error(2)
          f('.edit_button').click
          save_without_error(5)
        end

        it "retains the settings after saving", priority: "1", test_id: 261714 do
          click_option('#calculation_method', "n Number of Times")
          save_without_error(3, 'n Number of Times')
          refresh_page
          fj('.outcomes-sidebar .outcome-level:first li').click
          expect(f('#calculation_int').text).to eq('3')
          expect(f('#calculation_method').text).to include('n Number of Times')
        end
      end

      context "create/edit/delete outcome groups" do
        it "creates an outcome group (root level)", priority: "2", test_id: 560586 do
          should_create_an_outcome_group_root_level
        end

        it "creates an outcome group (nested)", priority: "1", test_id: 250237 do
          should_create_an_outcome_group_nested
        end

        it "edits an outcome group", priority: "2", test_id: 114340 do
          should_edit_an_outcome_group
        end

        it "deletes an outcome group", priority: "2", test_id: 250553 do
          skip_if_safari(:alert)
          should_delete_an_outcome_group
        end

        it "drags and drop an outcome to an outcome group", priority: "2", test_id: 114339 do
          group = @course.learning_outcome_groups.create!(title: 'groupage')
          group2 = @course.learning_outcome_groups.create!(title: 'groupage2')
          group.adopt_outcome_group(group2)
          group2.add_outcome @course.created_learning_outcomes.create!(title: 'o1')
          get "/courses/#{@course.id}/outcomes"
          f(".ellipsis[title='groupage2']").click
          wait_for_ajaximations

          # make sure the outcome group 'groupage2' and outcome 'o1' are on different frames
          expect(ffj(".outcome-level:first .outcome-group .ellipsis")[0]).to have_attribute("title", 'groupage2')
          expect(ffj(".outcome-level:last .outcome-link .ellipsis")[0]).to have_attribute("title", 'o1')
          drag_and_drop_element(ffj(".outcome-level:last .outcome-link .ellipsis")[0], ffj(' .outcome-level')[0])
          wait_for_ajaximations

          # after the drag and drop, the outcome and the group are on a same screen
          expect(ffj(".outcome-level:last .outcome-group .ellipsis")[0]).to have_attribute("title", 'groupage2')
          expect(ffj(".outcome-level:last .outcome-link .ellipsis")[0]).to have_attribute("title", 'o1')

          # assert there is only one frame now after the drag and drop
          expect(ffj(' .outcome-level:first')).to eq ffj(' .outcome-level:last')
        end
      end
    end

    context "actions" do
      it "does not render an HTML-escaped title in outcome directory while editing", priority: "2", test_id: 250554 do
        title = 'escape & me <<->> if you dare'
        who_to_login == 'teacher' ? @context = @course : @context = account
        outcome_model
        get outcome_url
        wait_for_ajaximations
        fj('.outcomes-sidebar .outcome-level:first li').click
        wait_for_ajaximations
        f('.edit_button').click

        # pass in the unescaped version of the title:
        replace_content f('.outcomes-content input[name=title]'), title
        f('.submit_button').click
        wait_for_ajaximations

        # the "readable" version should be rendered in directory browser
        li_el = fj('.outcomes-sidebar .outcome-level:first li:first')
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
      it "shows rubrics as aligned items", priority: "2", test_id: 250555 do
        outcome_with_rubric

        get "/courses/#{@course.id}/outcomes/#{@outcome.id}"
        wait_for_ajaximations

        expect(f('#alignments').text).to match(/#{@rubric.title}/)
      end
    end

    describe 'with improved_outcome_management enabled' do
      before(:each) do
        enable_improved_outcomes_management(Account.default)
      end

      it 'creates an initial outcome in the course level as a teacher' do
        get outcome_url
        create_outcome('Test Outcome')
        run_jobs
        get outcome_url
        # Initial Group is created as well as a Create New Group button
        expect(tree_browser_outcome_groups.count).to eq(2)
        group_text = tree_browser_outcome_groups[0].text.split("\n")[0]
        expect(group_text).to eq(@course.name)
        add_new_group_text = tree_browser_outcome_groups[1].text
        # Verify through AR to save time
        expect(add_new_group_text).to eq('Create New Group')
        expect(LearningOutcome.where(context_id: @course.id).count).to eq(1)
        expect(LearningOutcome.find_by(context_id: @course.id).short_description).to eq('Test Outcome')
      end

      it 'edits an existing outcome in the course level as a teacher' do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        expect(nth_individual_outcome_title(0)).to eq('outcome 0')
        individual_outcome_kabob_menu(0).click
        edit_outcome_button.click
        edit_outcome_title('Edited Title')
        click_save_edit_modal
        expect(nth_individual_outcome_title(0)).to eq('Edited Title')
      end

      it 'removes a single outcome in the course level as a teacher' do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        expect(nth_individual_outcome_title(0)).to eq('outcome 0')
        individual_outcome_kabob_menu(0).click
        click_remove_outcome_button
        click_confirm_remove_button
        expect(no_outcomes_billboard.present?).to eq(true)
      end

      it 'moves an outcome into a newly created outcome group as a teacher' do
        create_bulk_outcomes_groups(@course, 1, 1)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        individual_outcome_kabob_menu(0).click
        click_move_outcome_button
        click_create_new_group_in_move_modal_button
        insert_new_group_name_in_move_modal('New group')
        click_confirm_new_group_in_move_modal_button
        tree_browser_root_group.click
        select_drilldown_outcome_group_with_text('New group').click
        force_click(confirm_move_button)
        # Verify through AR to save time
        new_group_children = LearningOutcomeGroup.find_by(title: 'New group').child_outcome_links
        expect(new_group_children.count).to eq(1)
        expect(new_group_children.first.title).to eq('outcome 0')
      end

      it 'bulk removes outcomes at the course level as a teacher' do
        create_bulk_outcomes_groups(@course, 1, 5)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        force_click(select_nth_outcome_for_bulk_action(0))
        force_click(select_nth_outcome_for_bulk_action(1))
        force_click(select_nth_outcome_for_bulk_action(2))
        force_click(select_nth_outcome_for_bulk_action(3))
        click_remove_button
        click_confirm_remove_button
        expect(nth_individual_outcome_title(0)).to eq('outcome 4')
      end

      # Can't reproduce the js error locally
      it 'bulk moves outcomes at the course level as a teacher', ignore_js_errors: true do
        create_bulk_outcomes_groups(@course, 1, 3)
        get outcome_url
        select_outcome_group_with_text(@course.name).click
        force_click(select_nth_outcome_for_bulk_action(0))
        force_click(select_nth_outcome_for_bulk_action(1))
        click_move_button
        click_create_new_group_in_move_modal_button
        insert_new_group_name_in_move_modal('New group')
        click_confirm_new_group_in_move_modal_button
        select_drilldown_outcome_group_with_text('New group').click
        force_click(confirm_move_button)
        # Verify through AR to save time
        new_group_children = LearningOutcomeGroup.find_by(title: 'New group').child_outcome_links
        expect(new_group_children.count).to eq(2)
        expect(new_group_children.pluck(:title).sort).to eq(['outcome 0', 'outcome 1'])
      end

      it 'imports account outcomes into a course via Find modal' do
        create_bulk_outcomes_groups(Account.default, 1, 10)
        get outcome_url
        open_find_modal
        select_outcome_group_with_text('Account Standards').click
        select_outcome_group_with_text('Default Account').click
        job_count = Delayed::Job.count
        outcome0_title = nth_find_outcome_modal_item_title(0)
        add_button_nth_find_outcome_modal_item(0).click
        click_done_find_modal

        # ImportOutcomes operations enqueue jobs that will need to be manually processed
        expect(Delayed::Job.count).to eq(job_count + 1)
        run_jobs

        # Verify by titles that the outcomes are imported into current root account
        course_outcomes = LearningOutcomeGroup.find_by(context_id: @course.id, context_type: 'Course', title: 'group 0').child_outcome_links
        # Since the outcomes existed already and are just imported into a new group, we're checking the new content tags
        expect(course_outcomes[0].title).to eq(outcome0_title)
      end
    end
  end
end
