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

  before(:each) do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(name: 'assignment with rubric', points_possible: 10)
    @association = @rubric.associate_with(@assignment, @course, purpose: 'grading')
  end

  it "grades assignment using rubric", priority: "2", test_id: 283749 do
    student_submission
    @association.use_for_grading = true
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # test opening and closing rubric
    scroll_into_view('.toggle_full_rubric')
    f('.toggle_full_rubric').click
    expect(f('#rubric_full')).to be_displayed
    scroll_into_view('.hide_rubric_link')
    f('#rubric_holder .hide_rubric_link').click
    wait_for_ajaximations
    expect(f('#rubric_full')).not_to be_displayed
    scroll_into_view('.toggle_full_rubric')
    f('.toggle_full_rubric').click
    rubric = f('#rubric_full')
    expect(rubric).to be_displayed

    # test rubric input
    rubric.find_element(:css, 'input.criterion_points').send_keys('3')
    expand_right_pane
    rubric.find_element(:css, '.criterion_comments img').click
    f('textarea.criterion_comments').send_keys('special rubric comment')
    f('#rubric_criterion_comments_dialog .save_button').click
    second_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[1][:id]}")
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    expect(rubric.find_element(:css, '.rubric_total')).to include_text('8')
    scroll_into_view('.save_rubric_button')
    f('#rubric_full .save_rubric_button').click
    expect(f('#rubric_summary_container > .rubric_container')).to be_displayed
    expect(f('#rubric_summary_container')).to include_text(@rubric.title)
    expect(f('#rubric_summary_container .rubric_total')).to include_text('8')
    expect(f('#grade_container input')).to have_attribute(:value, '8')
  end

  it "updates grading status icon when rubric assignment is graded", priority: "1", test_id: 3368679 do
    student_submission
    @association.use_for_grading = true
    @association.save!

    Speedgrader.visit(@course.id, @assignment.id)
    make_full_screen
    Speedgrader.view_rubric_button.click
    expand_right_pane
    # grade both criteria
    Speedgrader.grade_rubric_criteria(@rubric.criteria.first[:id], 3)
    Speedgrader.grade_rubric_criteria(@rubric.criteria.second[:id], 5)
    Speedgrader.save_rubric_button.click
    wait_for_ajaximations

    expect(Speedgrader.student_grading_status_icon(@student.name)).to have_class('graded')
  end

  it "allows commenting using rubric", priority: "1", test_id: 283750 do
    student_submission
    @association.use_for_grading = true
    @association.save!

    @rubric.data.detect{ |row| row[:learning_outcome_id] == @outcome.id }[:ignore_for_scoring] = true
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    to_comment = 'special rubric comment'
    scroll_into_view('.toggle_full_rubric')
    f('.toggle_full_rubric').click
    expect(f('#rubric_full')).to be_displayed
    expand_right_pane
    f('#rubric_full tr.learning_outcome_criterion .criterion_comments img').click
    f('textarea.criterion_comments').send_keys(to_comment)
    f('#rubric_criterion_comments_dialog .save_button').click
    scroll_into_view('.save_rubric_button')
    f('#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    saved_comment = f('#rubric_summary_container .rubric_table ' \
      'tr.learning_outcome_criterion .rating_comments_dialog_link')
    expect(saved_comment.text).to eq to_comment
  end

  it "should not convert invalid text to 0", priority: "2", test_id: 283751 do
    student_submission
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    scroll_into_view('.toggle_full_rubric')
    f('.toggle_full_rubric').click
    wait_for_ajaximations
    rubric = f('#rubric_full')

    # test rubric input
    rubric.find_element(:css, 'input.criterion_points').send_keys('SMRT')
    scroll_into_view('button.save_rubric_button')
    f('#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    scroll_into_view('.toggle_full_rubric')
    f('.toggle_full_rubric').click
    wait_for_ajaximations
    expect(f('.rubric_container .criterion_points')).to have_value('')
  end

  it "ignores rubric lines for grading", priority: "1", test_id: 283989 do
    student_submission
    @association.use_for_grading = true
    @association.save!
    @ignored = @course.created_learning_outcomes.create!(title: 'outcome', description: 'just for reference')
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
      ignore_for_scoring:'1',
    }]
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    scroll_into_view('.toggle_full_rubric')
    f('button.toggle_full_rubric').click
    f(".rubric.assessing table.rubric_table tr:nth-child(1) table.ratings td:nth-child(1)").click
    f(".rubric.assessing table.rubric_table tr:nth-child(3) table.ratings td:nth-child(1)").click
    scroll_into_view('.save_rubric_button')
    f("#rubric_holder button.save_rubric_button").click
    wait_for_ajaximations

    expect(@submission.reload.score).to eq 3
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, '3')
    expect(f("#rubric_summary_container tr:nth-child(1) .editing")).to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(1) .ignoring")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .editing")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .ignoring")).to be_displayed
    expect(f("#rubric_summary_container tr.summary .rubric_total").text).to eq '3'
    # check that null scores do not show a criterion level
    expect(f("#rubric_summary_container tr:nth-child(2) .description").text).to be_empty

    # check again that initial page load has the same data.
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, '3')
    expect(f("#rubric_summary_container tr:nth-child(1) .editing")).to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(1) .ignoring")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .editing")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .ignoring")).to be_displayed
    expect(f("#rubric_summary_container tr.summary .rubric_total").text).to eq '3'
    expect(f("#rubric_summary_container tr:nth-child(2) .description").text).to be_empty
  end

  context "when rounding .rubric_total" do
    it "should round to 2 decimal places", priority: "1", test_id: 283752 do
      setup_and_grade_rubric('1.001', '1.01')

      expect(f('#rubric_full .rubric_total').text).to eq('2.01') # while entering scores

      scroll_into_view('button.save_rubric_button')
      f('.save_rubric_button').click
      wait_for_ajaximations
      expect(f('#rubric_summary_holder .rubric_total').text).to eq('2.01') # seeing the summary after entering scores

      scroll_into_view('.toggle_full_rubric')
      f('.toggle_full_rubric').click
      wait_for_ajaximations
      expect(f('#rubric_full .rubric_total').text).to eq('2.01') # after opening the rubric up again to re-score
    end

    it "should not display trailing zeros", priority: "1", test_id: 283753 do
      setup_and_grade_rubric('1', '1')

      expect(f('#rubric_full .rubric_total').text).to eq('2') # while entering scores

      scroll_into_view('button.save_rubric_button')
      f('.save_rubric_button').click
      wait_for_ajaximations
      expect(f('#rubric_summary_holder .rubric_total').text).to eq('2') # seeing the summary after entering scores

      scroll_into_view('.toggle_full_rubric')
      f('.toggle_full_rubric').click
      wait_for_ajaximations
      expect(f('#rubric_full .rubric_total').text).to eq('2') # after opening the rubric up again to re-score
    end
  end
end
