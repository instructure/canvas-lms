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
  
  describe "GET 'grade_summary'" do
    it "should redirect teacher to gradebook" do
      course_with_teacher_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id
      response.should be_redirect
      response.should redirect_to(:action => 'show')
    end
    
    it "should render for current user" do
      course_with_student_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id
      response.should render_template('grade_summary')
      get 'grade_summary', :course_id => @course.id, :id => @user.id
      response.should render_template('grade_summary')
    end
    
    it "should not allow access for wrong user" do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      user_session(@user)
      get 'grade_summary', :course_id => @course.id
      assert_unauthorized
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assert_unauthorized
    end
    
    it" should allow access for a linked observer" do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      user_session(@user)
      @oe = @course.enroll_user(@user, 'ObserverEnrollment')
      @oe.accept
      @oe.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      response.should render_template('grade_summary')
    end
    
    it "should allow concluded teachers to see a student grades pages" do
      course_with_teacher_logged_in(:active_all => true)
      @enrollment.conclude
      @student = user_model
      @enrollment = @course.enroll_student(@student)
      @enrollment.accept
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      response.should be_success
      response.should render_template('grade_summary')
    end
  
    it "should allow concluded students to see their grades pages" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.conclude
      get 'grade_summary', :course_id => @course.id, :id => @user.id
      response.should render_template('grade_summary')
    end
  end

  describe "GET 'show'" do
    describe "gradebook_init_json" do
      it "should include group_category_name in rendered json for assignments" do
        course_with_teacher_logged_in(:active_all => true)
        assignment1 = @course.assignments.create(:title => "Assignment 1", :group_category_name => 'Category 1')
        assignment2 = @course.assignments.create(:title => "Assignment 2", :group_category_name => 'Category 2')
        get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'json'
        response.should be_success
        data = JSON.parse(response.body) rescue nil
        data.should_not be_nil
        data.size.should == 3 # 2 assignments + a total
        data.first(2).sort_by{ |a| a['assignment']['title'] }.map{ |a| a['assignment']['group_category_name'] }.
          should == [assignment1, assignment2].map{ |a| a.group_category_name }
      end
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
    
    it "should not allow updating submissions for concluded courses" do
      course_with_teacher_logged_in(:active_all => true)
      @enrollment.complete
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      assert_unauthorized
    end
  end
  
  describe "GET 'speed_grader'" do
    it "should have a route for speed_grader" do
      params_from(:get, "/courses/20/gradebook/speed_grader").should == 
        {:controller => "gradebooks", :action => "speed_grader", :course_id => "20"}
    end
    
  end
  
end
