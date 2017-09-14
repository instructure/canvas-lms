#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/assignments_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  def point_validation
    assignment_name = 'first test assignment'
    @assignment = @course.assignments.create({
                    :name => assignment_name,
                    :assignment_group => @course.assignment_groups.create!(:name => "default")
                  })

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
    yield if block_given?
    f('.btn-primary[type=submit]').click
    wait_for_ajaximations
    expect(f('.errorBox:not(#error_box_template)')).to include_text("Points possible must be 0 or more for selected grading type")
  end

  before(:each) do
    course_with_teacher_logged_in
    enable_all_rcs @course.account
    stub_rcs_config
  end

  %w(points percent pass_fail letter_grade gpa_scale).each do |grading_option|
    it "should create assignment with #{grading_option} grading option", priority: "2", test_id: 209976 do
      assignment_title = 'grading options assignment'
      manually_create_assignment(assignment_title)
      wait_for_ajaximations
      click_option('#assignment_grading_type', grading_option, :value)
      if grading_option == "percent"
        replace_content f('#assignment_points_possible'), ('1')
      end
      click_option('#assignment_submission_type', 'No Submission')
      assignment_points_possible = f("#assignment_points_possible")
      replace_content(assignment_points_possible, "5")
      submit_assignment_form
      expect(f('.title')).to include_text(assignment_title)
      expect(Assignment.find_by_title(assignment_title).grading_type).to eq grading_option
    end
  end

  it "should validate points for percentage grading (!= '')", priority: "2", test_id: 209980 do
    point_validation {
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for percentage grading (digits only)", priority: "2", test_id: 209984  do
    point_validation {
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end

  it "should validate points for letter grading (!= '')", priority: "2", test_id:209985 do
    point_validation {
      click_option('#assignment_grading_type', 'Letter Grade')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for letter grading (digits only)", priority: "2", test_id: 209986 do
    point_validation {
      click_option('#assignment_grading_type', 'Letter Grade')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end

  it "should validate points for GPA scale grading (!= '')", priority: "2", test_id: 209988 do
    point_validation {
      click_option('#assignment_grading_type', 'GPA Scale')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for GPA scale grading (digits only)", priority: "2", test_id: 209980 do
    point_validation {
      click_option('#assignment_grading_type', 'GPA Scale')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end
end
