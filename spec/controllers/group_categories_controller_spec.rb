#
# Copyright (C) 2013 Instructure, Inc.
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

describe GroupCategoriesController do

  describe "POST create" do
    it "should require authorization" do
      @course = course_model(:reusable => true)
      @group = @course.groups.create(:name => "some groups")
      post 'create', :course_id => @course.id, :category => {}
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
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :split_group_count => 2, :split_groups => '1'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      groups = assigns[:group_category].groups
      groups.length.should eql(2)
      groups[0].users.length.should eql(3)
      groups[1].users.length.should eql(3)
    end

    it "should give the new groups the right group_category" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :split_group_count => 1, :split_groups => '1'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      assigns[:group_category].groups[0].group_category.name.should == "Study Groups"
    end

    it "should error if the group name is protected" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :category => {:name => "Student Groups"}
      response.should_not be_success
    end

    it "should error if the group name is already in use" do
      course_with_teacher_logged_in(:active_all => true)
      @course.group_categories.create(:name => "My Category")
      post 'create', :course_id => @course.id, :category => {:name => "My Category"}
      response.should_not be_success
    end

    it "should default an empty or missing name to 'Study Groups'" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :category => {}
      response.should be_success
      assigns[:group_category].name.should == "Study Groups"
      assigns[:group_category].destroy

      post 'create', :course_id => @course.id, :category => {:name => ''}
      response.should be_success
      assigns[:group_category].name.should == "Study Groups"
    end

    it "should respect enable_self_signup" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      assigns[:group_category].should be_self_signup
      assigns[:group_category].should be_unrestricted_self_signup
    end

    it "should use create_group_count when self-signup" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_group_count => '3'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      assigns[:group_category].groups.size.should == 3
    end

    it "should respect the max new-category group count" do
      course_with_teacher_logged_in(:active_all => true)
      Setting.set('max_groups_in_new_category', '5')
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_group_count => '7'}
      response.should be_success
      assigns[:group_category].groups.size.should == 5
    end

    it "should not distribute students when self-signup" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      student_in_course
      student_in_course
      student_in_course
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_category_count => '2'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      assigns[:group_category].groups.all?{ |g| g.users.should be_empty }
    end

    it "should respect restrict_self_signup" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :restrict_self_signup => '1'}
      response.should be_success
      assigns[:group_category].should_not be_nil
      assigns[:group_category].should be_restricted_self_signup
    end

    it "should work when the context is an account and not enable_self_signup and split_groups" do
      user = account_admin_user
      user_session(user)
      post 'create', :account_id => Account.default, :category => {:name => "Study Groups", :split_group_count => 1, :split_groups => '1'}
      response.should be_success
      assigns[:group_category].should_not be_nil
    end
  end

  describe "PUT update" do
    before :each do
      course_with_teacher(:active_all => true)
      @group_category = @course.group_categories.create(:name => "My Category")
    end

    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {}
      assert_unauthorized
    end

    it "should update category" do
      user_session(@user)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Different Category", :enable_self_signup => "1"}
      response.should be_success
      assigns[:group_category].should eql(@group_category)
      assigns[:group_category].name.should eql("Different Category")
      assigns[:group_category].should be_self_signup
    end

    it "should leave the name alone if not given" do
      user_session(@user)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {}
      response.should be_success
      assigns[:group_category].name.should == "My Category"
    end

    it "should treat a sent but empty name as 'Study Groups'" do
      user_session(@user)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => ''}
      response.should be_success
      assigns[:group_category].name.should == "Study Groups"
    end

    it "should error if the name is protected" do
      user_session(@user)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Student Groups"}
      response.should_not be_success
    end

    it "should error if the name is already in use" do
      user_session(@user)
      @course.group_categories.create(:name => "Other Category")
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Other Category"}
      response.should_not be_success
    end

    it "should not error if the name is the current name" do
      user_session(@user)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "My Category"}
      response.should be_success
      assigns[:group_category].name.should eql("My Category")
    end

    it "should error if restrict_self_signups is specified but the category has heterogenous groups" do
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @group_category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)

      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:enable_self_signup => '1', :restrict_self_signup => '1'}
      response.should_not be_success
    end
  end

  describe "DELETE delete" do
    it "should require authorization" do
      @course = course_model(:reusable => true)
      group_category = @course.group_categories.create(:name => "Study Groups")
      delete 'destroy', :course_id => @course.id, :id => group_category.id
      assert_unauthorized
    end

    it "should delete the category and groups" do
      course_with_teacher_logged_in(:active_all => true)
      category1 = @course.group_categories.create(:name => "Study Groups")
      category2 = @course.group_categories.create(:name => "Other Groups")
      @course.groups.create(:name => "some group", :group_category => category1)
      @course.groups.create(:name => "another group", :group_category => category2)
      delete 'destroy', :course_id => @course.id, :id => category1.id
      response.should be_success
      @course.reload
      @course.all_group_categories.length.should eql(2)
      @course.group_categories.length.should eql(1)
      @course.groups.length.should eql(2)
      @course.groups.active.length.should eql(1)
    end

    it "should fail if category doesn't exist" do
      course_with_teacher_logged_in(:active_all => true)
      delete 'destroy', :course_id => @course.id, :id => 11235
      response.should_not be_success
    end

    it "should fail if category is protected" do
      course_with_teacher_logged_in(:active_all => true)
      delete 'destroy', :course_id => @course.id, :id => GroupCategory.student_organized_for(@course).id
      response.should_not be_success
    end
  end

end