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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/gradebook_page'

describe "Gradebook - group weights" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  def student_totals()
    totals = ff('.total-cell')
    points = []
    for i in totals do
      points.push(i.text)
    end
    points
  end

  def toggle_group_weight
    gradebook_page.settings_cog_select
    set_group_weights.click
    group_weighting_scheme.click
    gradebook_page.save_button_click
    wait_for_ajax_requests
  end

  before(:each) do
    course_with_teacher_logged_in
    student_in_course
    @course.update(group_weighting_scheme: 'percent')
    @group1 = @course.assignment_groups.create!(name: 'first assignment group', group_weight: 50)
    @group2 = @course.assignment_groups.create!(name: 'second assignment group', group_weight: 50)
    @assignment1 = assignment_model({
                                      course: @course,
                                      name: 'first assignment',
                                      due_at: Date.today,
                                      points_possible: 50,
                                      submission_types: 'online_text_entry',
                                      assignment_group: @group1
                                    })
    @assignment2 = assignment_model({
                                      course: @course,
                                      name: 'second assignment',
                                      due_at: Date.today,
                                      points_possible: 10,
                                      submission_types: 'online_text_entry',
                                      assignment_group: @group2
                                    })
    @course.reload
  end

  it 'should show total column as points' do
    @assignment1.grade_student @student, grade: 20, grader: @teacher
    @assignment2.grade_student @student, grade: 5, grader: @teacher

    @course.show_total_grade_as_points = true
    @course.update(group_weighting_scheme: 'points')

    # Displays total column as points
    Gradebook.visit(@course)
    expect(student_totals).to eq(["25"])
  end

  it 'should show total column as percent' do
    @assignment1.grade_student @student, grade: 20, grader: @teacher
    @assignment2.grade_student @student, grade: 5, grader: @teacher

    @course.show_total_grade_as_points = false
    @course.update(group_weighting_scheme: 'percent')

    # Displays total column as points
    Gradebook.visit(@course)
    expect(student_totals).to eq(["45%"])
  end

  context "warning message" do
    before(:each) do
      course_with_teacher_logged_in
      student_in_course
      @course.update(group_weighting_scheme: 'percent')
      @group1 = @course.assignment_groups.create!(name: 'first assignment group', group_weight: 50)
      @group2 = @course.assignment_groups.create!(name: 'second assignment group', group_weight: 50)
      @assignment1 = assignment_model({
                                        course: @course,
                                        name: 'first assignment',
                                        due_at: Date.today,
                                        points_possible: 50,
                                        submission_types: 'online_text_entry',
                                        assignment_group: @group1
                                      })
      @assignment2 = assignment_model({
                                        course: @course,
                                        name: 'second assignment',
                                        due_at: Date.today,
                                        points_possible: 0,
                                        submission_types: 'online_text_entry',
                                        assignment_group: @group2
                                      })
      @course.reload
    end

    it 'should display a warning icon in the total column', priority: '1', test_id: 164013 do
      Gradebook.visit(@course)
      expect(Gradebook.total_cell_warning_icon_select.size).to eq(1)
    end

    it 'should not display warning icons if group weights are turned off', priority: "1", test_id: 305579 do
      @course.apply_assignment_group_weights = false
      @course.save!
      Gradebook.visit(@course)

      expect(f("body")).not_to contain_css('.icon-warning')
    end

    it 'should display mute icon in total column if an assignment is muted' do
      Gradebook.visit(@course)
      Gradebook.toggle_assignment_muting(@assignment2.id)

      expect(Gradebook.content_selector).to contain_jqcss('.total-cell .icon-off')
    end

    it 'should not display mute icon in total column if an assignment is unmuted' do
      @assignment2.muted = true
      @assignment2.save!

      Gradebook.visit(@course)
      Gradebook.toggle_assignment_muting(@assignment2.id)

      expect(Gradebook.content_selector).not_to contain_jqcss('.total-cell .icon-off')
    end
  end
end
