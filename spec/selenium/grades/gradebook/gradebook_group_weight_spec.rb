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

describe "group weights" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  def student_totals
    totals = ff('.total-cell')
    points = []
    totals.each do |i|
      points.push(i.text)
    end
    points
  end

  def toggle_group_weight
    Gradebook.settings_cog.click
    set_group_weights.click
    group_weighting_scheme.click
    Gradebook.save_button_click
    wait_for_ajax_requests
  end

  before(:each) do
    course_with_teacher_logged_in
    student_in_course
    @course.update_attributes(group_weighting_scheme: 'percent')
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
    @course.update_attributes(group_weighting_scheme: 'points')

    # Displays total column as points
    Gradebook.visit_gradebook(@course)
    expect(student_totals).to eq(["25"])
  end

  it 'should show total column as percent' do
    @assignment1.grade_student @student, grade: 20, grader: @teacher
    @assignment2.grade_student @student, grade: 5, grader: @teacher

    @course.show_total_grade_as_points = false
    @course.update_attributes(group_weighting_scheme: 'percent')

    # Displays total column as points
    Gradebook.visit_gradebook(@course)
    expect(student_totals).to eq(["45%"])
  end

  context "warning message" do
    before(:each) do
      course_with_teacher_logged_in
      student_in_course
      @course.update_attributes(group_weighting_scheme: 'percent')
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

    it 'should display triangle warnings for assignment groups with 0 points possible', priority: "1", test_id: 164013 do

      Gradebook.visit_gradebook(@course)
      expect(ff('.icon-warning').count).to eq(2)
    end

    it 'should not display triangle warnings if group weights are turned off in gradebook', priority: "1", test_id: 305579 do

      @course.apply_assignment_group_weights = false
      @course.save!
      Gradebook.visit_gradebook(@course)
      expect(f("body")).not_to contain_css('.icon-warning')
    end

    it 'should not display triangle warnings if an assignment is muted in both header and total column' do
      Gradebook.visit_gradebook(@course)
      Gradebook.toggle_assignment_mute_option(@assignment2.id)
      expect(f("#content")).not_to contain_jqcss('.total-cell .icon-warning')
      expect(f("#content")).not_to contain_jqcss(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .icon-warning")
    end

    it 'should display triangle warnings if an assignment is unmuted in both header and total column' do
      @assignment2.muted = true
      @assignment2.save!
      Gradebook.visit_gradebook(@course)
      Gradebook.toggle_assignment_mute_option(@assignment2.id)
      expect(f('.total-cell .icon-warning')).to be_displayed
      expect(fj(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .icon-warning")).to be_displayed
      expect(f("#content")).not_to contain_jqcss(".container_1 .slick-header-column[id*='assignment_#{@assignment2.id}'] .muted")
    end
  end
end
