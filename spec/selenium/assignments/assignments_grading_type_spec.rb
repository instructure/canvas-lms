#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/assignments_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  def point_validation(assignment=nil)
    @assignment = assignment ||
      @course.assignments.create!(
        name: 'first test assignment',
        assignment_group: @course.assignment_groups.create!(name: 'default')
      )

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
    yield if block_given?
    f('.btn-primary[type=submit]').click
    wait_for_ajaximations
    expect(f('.errorBox:not(#error_box_template)')).
      to include_text('Points possible must be 0 or more for selected grading type')
  end

  context 'with points' do
    before(:each) do
      course_with_teacher_logged_in
    end

    it 'should validate points for percentage grading (!= '')', priority: '2', test_id: 209980 do
      point_validation do
        click_option('#assignment_grading_type', 'Percentage')
        replace_content f('#assignment_points_possible'), ''
      end
    end

    it 'should validate points for percentage grading (digits only)', priority: '2', test_id: 209984 do
      point_validation do
        click_option('#assignment_grading_type', 'Percentage')
        replace_content f('#assignment_points_possible'), 'taco'
      end
    end

    it 'should validate points for letter grading (!= '')', priority: '2', test_id:209985 do
      point_validation do
        click_option('#assignment_grading_type', 'Letter Grade')
        replace_content f('#assignment_points_possible'), ''
      end
    end

    it 'should validate points for letter grading (digits only)', priority: '2', test_id: 209986 do
      point_validation do
        click_option('#assignment_grading_type', 'Letter Grade')
        replace_content f('#assignment_points_possible'), 'taco'
      end
    end
  end

  context 'with assignment creation' do
    before(:each) do
      course_with_teacher_logged_in
      @assignment_title = 'grading options assignment'
      manually_create_assignment(@assignment_title)
    end

    %w(points percent pass_fail letter_grade gpa_scale).each do |grading_option|
      it "can create an assignment with #{grading_option} grading option", priority: '2', test_id: 209976 do
        click_option('#assignment_grading_type', grading_option, :value)
        replace_content(f('#assignment_points_possible'), '5')
        click_option('#assignment_submission_type', 'No Submission')
        f('#edit_assignment_form .btn-primary[type=submit]').click
        wait_for_ajaximations
        expect(f('.title')).to include_text @assignment_title
        expect(Assignment.find_by(title: @assignment_title).grading_type).to eq grading_option
      end
    end
  end

  context 'with GPA Scale Assignments' do
    before(:each) do
      course_with_teacher_logged_in
    end

    let(:assignment) do
      # The 'GPA Scale' option is only available in the UI if the assignment is already of type
      # 'gpa_scale'. Therefore, we create the assignment here with type 'gpa_scale' so that the
      # 'GPA Scale' option is available when we go to edit the assignment
      @course.assignments.create!(
        assignment_group: @course.assignment_groups.create!(name: 'default'),
        grading_type: 'gpa_scale',
        name: 'first test assignment'
      )
    end

    it 'validates points for GPA scale grading (!= '')', priority: '2', test_id: 209988 do
      point_validation(assignment) do
        click_option('#assignment_grading_type', 'GPA Scale')
        replace_content f('#assignment_points_possible'), ''
      end
    end

    it 'validates points for GPA scale grading (digits only)', priority: '2', test_id: 209980 do
      point_validation(assignment) do
        click_option('#assignment_grading_type', 'GPA Scale')
        replace_content f('#assignment_points_possible'), 'taco'
      end
    end

    it "shows 'GPA Scale' option if the assignment's type is GPA Scale", priority: '1', test_id: 3431684 do
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      expect(f('#assignment_grading_type')).to contain_css('option[value="gpa_scale"]')
    end

    it "shows 'GPA Scale' option if the assignment's type is not GPA Scale", priority: '2', test_id: 3431685 do
      assignment.update!(grading_type: 'points')
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      expect(f('#assignment_grading_type')).to contain_css('option[value="gpa_scale"]')
    end
  end
end
