#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'csv'

describe GradebookUploadsController do
  def course_with_graded_student
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @assignment2.grade_student(@user, :grade => "8")
    @course.recompute_student_scores
    @user.reload
    @course.reload
  end

  def check_create_response(include_sis_id=false)
    file = Tempfile.new("csv.csv")
    file.puts(@course.gradebook_to_csv(:include_sis_id => include_sis_id))
    file.close
    data = Rack::Test::UploadedFile.new(file.path, 'text/csv', true)
    post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
    expect(response).to be_success
    upload = assigns[:uploaded_gradebook]
    expect(upload).not_to be_nil
  end

  def setup_DA
    @course_section = @course.course_sections.create
    @student1, @student2, @student3 = create_users(3, return_type: :record)
    @assignment.only_visible_to_overrides = true
    @assignment.save
    @course.enroll_student(@student3, :enrollment_state => 'active')
    @section = @course.course_sections.create!(name: "test section")
    @section2 = @course.course_sections.create!(name: "second test section")
    student_in_section(@section, user: @student1)
    student_in_section(@section2, user: @student2)
    create_section_override_for_assignment(@assignment, {course_section: @section})
    @assignment2.only_visible_to_overrides = true
    @assignment2.save
    create_section_override_for_assignment(@assignment2, {course_section: @section2})
    @course.reload
    @assignment.reload
    @assignment2.reload
  end

  before :once do
    course_with_teacher active_all: true
    student_in_course active_all: true
    course_with_graded_student
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect on failed csvs" do
      user_session(@teacher)
      file = Tempfile.new("csv.csv")
      file.puts("not a good csv")
      file.close
      data = Rack::Test::UploadedFile.new(file.path, 'text/csv', true)
      post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
      expect(response).to be_redirect
    end

    it "should accept a valid csv upload" do
      user_session(@teacher)
      check_create_response
    end

    it "should accept a valid csv upload with a final grade column" do
      user_session(@teacher)
      @course.grading_standard_id = 0
      @course.save!
      check_create_response
    end

    it "should accept a valid csv upload with sis id columns" do
      user_session(@teacher)
      @course.grading_standard_id = 0
      @course.save!
      check_create_response(true)
    end
  end
end
