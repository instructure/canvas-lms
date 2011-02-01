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

describe GradebooksController do

  it "should use GradebooksController" do
    controller.should be_an_instance_of(GradebooksController)
  end

  describe "GET 'index'" do
    before(:each) do
      Course.should_receive(:find).and_return(['a course'])
    end

  end

  describe "GET 'show'" do
    before(:each) do
      @assignments = [mock_model(Assignment)]
      @assignment_sumbissions = [mock_model(Submission)]
      @students = [mock_model(User)]
      @course = mock_model(Course)
      @course.should_receive(:submissions).and_return(@submissions)
      @course.should_receive(:assignments).and_return(@assignments)
      @course.should_receive(:students).and_return(@students)
      Course.should_receive(:find).and_return(@course)
    end
  end
  
  describe "POST 'update_submission'" do
    
    it "should have a route for update_submission" do
      params_from(:post, "/courses/20/gradebook/update_submission").should == 
        {:controller => "gradebooks", :action => "update_submission", :course_id => "20"}
    end
    
    it "should allow adding comments for submission" do
      course_with_teacher_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      response.should be_redirect
      assigns[:assignment].should eql(@assignment)
      assigns[:submissions].should_not be_nil
      assigns[:submissions].length.should eql(1)
      assigns[:submissions][0].submission_comments.should_not be_nil
      assigns[:submissions][0].submission_comments[0].comment.should eql("some comment")
    end
    
    it "should allow attaching files to comments for submission" do
      course_with_teacher_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/doc.doc"), "application/msword", true)
      post 'update_submission', :course_id => @course.id, :attachments => {"0" => {:uploaded_data => data}}, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      response.should be_redirect
      assigns[:assignment].should eql(@assignment)
      assigns[:submissions].should_not be_nil
      assigns[:submissions].length.should eql(1)
      assigns[:submissions][0].submission_comments.should_not be_nil
      assigns[:submissions][0].submission_comments[0].comment.should eql("some comment")
      assigns[:submissions][0].submission_comments[0].attachments.length.should eql(1)
      assigns[:submissions][0].submission_comments[0].attachments[0].display_name.should eql("doc.doc")
    end
  end
  
  describe "GET 'speed_grader'" do
    it "should have a route for speed_grader" do
      params_from(:get, "/courses/20/gradebook/speed_grader").should == 
        {:controller => "gradebooks", :action => "speed_grader", :course_id => "20"}
    end
    
  end
  
end
