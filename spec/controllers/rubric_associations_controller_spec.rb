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

describe RubricAssociationsController do
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      post 'create', :course_id => @course.id, :rubric_association => {:rubric_id => @rubric.id}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      post 'create', :course_id => @course.id, :rubric_association => {:rubric_id => @rubric.id, :title => "some association", :association_type => @rubric_association.association.class.name, :association_id => @rubric_association.association.id}
      assigns[:association].should_not be_nil
      assigns[:association].title.should eql("some association")
      response.should be_success
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric_association.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric_association.id, :rubric_association => {:title => "some association"}
      assigns[:association].should_not be_nil
      assigns[:association].title.should eql("some association")
      response.should be_success
    end
    it "should update the rubric if updateable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric_association.id, :rubric => {:title => "new title"}, :rubric_association => {:title => "some association"}
      assigns[:rubric].should_not be_nil
      assigns[:rubric].title.should eql("new title")
      assigns[:association].should_not be_nil
      assigns[:association].title.should eql("some association")
      response.should be_success
    end
    it "should not update the rubric if not updateable (should make a new one instead)" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      put 'update', :course_id => @course.id, :id => @rubric_association.id, :rubric => {:title => "new title"}, :rubric_association => {:title => "some association"}
      assigns[:rubric].should_not be_nil
      assigns[:rubric].title.should_not eql("new title")
      assigns[:association].should_not be_nil
      assigns[:association].title.should eql("some association")
      response.should be_success
    end
    it "should update the association" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric_association.id, :rubric_association => {:title => "some association"}
      assigns[:association].should_not be_nil
      assigns[:association].title.should eql("some association")
      response.should be_success
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :id => @rubric_association.id
      assert_unauthorized
    end
    it "should delete the rubric if deletable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :id => @rubric_association.id
      response.should be_success
      assigns[:association].should_not be_nil
      assigns[:association].should be_frozen
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should be_deleted
    end
    it "should_not delete the rubric if still created at the context level instead of the assignment level" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', :course_id => @course.id, :id => @rubric_association.id
      response.should be_success
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should_not be_deleted
      assigns[:rubric].should_not be_frozen
      assigns[:association].should_not be_nil
      assigns[:association].should be_frozen
    end
    it "should delete only the association if the rubric is not deletable" do
      rubric_association_model
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :rubric => @rubric, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', :course_id => @course.id, :id => @rubric_association.id
      response.should be_success
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should_not be_deleted
      assigns[:rubric].should_not be_frozen
      assigns[:association].should_not be_nil
      assigns[:association].should be_frozen
    end
  end
end
