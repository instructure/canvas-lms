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
      response.should be_redirect
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

  describe "POST 'update'" do
    before :each do
      user_session(@teacher)
    end

    it "should update grades and save new versions" do
      @assignment.reload
      @assignment2.reload
      @assignment.submissions.first.grade.should == '10'
      @assignment2.submissions.first.grade.should == '8'

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Some Assignment", "Some Assignment 2"]
        csv << ["    Points Possible", "", "","", ""]
        csv << ["" , @student.id.to_s, "", "", "", 5, 7]
      end

      @gi = GradebookImporter.new(@course, uploaded_csv)
      @gi.parse!
      post 'update', :course_id => @course.id, :json_data_to_submit => @gi.to_json

      a_sub = @assignment.reload.submissions.first
      a2_sub = @assignment2.reload.submissions.first
      a_sub.grade.should == '5'
      a_sub.graded_at.should_not be_nil
      a_sub.grader_id.should_not be_nil
      a_sub.version_number.should == 2
      a2_sub.grade.should == '7'
      a2_sub.graded_at.should_not be_nil
      a2_sub.grader_id.should_not be_nil
      a2_sub.version_number.should == 2

      response.should redirect_to(course_gradebook_url(@course))
    end

    it "should create new assignments" do
      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Some Assignment", "Some Assignment 2", "Third Assignment"]
        csv << ["    Points Possible", "", "","", "", "", "", "15"]
        csv << ["" , @student.id.to_s, "", "", "", 5, 7, 10]
      end

      @gi = GradebookImporter.new(@course, uploaded_csv)
      @gi.parse!
      post 'update', :course_id => @course.id, :json_data_to_submit => @gi.to_json

      a = @course.assignments.find_by_title("Third Assignment")
      a.should_not be_nil
      a.title.should == "Third Assignment"
      a.points_possible.should == 15
      a.submissions.first.grade.should == '10'
    end


  end

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
    response.should be_success
    upload = assigns[:uploaded_gradebook]
    upload.should_not be_nil
  end

  describe "POST 'update'" do

    it "should allow entering a percentage for a score" do
      @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :grading_type => 'percent', :assignment_group => @group)
      user_session(@teacher)
      uploaded_json = <<-JSON
      {
        "students": [{
          "previous_id": #{@student.id},
          "name": "#{@student.name}",
          "submissions": [{
            "grade": "40%",
            "assignment_id": #{@assignment.id}
          }],
          "id": #{@student.id},
          "last_name_first": "#{@student.last_name_first}"
        }],
        "assignments": [{
          "previous_id": #{@assignment.id},
          "title": "#{@assignment.title}",
          "id": #{@assignment.id},
          "points_possible": #{@assignment.points_possible},
          "grading_type": "#{@assignment.grading_type}"
        }]
      }
      JSON
      post 'update', :course_id => @course.id, :json_data_to_submit => uploaded_json
      @submission = @assignment.reload.submissions.find_by_user_id(@student.id)
      @submission.grade.should == "40%"
      @submission.score.should == 4
    end

  end
end
