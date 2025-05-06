# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../../conditional_release_spec_helper"
require_relative "../assignments/page_objects/assignments_index_page"
require_relative "../content_migrations/page_objects/new_course_copy_page"
require_relative "../content_migrations/page_objects/new_content_migration_page"
require_relative "page_objects/conditional_release_objects"

describe "native canvas conditional release" do
  include AssignmentsIndexPage

  include_context "in-process server selenium tests"
  before(:once) do
    account = Account.default
    account.settings[:conditional_release] = { value: true }
    account.save!
  end

  before do
    course_with_teacher_logged_in
    @course.conditional_release = true
    @course.save!
  end

  def wait_for_migration_to_complete
    keep_trying_for_attempt_times(attempts: 10, sleep_interval: 1) do
      wait_for_ajaximations
    end
  end

  context "Pages as part of Mastery Paths" do
    it "is not included in the assignments page" do
      page_title = "MP Page to Verify"
      @new_page = @course.wiki_pages.create!(title: page_title)
      page_assignment = @new_page.course.assignments.create!(
        wiki_page: @new_page,
        submission_types: "wiki_page",
        title: @new_page.title
      )

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect { assignment_row(page_assignment.id) }.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
    end
  end

  context "Quizzes Classic as part of Mastery Paths" do
    it "displays Mastery Paths tab in quizzes edit page" do
      course_quiz
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      expect(ConditionalReleaseObjects.quiz_conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.quiz_conditional_release_link.click
      expect(ConditionalReleaseObjects.cr_editor_exists?).to be(true)
    end

    it "disables Mastery Paths tab in quizzes for quiz types other than graded" do
      course_quiz

      quiz_types_without_mastery_paths = %i[
        practice_quiz
        graded_survey
        survey
      ].freeze

      quiz_types_without_mastery_paths.each do |type|
        @quiz.quiz_type = type
        @quiz.save!
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(ConditionalReleaseObjects.disabled_cr_editor_exists?).to be(true)
      end
    end
  end

  context "Discussions as part of Mastery Paths" do
    it "displays Mastery paths tab from (graded) Discussions edit page" do
      discussion_topic_model(context: @course)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"

      expect(ConditionalReleaseObjects.conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.conditional_release_editor_exists?).to be(true)
    end
  end

  context "Assignment Mastery Paths" do
    it "displays Mastery Paths tab in assignments edit page" do
      assignment = assignment_model(course: @course)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

      expect(ConditionalReleaseObjects.conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.conditional_release_editor_exists?).to be(true)
    end

    it "is able to see default conditional release editor" do
      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.scoring_ranges.count).to eq(3)
      expect(ConditionalReleaseObjects.top_scoring_boundary.text).to eq("100 pts")
    end

    it "is able to set scoring range" do
      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      division_cutoff1 = ConditionalReleaseObjects.division_cutoff(0)
      division_cutoff2 = ConditionalReleaseObjects.division_cutoff(1)
      ConditionalReleaseObjects.replace_mastery_path_scores(division_cutoff1, "70", "72")
      ConditionalReleaseObjects.replace_mastery_path_scores(division_cutoff2, "40", "47")
      division_cutoff2.send_keys :tab

      expect(division_cutoff1.attribute("value")).to eq("72 pts")
      expect(division_cutoff2.attribute("value")).to eq("47 pts")
    end

    it "is able to add an assignment to a range", :ignore_js_errors do
      main_assignment = assignment_model(course: @course, points_possible: 100)
      assignment_for_mp = assignment_model(course: @course, points_possible: 10, title: "Assignment for MP")
      get "/courses/#{@course.id}/assignments/#{main_assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      ConditionalReleaseObjects.last_add_assignment_button.click
      ConditionalReleaseObjects.mp_assignment_checkbox(assignment_for_mp.title).click
      ConditionalReleaseObjects.add_items_button.click

      expect(ConditionalReleaseObjects.assignment_card_exists?(assignment_for_mp.title)).to be(true)
    end

    it "is able to toggle and/or between two assignments", :ignore_js_errors do
      main_assignment = assignment_model(course: @course, points_possible: 100)
      assignment1_for_mp = assignment_model(course: @course, points_possible: 10, title: "Assignment 1 for MP")
      assignment2_for_mp = assignment_model(course: @course, points_possible: 10, title: "Assignment 2 for MP")
      get "/courses/#{@course.id}/assignments/#{main_assignment.id}/edit"

      ConditionalReleaseObjects.conditional_release_link.click
      [assignment1_for_mp, assignment2_for_mp].each do |assignment_to_add|
        ConditionalReleaseObjects.last_add_assignment_button.click
        ConditionalReleaseObjects.mp_assignment_checkbox(assignment_to_add.title).click
        ConditionalReleaseObjects.add_items_button.click
      end

      expect(ConditionalReleaseObjects.and_toggle_button_exists?).to be(true)

      ConditionalReleaseObjects.and_toggle_button.click
      expect(ConditionalReleaseObjects.or_toggle_button_exists?).to be(true)

      ConditionalReleaseObjects.or_toggle_button.click
      expect(ConditionalReleaseObjects.and_toggle_button_exists?).to be(true)
    end

    it "is able to move assignment to next row", :ignore_js_errors do
      main_assignment = assignment_model(course: @course, points_possible: 100)
      assignment_for_mp = assignment_model(course: @course, points_possible: 10, title: "Assignment for MP")
      get "/courses/#{@course.id}/assignments/#{main_assignment.id}/edit"

      ConditionalReleaseObjects.conditional_release_link.click
      ConditionalReleaseObjects.last_add_assignment_button.click
      ConditionalReleaseObjects.mp_assignment_checkbox(assignment_for_mp.title).click
      ConditionalReleaseObjects.add_items_button.click
      ConditionalReleaseObjects.assignment_options_button(assignment_for_mp.title).click
      ConditionalReleaseObjects.menu_option("Move to 70 pts - 100 pts").click

      expect(ConditionalReleaseObjects.assignment_exists_in_scoring_range?(1, assignment_for_mp.title)).to be(true)
    end

    it "is able see errors for invalid scoring ranges" do
      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      division_cutoff1 = ConditionalReleaseObjects.division_cutoff(0)

      ConditionalReleaseObjects.replace_mastery_path_scores(division_cutoff1, "70", "")
      expect(ConditionalReleaseObjects.scoring_input_error[0].text).to include("Please enter a score")

      ConditionalReleaseObjects.replace_mastery_path_scores(division_cutoff1, "", "35")
      expect(ConditionalReleaseObjects.scoring_input_error[0].text).to include("Please adjust score order")
    end

    it "does not show error setting middle range to 0" do
      assignment = assignment_model(course: @course, points_possible: 4)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      division_cutoff1 = ConditionalReleaseObjects.division_cutoff(0)
      division_cutoff2 = ConditionalReleaseObjects.division_cutoff(1)
      replace_content(division_cutoff1, "2")
      replace_content(division_cutoff2, "0")

      expect(element_exists?(ConditionalReleaseObjects.scoring_input_error_selector)).to be_falsey
    end
  end

  context "Mastery Path Breakdowns" do
    before do
      @trigger_assmt = @course.assignments.create!(points_possible: 10, submission_types: "online_text_entry")
      ranges = [
        create(
          :scoring_range_with_assignments,
          assignment_set_count: 1,
          assignment_count: 1,
          lower_bound: 0.7,
          upper_bound: 1.0
        ),
        create(
          :scoring_range_with_assignments,
          assignment_set_count: 1,
          assignment_count: 2,
          lower_bound: 0.4,
          upper_bound: 0.7
        ),
        create(
          :scoring_range_with_assignments,
          assignment_set_count: 2,
          assignment_count: 2,
          lower_bound: 0,
          upper_bound: 0.4
        ),
      ]
      @rule = @course.conditional_release_rules.create!(trigger_assignment: @trigger_assmt, scoring_ranges: ranges)
    end

    it "shows Mastery Path Breakdown for an Assignment" do
      get "/courses/#{@course.id}/assignments/#{@trigger_assmt.id}"

      expect(ConditionalReleaseObjects.breakdown_graph_exists?).to be(true)
    end

    it "shows Mastery Path Breakdown for a Discussion" do
      skip "Will be fixed in VICE-5209"
      graded_discussion = @course.discussion_topics.build(assignment: @trigger_assmt, title: "graded discussion")
      graded_discussion.save!
      get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}"

      expect(ConditionalReleaseObjects.breakdown_graph_exists?).to be(true)
    end
  end

  context "Copying a course with a mastery path" do
    it "copies a mastery path course with wiki pages correctly" do
      course_with_admin_logged_in

      Account.site_admin.enable_feature!(:wiki_page_mastery_path_no_assignment_group)

      page_title = "MP Page to Verify"
      @new_page = @course.wiki_pages.create!(title: page_title)
      page_assignment = @new_page.course.assignments.create!(
        wiki_page: @new_page,
        submission_types: "wiki_page",
        title: @new_page.title
      )

      @trigger_assignment = @course.assignments.create!(
        title: "Trigger Assignment",
        grading_type: "points",
        points_possible: 100,
        submission_types: "online_text_entry"
      )

      page_assignment.assignment_overrides.create!(
        set_type: "Noop",
        set_id: 1,
        all_day: false,
        title: "Mastery Paths",
        unlock_at_overridden: true,
        lock_at_overridden: true,
        due_at_overridden: true
      )

      course_module = @course.context_modules.create!(name: "Mastery Path Module")
      course_module.add_item(id: @trigger_assignment.id, type: "assignment")
      course_module.add_item(id: @new_page.id, type: "wiki_page")

      ranges = [
        ConditionalRelease::ScoringRange.new(
          lower_bound: 0,
          upper_bound: 0.4,
          assignment_sets: [
            ConditionalRelease::AssignmentSet.new(
              assignment_set_associations: [
                ConditionalRelease::AssignmentSetAssociation.new(
                  assignment_id: page_assignment.id
                )
              ]
            )
          ]
        )
      ]
      @rule = @course.conditional_release_rules.create!(trigger_assignment: @trigger_assignment, scoring_ranges: ranges)
      get "/courses/#{@course.id}/modules"
      get "/courses/#{@course.id}/copy"

      expect_new_page_load { NewCourseCopyPage.create_course_button.click }

      run_jobs
      wait_for_ajaximations
      wait_for_migration_to_complete

      @new_course = Course.last

      expect(@new_course.conditional_release).to be(true)
      expect(@new_course.assignments.count).to eq(2)
    end
  end
end
