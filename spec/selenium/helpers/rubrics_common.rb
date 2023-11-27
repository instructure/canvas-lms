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

module RubricsCommon
  def create_rubric_with_criterion_points(points)
    get rubric_url

    f(".add_rubric_link").click
    check_element_has_focus(fj("#rubric_new :text:first"))
    criterion_points = f("#criterion_1 .criterion_points")
    set_value(criterion_points, points.to_s)
    criterion_points.send_keys(:return)
    submit_form("#edit_rubric_form")
    wait_for_ajaximations
  end

  def create_assignment_with_points(points)
    assignment_name = "first test assignment"
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(name: "default")
    @assignment = @course.assignments.create(
      name: assignment_name,
      due_at: due_date,
      points_possible: points,
      assignment_group: @group
    )
    @assignment
  end

  def assignment_with_rubric(points, title = "new rubric")
    @assignment = create_assignment_with_points(points)
    rubric_model(title:,
                 data:
                                        [{
                                          description: "Some criterion",
                                          points:,
                                          id: "crit1",
                                          ratings:
                                                 [{ description: "Good", points:, id: "rat1", criterion_id: "crit1" }]
                                        }],
                 description: "new rubric description")
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: false)
  end

  def assignment_with_editable_rubric(points, title = "My Rubric")
    @assignment = create_assignment_with_points(points)
    @rubric = @course.rubrics.build
    rubric_params = {
      title:,
      hide_score_total: false,
      criteria: {
        "0" => {
          points:,
          description: "no outcome row",
          long_description: "non outcome criterion",
          ratings: {
            "0" => {
              points:,
              description: "Amazing",
            },
            "1" => {
              points: points * 0.30,
              description: "Reduced Marks",
            },
            "2" => {
              points: 0,
              description: "No Marks",
            }
          }
        }
      }
    }
    @rubric.update_criteria(rubric_params)
    @rubric.reload
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
  end

  def edit_rubric_after_updating
    fj(".rubric .edit_rubric_link:visible").click
  end

  def should_delete_a_rubric
    create_rubric_with_criterion_points "5"
    f(".delete_rubric_link").click
    driver.switch_to.alert.accept
    ff("#rubrics .rubric").each { |rubric| expect(rubric).not_to be_displayed }
    expect(Rubric.last.workflow_state).to eq "deleted"
  end

  def should_edit_a_rubric
    edit_title = "edited rubric"
    create_rubric_with_criterion_points "5"
    rubric = Rubric.last
    f(".edit_rubric_link").click
    replace_content(ff("#rubric_#{rubric.id} .rubric_title input")[1], edit_title)
    submit_form(ff("#rubric_#{rubric.id} #edit_rubric_form")[1])
    expect(f(".rubric_title .title")).to include_text edit_title
    rubric.reload
    expect(rubric.title).to eq edit_title
  end

  def should_allow_fractional_points
    create_rubric_with_criterion_points "5.5"
    expect(fj(".rubric .criterion:visible .display_criterion_points").text).to eq "5.5"
    expect(fj(".rubric .criterion:visible .rating .points").text).to eq "5.5"
  end

  def should_round_to_2_decimal_places
    create_rubric_with_criterion_points "5.249"
    expect(fj(".rubric .criterion:visible .display_criterion_points")).to include_text "5.25"
  end

  def should_round_to_an_integer_when_splitting
    create_rubric_with_criterion_points "5.5"
    edit_rubric_after_updating

    wait_for_ajaximations
    fj(".add_rating_link_after:visible").click
    expect(f("#edit_rating_form input")).to have_value("3")
    set_value(f("#rating_form_title"), "three")
    fj("span:contains('Update Rating')").click
    wait_for_ajaximations
    expect(ffj(".rubric .criterion:visible .rating .points").count).to eq 3
    expect(ffj(".rubric .criterion:visible .rating .points")[1].text).to eq "3"
  end

  def import_outcome
    f("#rubric-action-buttons .edit_rubric_link").click
    wait_for_ajaximations
    f(".rubric.editing tr.criterion .delete_criterion_link").click
    wait_for_ajaximations
    f(".rubric.editing .find_outcome_link").click
    wait_for_ajaximations
    f(".outcome-link").click
    wait_for_ajaximations
    f(".ui-dialog .btn-primary").click
    wait_for_ajaximations
  end
end
