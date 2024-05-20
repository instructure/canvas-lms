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
  end

  context "Pages as part of Mastery Paths" do
    it "shows Allow in Mastery Paths for a Page when feature enabled" do
      get "/courses/#{@course.id}/pages/new/edit"
      expect(ConditionalReleaseObjects.conditional_content_exists?).to be(true)
    end

    it "does not show Allow in Mastery Paths when feature disabled" do
      account = Account.default
      account.settings[:conditional_release] = { value: false }
      account.save!
      get "/courses/#{@course.id}/pages/new/edit"
      expect(ConditionalReleaseObjects.conditional_content_exists?).to be(false)
    end

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
      ConditionalReleaseObjects.replace_mastery_path_scores(ConditionalReleaseObjects.division_cutoff1, "70", "72")
      ConditionalReleaseObjects.replace_mastery_path_scores(ConditionalReleaseObjects.division_cutoff2, "40", "47")
      ConditionalReleaseObjects.division_cutoff2.send_keys :tab

      expect(ConditionalReleaseObjects.division_cutoff1.attribute("value")).to eq("72 pts")
      expect(ConditionalReleaseObjects.division_cutoff2.attribute("value")).to eq("47 pts")
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

      ConditionalReleaseObjects.replace_mastery_path_scores(ConditionalReleaseObjects.division_cutoff1, "70", "")
      expect(ConditionalReleaseObjects.must_not_be_empty_exists?).to be(true)

      ConditionalReleaseObjects.replace_mastery_path_scores(ConditionalReleaseObjects.division_cutoff1, "", "35")
      expect(ConditionalReleaseObjects.these_scores_are_out_of_order_exists?).to be(true)
    end

    it "does not show error setting middle range to 0" do
      assignment = assignment_model(course: @course, points_possible: 4)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      replace_content(ConditionalReleaseObjects.division_cutoff1, "2")
      replace_content(ConditionalReleaseObjects.division_cutoff2, "0")

      expect(ConditionalReleaseObjects.must_not_be_empty_exists?).to be(false)
      expect(ConditionalReleaseObjects.these_scores_are_out_of_order_exists?).to be(false)
      expect(ConditionalReleaseObjects.must_be_a_number_exists?).to be(false)
      expect(ConditionalReleaseObjects.number_is_too_small_exists?).to be(false)
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
      graded_discussion = @course.discussion_topics.build(assignment: @trigger_assmt, title: "graded discussion")
      graded_discussion.save!
      get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}"

      expect(ConditionalReleaseObjects.breakdown_graph_exists?).to be(true)
    end
  end
end
