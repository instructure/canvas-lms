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
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
  end

  describe "POST create" do
    it "should require authorization" do
      @group = @course.groups.create(:name => "some groups")
      post 'create', :course_id => @course.id, :category => {}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      @group = @course.groups.create(:name => "some groups")
      create_users_in_course(@course, 5) # plus one student in before block
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :split_group_count => 2, :split_groups => '1'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      groups = assigns[:group_category].groups
      expect(groups.length).to eql(2)
      expect(groups[0].users.length).to eql(3)
      expect(groups[1].users.length).to eql(3)
    end

    it "should give the new groups the right group_category" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :split_group_count => 1, :split_groups => '1'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].groups[0].group_category.name).to eq "Study Groups"
    end

    it "should error if the group name is protected" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Student Groups"}
      expect(response).not_to be_success
    end

    it "should error if the group name is already in use" do
      user_session(@teacher)
      @course.group_categories.create(:name => "My Category")
      post 'create', :course_id => @course.id, :category => {:name => "My Category"}
      expect(response).not_to be_success
    end

    it "should require the group name" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {}
      expect(response).not_to be_success
    end

    it "should respect enable_self_signup" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category]).to be_self_signup
      expect(assigns[:group_category]).to be_unrestricted_self_signup
    end

    it "should use create_group_count when self-signup" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_group_count => '3'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].groups.size).to eq 3
    end

    it "respects auto_leader params" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_auto_leader => '1', :auto_leader_type => 'RANDOM'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].auto_leader).to eq 'random'
    end

    it "should respect the max new-category group count" do
      user_session(@teacher)
      Setting.set('max_groups_in_new_category', '5')
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_group_count => '7'}
      expect(response).to be_success
      expect(assigns[:group_category].groups.size).to eq 5
    end

    it "should not distribute students when self-signup" do
      user_session(@teacher)
      create_users_in_course(@course, 3)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :create_category_count => '2'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      assigns[:group_category].groups.all?{ |g| expect(g.users).to be_empty }
    end

    it "should respect restrict_self_signup" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :category => {:name => "Study Groups", :enable_self_signup => '1', :restrict_self_signup => '1'}
      expect(response).to be_success
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category]).to be_restricted_self_signup
    end
  end

  describe "PUT update" do
    before :once do
      @group_category = @course.group_categories.create(:name => "My Category")
    end

    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {}
      assert_unauthorized
    end

    it "should update category" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Different Category", :enable_self_signup => "1"}
      expect(response).to be_success
      expect(assigns[:group_category]).to eql(@group_category)
      expect(assigns[:group_category].name).to eql("Different Category")
      expect(assigns[:group_category]).to be_self_signup
    end

    it "should leave the name alone if not given" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {}
      expect(response).to be_success
      expect(assigns[:group_category].name).to eq "My Category"
    end

    it "should not accept a sent but empty name" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => ''}
      expect(response).not_to be_success
    end

    it "should error if the name is protected" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Student Groups"}
      expect(response).not_to be_success
    end

    it "should error if the name is already in use" do
      user_session(@teacher)
      @course.group_categories.create(:name => "Other Category")
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "Other Category"}
      expect(response).not_to be_success
    end

    it "should not error if the name is the current name" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group_category.id, :category => {:name => "My Category"}
      expect(response).to be_success
      expect(assigns[:group_category].name).to eql("My Category")
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
      expect(response).not_to be_success
    end
  end

  describe "DELETE delete" do
    it "should require authorization" do
      group_category = @course.group_categories.create(:name => "Study Groups")
      delete 'destroy', :course_id => @course.id, :id => group_category.id
      assert_unauthorized
    end

    it "should delete the category and groups" do
      user_session(@teacher)
      category1 = @course.group_categories.create(:name => "Study Groups")
      category2 = @course.group_categories.create(:name => "Other Groups")
      @course.groups.create(:name => "some group", :group_category => category1)
      @course.groups.create(:name => "another group", :group_category => category2)
      delete 'destroy', :course_id => @course.id, :id => category1.id
      expect(response).to be_success
      @course.reload
      expect(@course.all_group_categories.length).to eql(2)
      expect(@course.group_categories.length).to eql(1)
      expect(@course.groups.length).to eql(2)
      expect(@course.groups.active.length).to eql(1)
    end

    it "should fail if category doesn't exist" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => 11235
      expect(response).not_to be_success
    end

    it "should fail if category is protected" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => GroupCategory.student_organized_for(@course).id
      expect(response).not_to be_success
    end
  end

end
