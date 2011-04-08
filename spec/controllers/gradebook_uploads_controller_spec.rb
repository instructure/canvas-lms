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

describe GradebookUploadsController do

  describe "POST 'create'" do
    it "should require authorization" do
      course_model
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect on failed csvs" do
      course_with_teacher_logged_in(:active_all => true)
      file = Tempfile.new("csv.csv")
      file.puts("not a good csv")
      file.close
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data = ActionController::TestUploadedFile.new(file.path, 'text/csv', true)
      post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
      response.should be_redirect
    end
    
    it "should accept a valid csv upload" do
      course_with_student(:active_all => true)
      @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment.grade_student(@user, :grade => "10")
      @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
      @assignment2.grade_student(@user, :grade => "8")
      @course.recompute_student_scores
      @user.reload
      @course.reload
      user_model
      @course.enroll_teacher(@user).accept
      user_session(@user)
      file = Tempfile.new("csv.csv")
      file.puts(@course.gradebook_to_csv)
      file.close
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data = ActionController::TestUploadedFile.new(file.path, 'text/csv', true)
      post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
      response.should be_success
      upload = assigns[:uploaded_gradebook]
      upload.assignments.length.should eql(2)
      upload.assignments[0].should eql(@assignment)
      upload.assignments[1].should eql(@assignment2)
      upload.students.length.should eql(1)
    end
    
    it "should accept a valid csv upload with a final grade column" do
      course_with_student(:active_all => true)
      @course.grading_standard_id = 0
      @course.save!
      @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment.grade_student(@user, :grade => "10")
      @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
      @assignment2.grade_student(@user, :grade => "8")
      @course.recompute_student_scores
      @user.reload
      @course.reload
      user_model
      @course.enroll_teacher(@user).accept
      user_session(@user)
      file = Tempfile.new("csv.csv")
      file.puts(@course.gradebook_to_csv)
      file.close
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data = ActionController::TestUploadedFile.new(file.path, 'text/csv', true)
      post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
      response.should be_success
      upload = assigns[:uploaded_gradebook]
      upload.assignments.length.should eql(2)
      upload.assignments[0].should eql(@assignment)
      upload.assignments[1].should eql(@assignment2)
      upload.students.length.should eql(1)
    end
  end
end
