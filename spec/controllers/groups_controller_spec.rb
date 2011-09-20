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

describe GroupsController do

  #Delete these examples and add some real ones
  it "should use GroupsController" do
    controller.should be_an_instance_of(GroupsController)
  end
  
  describe "GET context_index" do
    it "should require authorization" do
      course_with_student
      g1 = @course.groups.create(:name => "some group", :group_category_name => "category 1")
      g2 = @course.groups.create(:name => "some other group", :group_category_name => "category 1")
      g3 = @course.groups.create(:name => "some third group", :group_category_name => "category 2")
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      g1 = @course.groups.create(:name => "some group", :group_category_name => "category 1")
      g2 = @course.groups.create(:name => "some other group", :group_category_name => "category 1")
      g3 = @course.groups.create(:name => "some third group", :group_category_name => "category 2")
      get 'index', :course_id => @course.id
      response.should be_success
      assigns[:groups].should_not be_empty
      assigns[:groups].length.should eql(3)
      (assigns[:groups] - [g1,g2,g3]).should be_empty
      assigns[:categories].length.should eql(2)
    end
  end
  
  describe "GET index" do
    it "should assign variables" do
      get 'index'
      assigns[:groups].should_not be_nil
    end
  end
  
  describe "GET show" do
    it "should require authorization" do
      @group = Group.create!(:name => "some group")
      get 'show', :id => @group.id
      assigns[:group].should eql(@group)
      assert_unauthorized
    end
    
    it "should assign variables" do
      @group = Group.create!(:name => "some group")
      @user = user_model
      user_session(@user)
      @group.add_user(@user)
      get 'show', :id => @group.id
      response.should be_success
      assigns[:group].should eql(@group)
      assigns[:context].should eql(@group)
    end
  end
  
  describe "GET new" do
    it "should require authorization" do
      @course = course_model(:reusable => true)
      @group = @course.groups.create(:name => "some group")
      get 'new', :course_id => @course.id
      assert_unauthorized
    end
  end
  
  describe "POST create_category" do
    it "should require authorization" do
      @course = course_model(:reusable => true)
      @group = @course.groups.create(:name => "some groups")
      post 'create_category', :course_id => @course.id, :category => {:name => "Study Groups", :group_count => 2}
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      @group = @course.groups.create(:name => "some groups")
      e1 = @course.enroll_student(user_model)
      e2 = @course.enroll_student(user_model)
      e3 = @course.enroll_student(user_model)
      e4 = @course.enroll_student(user_model)
      e5 = @course.enroll_student(user_model)
      e6 = @course.enroll_student(user_model)
      post 'create_category', :course_id => @course.id, :category => {:name => "Study Groups", :group_count => 2, :split_groups => '1'}
      response.should be_success
      assigns[:groups].length.should eql(2)
      assigns[:groups][0].users.length.should eql(3)
      assigns[:groups][1].users.length.should eql(3)
    end
    
    it "should give the new groups the right group_category_name" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create_category', :course_id => @course.id, :category => {:name => "Study Groups", :group_count => 1}
      response.should be_success
      assigns[:groups].length.should eql(1)
      assigns[:groups][0].group_category_name.should == "Study Groups"
    end
  end
  
  describe "DELETE delete_category" do
    it "should require authorization" do
      @course = course_model(:reusable => true)
      delete 'delete_category', :course_id => @course.id, :category_name => "Study Groups"
      assert_unauthorized
    end
    
    it "should delete groups" do
      course_with_teacher_logged_in(:active_all => true)
      @course.groups.create(:name => "some group", :group_category_name => "Study Groups")
      @course.groups.create(:name => "another group", :group_category_name => "Other Groups")
      delete 'delete_category', :course_id => @course.id, :category_name => "Study Groups"
      response.should be_success
      @course.reload
      @course.groups.length.should eql(2)
      @course.groups.active.length.should eql(1)
    end
  end
  
  describe "POST add_user" do
    it "should require authorization" do
      @group = Group.create(:name => "some group")
      post 'add_user', :group_id => @group.id
      assert_unauthorized
    end
    
    it "should add user" do
      @group = Group.create(:name => "some group")
      @user = user(:active_all => true)
      @group.add_user(@user)
      user_session(@user)
      @user = user(:active_all => true)
      post 'add_user', :group_id => @group.id, :user_id => @user.id
      response.should be_success
      assigns[:membership].should_not be_nil
      assigns[:membership].user.should eql(@user)
    end
  end
  
  describe "DELETE remove_user" do
    it "should require authorization" do
      @group = Group.create(:name => "some group")
      @user = user(:active_all => true)
      @group.add_user(@user)
      delete 'remove_user', :group_id => @group.id, :user_id => @user.id
      assert_unauthorized
    end
    
    it "should remove user" do
      @group = Group.create(:name => "some group")
      @user = user(:active_all => true)
      user_session(@user)
      @group.add_user(@user)
      delete 'remove_user', :group_id => @group.id, :user_id => @user.id
      response.should be_success
      @group.reload
      @group.users.should be_empty
    end
  end
  
  describe "POST create" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should create new group" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :group => {:name => "some group"}
      response.should be_redirect
      assigns[:group].should_not be_nil
      assigns[:group].name.should eql("some group")
    end

    it "should honor group[group_category_name] when permitted" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :group => {:name => "some group", :group_category_name => "some category"}
      response.should be_redirect
      assigns[:group].should_not be_nil
      assigns[:group].group_category_name.should eql("some category")
    end

    it "should not honor group[group_category_name] when not permitted" do
      course_with_student_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :group => {:name => "some group", :group_category_name => "some category"}
      response.should be_redirect
      assigns[:group].should_not be_nil
      assigns[:group].group_category_name.should eql("Student Groups")
    end
  end
  
  describe "GET edit" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      get 'edit', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      get 'edit', :course_id => @course.id, :id => @group.id
      assigns[:group].should eql(@group)
    end
  end
  
  describe "PUT update" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => "new name"}
      assert_unauthorized
    end
    
    it "should update group" do
      course_with_teacher_logged_in(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => "new name"}
      response.should be_redirect
      assigns[:group].should eql(@group)
      assigns[:group].name.should eql("new name")
    end
  end
  
  describe "DELETE destroy" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end
    
    it "should delete group" do
      course_with_teacher_logged_in(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assigns[:group].should eql(@group)
      assigns[:group].should_not be_frozen
      assigns[:group].should be_deleted
      @course.groups.should be_include(@group)
      @course.groups.active.should_not be_include(@group)
    end
  end
  
  describe "GET 'unassigned_members'" do
    it "should include all users if the category is student organized" do
      course_with_teacher_logged_in(:active_all => true)
      u1 = @course.enroll_student(user_model).user
      u2 = @course.enroll_student(user_model).user
      u3 = @course.enroll_student(user_model).user

      group = @course.groups.create(:name => "Group 1", :group_category_name => "Student Groups")
      group.add_user(u1)
      group.add_user(u2)

      get 'unassigned_members', :course_id => @course.id, :category => group.group_category_name
      response.should be_success
      data = JSON.parse(response.body) rescue nil
      data.should_not be_nil
      data['users'].map{ |u| u['user_id'] }.sort.
        should == [u1, u2, u3].map{ |u| u.id }.sort
    end

    it "should include only users not in a group in the category otherwise" do
      course_with_teacher_logged_in(:active_all => true)
      u1 = @course.enroll_student(user_model).user
      u2 = @course.enroll_student(user_model).user
      u3 = @course.enroll_student(user_model).user

      group1 = @course.groups.create(:name => "Group 1", :group_category_name => "Group Category 1")
      group1.add_user(u1)

      group2 = @course.groups.create(:name => "Group 1", :group_category_name => "Group Category 2")
      group2.add_user(u2)

      group3 = @course.groups.create(:name => "Group 1", :group_category_name => "Group Category 3")
      group3.add_user(u2)
      group3.add_user(u3)

      get 'unassigned_members', :course_id => @course.id, :category => group1.group_category_name
      response.should be_success
      data = JSON.parse(response.body) rescue nil
      data.should_not be_nil
      data['users'].map{ |u| u['user_id'] }.sort.
        should == [u2, u3].map{ |u| u.id }.sort

      get 'unassigned_members', :course_id => @course.id, :category => group2.group_category_name
      response.should be_success
      data = JSON.parse(response.body) rescue nil
      data.should_not be_nil
      data['users'].map{ |u| u['user_id'] }.sort.
        should == [u1, u3].map{ |u| u.id }.sort

      get 'unassigned_members', :course_id => @course.id, :category => group3.group_category_name
      response.should be_success
      data = JSON.parse(response.body) rescue nil
      data.should_not be_nil
      data['users'].map{ |u| u['user_id'] }.should == [ u1.id ]
    end
  end


  # describe "GET 'index'" do
  #   it "should be successful" do
  #     get 'index'
  #     # response.should be_success
  #   end
  # end
  # 
  # describe "GET 'show'" do
  #   it "should be successful" do
  #     get 'show'
  #     # response.should be_success
  #   end
  # end
  # 
  # describe "GET 'new'" do
  #   it "should be successful" do
  #     get 'new'
  #     # response.should be_success
  #   end
  # end
  # 
  # describe "GET 'edit'" do
  #   it "should be successful" do
  #     get 'edit'
  #     # response.should be_success
  #   end
  # end
  # 
  # describe "GET 'destroy'" do
  #   it "should be successful" do
  #     params[:id] = 1
  #     params[:course_id] = 1
  #     @group = mock_model(Group)
  #     @group.should_receive(:destroy).and_return true
  #     @context = mock_model(Course)
  #     @context.stub!(:groups).and_return(@group)
  #     Course.stub!(:find).and_return(@course)
  #     get 'destroy', :id => 1, :course_id => 1
  #     # response.should be_success
  #   end
  # end
end
