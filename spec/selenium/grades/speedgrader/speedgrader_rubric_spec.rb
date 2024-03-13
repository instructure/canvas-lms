# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../../helpers/speed_grader_common"
require_relative "../pages/speedgrader_page"

describe "speed grader - rubrics" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(name: "assignment with rubric", points_possible: 10)
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading")
  end

  it "grades assignment using rubric", priority: "2" do
    student_submission
    @association.use_for_grading = true
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # test opening and closing rubric
    scroll_into_view(".toggle_full_rubric")
    f(".toggle_full_rubric").click
    expect(f("#rubric_full")).to be_displayed
    scroll_into_view(".hide_rubric_link")
    f("#rubric_holder .hide_rubric_link").click
    wait_for_ajaximations
    expect(f("#rubric_full")).not_to be_displayed
    scroll_into_view(".toggle_full_rubric")
    f(".toggle_full_rubric").click
    rubric = f("#rubric_full")
    expect(rubric).to be_displayed

    # test rubric input
    f('td[data-testid="criterion-points"] input').send_keys("3")
    expand_right_pane
    ff(".rating-description").find { |elt| elt.displayed? && elt.text == "Amazing" }.click
    driver.execute_script(%(document.querySelector('svg[name="IconFeedback"]').parentElement.click()))
    f("textarea[data-selenium='criterion_comments_text']").send_keys("special rubric comment")
    wait_for_ajaximations
    expect(f("span[data-selenium='rubric_total']")).to include_text("8")
    wait_for_ajaximations
    scroll_into_view(".save_rubric_button")
    wait_for_ajaximations
    f("#rubric_full .save_rubric_button").click
    wait_for_ajaximations
    scroll_into_view(".save_rubric_button")
    expect(f("#rubric_summary_container > .rubric_container")).to be_displayed
    expect(f("#rubric_summary_container")).to include_text(@rubric.title)
    expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("8")
    expect(f("#grade_container input")).to have_attribute(:value, "8")
  end

  it "updates grading status icon when rubric assignment is graded", priority: "1" do
    student_submission
    @association.use_for_grading = true
    @association.save!

    Speedgrader.visit(@course.id, @assignment.id)

    Speedgrader.view_rubric_button.click
    expand_right_pane
    # grade both criteria
    Speedgrader.select_rubric_criterion("Rockin'")
    Speedgrader.select_rubric_criterion("Amazing")
    Speedgrader.save_rubric_button.click
    wait_for_ajaximations

    expect(Speedgrader.student_grading_status_icon(@student.name)).to have_class("graded")
  end

  it "allows commenting using rubric", priority: "1" do
    student_submission
    @association.use_for_grading = true
    @association.save!

    @rubric.data.detect { |row| row[:learning_outcome_id] == @outcome.id }[:ignore_for_scoring] = true
    @rubric.save!

    Speedgrader.visit(@course.id, @assignment.id)

    to_comment = "special rubric comment"
    Speedgrader.view_rubric_button.click
    expect(f("#rubric_full")).to be_displayed

    Speedgrader.expand_right_pane
    Speedgrader.comment_button_for_row("no outcome row").click
    Speedgrader.additional_comment_textarea.send_keys(to_comment)
    wait_for_ajaximations
    Speedgrader.enter_rubric_points("1")
    button = Speedgrader.save_rubric_button
    keep_trying_until do
      button.click
      true
    end
    wait_for_ajaximations
    expect(Speedgrader.rubric_comment_for_row("no outcome row")).to include_text to_comment
  end

  it "does not convert invalid text to 0", priority: "2" do
    student_submission
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    scroll_into_view(".toggle_full_rubric")
    f(".toggle_full_rubric").click
    wait_for_ajaximations

    # test rubric input
    f('td[data-testid="criterion-points"] input').send_keys("SMRT")
    scroll_into_view("button.save_rubric_button")
    f("#rubric_full .save_rubric_button").click
    wait_for_ajaximations
    scroll_into_view(".toggle_full_rubric")
    f(".toggle_full_rubric").click
    wait_for_ajaximations
    expect(f('.rubric_container td[data-testid="criterion-points"] input')).to have_value("--")
  end

  it "ignores rubric lines for grading", priority: "1" do
    student_submission
    @association.use_for_grading = true
    @association.save!
    @ignored = @course.created_learning_outcomes.create!(title: "outcome", description: "just for reference")
    @rubric.data = @rubric.data + [{
      points: 3,
      description: "just for reference",
      id: 3,
      ratings: [
        {
          points: 3,
          description: "You Learned",
          criterion_id: 3,
          id: 6,
        },
        {
          points: 0,
          description: "No-learn-y",
          criterion_id: 3,
          id: 7,
        },
      ],
      learning_outcome_id: @ignored.id,
      ignore_for_scoring: "1",
    }]
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    scroll_into_view(".toggle_full_rubric")
    f("button.toggle_full_rubric").click
    fj("span:contains('Rockin\\''):visible").click
    fj("span:contains('You Learned'):visible").click
    scroll_into_view(".save_rubric_button")
    f("#rubric_holder button.save_rubric_button").click
    wait_for_ajaximations

    expect(@submission.reload.score).to eq 3
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, "3")
    expect(f("#rubric_summary_container tr:nth-child(1) td")).to include_text("3 pts")
    expect(f("#rubric_summary_container tr:nth-child(3) td")).not_to include_text("pts")

    expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("3")
    expect(f("#rubric_summary_container tr:nth-child(2) td")).to include_text("-- / 5 pts")

    # check again that initial page load has the same data.
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, "3")
    expect(f("#rubric_summary_container tr:nth-child(1) td")).to include_text("3 pts")
    expect(f("#rubric_summary_container tr:nth-child(3) td")).not_to include_text("pts")
    expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("3")
    expect(f("#rubric_summary_container tr:nth-child(2) td")).to include_text("-- / 5 pts")
  end

  context "when rounding .rubric_total" do
    it "rounds to 2 decimal places", priority: "1" do
      setup_and_grade_rubric("1.001", "1.01")

      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2.01") # while entering scores

      scroll_into_view("button.save_rubric_button")
      f(".save_rubric_button").click
      wait_for_ajaximations
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2.01") # seeing the summary after entering scores

      scroll_into_view(".toggle_full_rubric")
      f(".toggle_full_rubric").click
      wait_for_ajaximations
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2.01") # after opening the rubric up again to re-score
    end

    it "does not display trailing zeros", priority: "1" do
      setup_and_grade_rubric("1", "1")

      expect(f("span[data-selenium='rubric_total']")).to include_text("2") # while entering scores

      scroll_into_view("button.save_rubric_button")
      f(".save_rubric_button").click
      wait_for_ajaximations
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2") # seeing the summary after entering scores

      scroll_into_view(".toggle_full_rubric")
      f(".toggle_full_rubric").click
      wait_for_ajaximations
      expect(fj("span[data-selenium='rubric_total']:visible")).to include_text("2") # after opening the rubric up again to re-score
    end
  end
end
