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

describe SubmissionsController do
  describe "POST create" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      assert_unauthorized
    end
    
    it "should allow submitting homework" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_url", :url => "url"}
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].user_id.should eql(@user.id)
      assigns[:submission].assignment_id.should eql(@assignment.id)
      assigns[:submission].submission_type.should eql("online_url")
      assigns[:submission].url.should eql("http://url")
    end
    
    it "should allow attaching multiple files to the submission" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data1 = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/doc.doc"), "application/msword", true)
      data2 = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/xls.xls"), "application/vnd.ms-excel", true)
      post 'create', :course_id => @course.id, :assignment_id => @assignment.id, :submission => {:submission_type => "online_upload"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].user_id.should eql(@user.id)
      assigns[:submission].assignment_id.should eql(@assignment.id)
      assigns[:submission].submission_type.should eql("online_upload")
      assigns[:submission].attachments.should_not be_empty
      assigns[:submission].attachments.length.should eql(2)
      assigns[:submission].attachments.map{|a| a.display_name}.should be_include("doc.doc")
      assigns[:submission].attachments.map{|a| a.display_name}.should be_include("xls.xls")
    end
  end
  
  describe "PUT update" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}
      assert_unauthorized
    end
    
    it "should require the right student" do
      course_with_student_logged_in(:active_all => true)
      @user2 = User.create!(:name => "some user")
      @course.enroll_user(@user2)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user2)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user2.id, :submission => {:comment => "some comment"}
      assert_unauthorized
    end
    
    it "should allow updating homework to add comments" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
    end
    
    it "should allow attaching comments to the comment" do
      course_with_student_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data1 = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/doc.doc"), "application/msword", true)
      data2 = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/xls.xls"), "application/vnd.ms-excel", true)
      put 'update', :course_id => @course.id, :assignment_id => @assignment.id, :id => @user.id, :submission => {:comment => "some comment"}, :attachments => {"0" => {:uploaded_data => data1}, "1" => {:uploaded_data => data2}}
      response.should be_redirect
      assigns[:submission].should eql(@submission)
      assigns[:submission].submission_comments.length.should eql(1)
      assigns[:submission].submission_comments[0].comment.should eql("some comment")
      assigns[:submission].submission_comments[0].attachments.length.should eql(2)
      assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}.should be_include("doc.doc")
      assigns[:submission].submission_comments[0].attachments.map{|a| a.display_name}.should be_include("xls.xls")
    end
    
  end
end
  
