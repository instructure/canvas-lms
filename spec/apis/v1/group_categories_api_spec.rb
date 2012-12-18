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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe "Group Categories API", :type => :integration do
  def category_json(category)
    {
        'id' => category.id,
        'name' => category.name,
        'role' => category.role,
        'self_signup' => category.self_signup,
        'context_type' => category.context_type,
        "#{category.context_type.downcase}_id" => category.context_id
    }
  end

  before do
    @moderator = user_model
    @member = user_with_pseudonym


    @communities = GroupCategory.communities_for(Account.default)
    @community = group_model(:name => "Algebra Teacher", :group_category => @communities, :context => Account.default)
    @community.add_user(@member, 'accepted', false)
    @community.add_user(@moderator, 'accepted', true)
    @community_path = "/api/v1/groups/#{@community.id}"
    @category_path_options = {:controller => "group_categories", :format => "json"}

    @course = course_with_teacher(:active_all => true).course
    student_in_course(:course => @course)
    @study_groups = GroupCategory.student_organized_for(@course)
    @study_group = group_model(:name => "Study Group", :group_category => @study_groups, :context => @course)
    @study_group.add_user(@student, 'accepted', false)

    @context = @community
  end

  it "should allow listing all of a course's group categories for teachers" do
    @user = @teacher
    json = api_call(:get, "/api/v1/courses/#{@course.to_param}/group_categories.json",
                    @category_path_options.merge(:action => 'index',
                                                 :course_id => @course.to_param))
    json.count.should == 1
    json.first['id'].should == @study_groups.id
  end

  it "should not allow listing of a course's group categories for students" do
    @user = @student
    raw_api_call(:get, "/api/v1/courses/#{@course.to_param}/group_categories.json",
                 @category_path_options.merge(:action => 'index',
                                              :course_id => @course.to_param))
    response.code.should == '401'
  end

  it "should allow listing all of an account's group categories for account admins" do
    @account = Account.default
    account_admin_user(:account => @account)

    json = api_call(:get, "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                    @category_path_options.merge(:action => 'index',
                                                 :account_id => @account.to_param))
    json.count.should == 1
    json.first['id'].should == @communities.id
  end

  it "should not allow non-admins to list an account's group categories" do
    @account = Account.default
    raw_api_call(:get, "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                 @category_path_options.merge(:action => 'index',
                                              :account_id => @account.to_param))
    response.code.should == '401'
  end

  it "should allow admins to retrieve a group category" do
    @account = Account.default
    account_admin_user(:account => @account)
    json = api_call(:get, "/api/v1/group_categories/#{@communities.id}", @category_path_options.merge(:action => 'show', :group_category_id => @communities.to_param))
    json['id'].should == @communities.id
  end

  it "should return a 'not found' error if there is no group_category" do
    @account = Account.default
    account_admin_user(:account => @account)
    raw_api_call(:get, "/api/v1/group_categories/9999999", @category_path_options.merge(:action => 'show', :group_category_id => "9999999"))
    response.code.should == '404'
  end

  it "should not allow non-admins to retrieve a group category" do
    @account = Account.default
    json = raw_api_call(:get, "/api/v1/group_categories/#{@communities.id}", @category_path_options.merge(:action => 'show', :group_category_id => @communities.to_param))
    response.code.should == '401'
  end

  it "should allow teachers to retrieve a group category" do
    @user = @teacher
    json = api_call(:get, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'show', :group_category_id => @study_groups.to_param))
    json['id'].should == @study_groups.id
  end

  it "should list all groups in category for a teacher" do
    @user = @teacher
    json = api_call(:get, "/api/v1/group_categories/#{@study_groups.id}/groups", @category_path_options.merge(:action => 'groups', :group_category_id => @study_groups.to_param))
    json.first['id'].should == @study_group.id
  end

  it "should list all groups in category for a teacher" do
    @user = @teacher
    json = api_call(:get, "/api/v1/group_categories/#{@study_groups.id}/groups", @category_path_options.merge(:action => 'groups', :group_category_id => @study_groups.to_param))
    json.first['id'].should == @study_group.id
  end

  it "should list all groups in category for a admin" do
    @account = Account.default
    account_admin_user(:account => @account)
    json = api_call(:get, "/api/v1/group_categories/#{@communities.id}/groups", @category_path_options.merge(:action => 'groups', :group_category_id => @communities.to_param))
    json.first['id'].should == @community.id
  end

  it "should not list all groups in category for a student" do
    @user = @student
    raw_api_call(:get, "/api/v1/group_categories/#{@study_groups.id}/groups", @category_path_options.merge(:action => 'groups', :group_category_id => @study_groups.to_param))
    response.code.should == '401'
  end

  it "should not list all groups in category for a non-admin" do
    raw_api_call(:get, "/api/v1/group_categories/#{@communities.id}/groups", @category_path_options.merge(:action => 'groups', :group_category_id => @communities.to_param))
    response.code.should == '401'
  end

  it "should allow a teacher to create a course group category" do
    @user = @teacher
    name = 'Discussion Groups'
    json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param), {'name' => name})
    category = GroupCategory.find(json["id"])
    json["context_type"].should == "Course"
    category.name.should == name
    json.should == category_json(category)
  end

  it "should not allow a student to create a course group category" do
    @user = @student
    name = 'Discussion Groups'
    raw_api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param), {'name' => name})
    response.code.should == '401'
  end

  it "should allow an admin to create an account group category" do
    @account = Account.default
    account_admin_user(:account => @account)
    name = 'WOT'
    json = api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories", @category_path_options.merge(:action => 'create', :account_id => @account.to_param), {'name' => name})

    category = GroupCategory.find(json["id"])
    json["context_type"].should == "Account"
    category.name.should == name
    json.should == category_json(category)
  end

  it "should not allow a non-admin to create an account group category" do
    @account = Account.default
    name = 'WOT'
    raw_api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories", @category_path_options.merge(:action => 'create', :account_id => @account.to_param), {'name' => name})
    response.code.should == '401'
  end

  it "should allow a teacher to update a category for a course" do
    @user = @teacher
    name = "Updated Course Name"
    api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
             {:name => name}
    category = GroupCategory.find(@study_groups.id)
    category.name.should == name
  end

  it "should allow a teacher to update a category to self_signup enabled for a course" do
    @user = @teacher
    name = "Updated Course Name"
    api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
             {
                 :name => name,
                 :self_signup => 'enabled'
             }
    category = GroupCategory.find(@study_groups.id)
    category.self_signup.should == "enabled"
    category.name.should == name
  end

  it "should allow a teacher to update a category to self_signup restricted for a course" do
    @user = @teacher
    name = "Updated Course Name"
    api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
             {
                 :name => name,
                 :self_signup => 'restricted'
             }
    category = GroupCategory.find(@study_groups.id)
    category.self_signup.should == "restricted"
    category.name.should == name
  end

  it "should allow a teacher to update a category to self_signup and create groups restricted for a course" do
    @user = @teacher
    name = "Updated Course Name"
    json = api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
             {
                 :name => name,
                 :self_signup => 'enabled',
                 'create_group_count' => 3
             }
    category = GroupCategory.find(json["id"])
    category.self_signup.should == "enabled"
    groups = category.groups.active
    groups.count.should == 4
  end

  it "should allow a teacher to update a category to self_signup and create groups restricted for a course" do
    6.times { course_with_user('StudentEnrollment', {:course => @study_groups.context}) }
    @user = @teacher
    name = "Updated Course Name"
    json = api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
                    {
                        :name => name,
                        :split_group_count => 3
                    }
    category = GroupCategory.find(json["id"])
    groups = category.groups.active
    groups.count.should == 4
    groups[0].users.count.should == 2
    groups[1].users.count.should == 2
    groups[2].users.count.should == 2
    groups[3].users.count.should == 2
  end

  it "should not allow a student to update a category for a course" do
    @user = @student
    name = "Updated Course Name"
    raw_api_call :put, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'update', :group_category_id => @study_groups.to_param),
                    {:name => name}
    response.code.should == '401'
  end

  it "should allow an admin to update a category for an account" do
    @account = Account.default
    account_admin_user(:account => @account)
    name = "Updated Account Name"
    api_call :put, "/api/v1/group_categories/#{@communities.id}", @category_path_options.merge(:action => 'update', :group_category_id => @communities.to_param),
             {:name => name}
    category = GroupCategory.find(@communities.id)
    category.name.should == name
  end

  it "should not allow a non-admin to update a category for an account" do
    name = "Updated Account Name"
    raw_api_call :put, "/api/v1/group_categories/#{@communities.id}", @category_path_options.merge(:action => 'update', :group_category_id => @communities.to_param),
             {:name => name}
    response.code.should == '401'
  end

  it "should allow a teacher to delete a category for a course" do
    @user = @teacher
    project_groups = @course.group_categories.build
    project_groups.name = "Course Project Groups"
    project_groups.save
    GroupCategory.find(project_groups.id).should_not == nil
    api_call :delete, "/api/v1/group_categories/#{project_groups.id}", @category_path_options.merge(:action => 'destroy', :group_category_id => project_groups.to_param)
    GroupCategory.find(project_groups.id).deleted_at.should_not == nil
  end

  it "should not allow a teacher to delete the student groups category" do
    @user = @teacher
    GroupCategory.find(@study_groups.id).should_not == nil
    raw_api_call :delete, "/api/v1/group_categories/#{@study_groups.id}", @category_path_options.merge(:action => 'destroy', :group_category_id => @study_groups.to_param)
    response.code.should == '401'
  end

  it "should not allow a student to delete a category for a course" do
    @user = @student
    project_groups = @course.group_categories.build
    project_groups.name = "Course Project Groups"
    project_groups.save
    GroupCategory.find(project_groups.id).should_not == nil
    raw_api_call :delete, "/api/v1/group_categories/#{project_groups.id}", @category_path_options.merge(:action => 'destroy', :group_category_id => project_groups.to_param)
    response.code.should == '401'
  end

  it "should allow an admin to delete a category for an account" do
    @account = Account.default
    account_admin_user(:account => @account)
    project_groups = @account.group_categories.build
    project_groups.name = "test group category"
    project_groups.save
    GroupCategory.find(project_groups.id).should_not == nil
    raw_api_call :delete, "/api/v1/group_categories/#{project_groups.id}", @category_path_options.merge(:action => 'destroy', :group_category_id => project_groups.to_param)
    GroupCategory.find(project_groups.id).deleted_at.should_not == nil
  end

  it "should not allow a non-admin to delete a category for an account" do
    @account = Account.default
    project_groups = @account.group_categories.build
    project_groups.name = "test group category"
    project_groups.save
    GroupCategory.find(@communities.id).should_not == nil
    raw_api_call :delete, "/api/v1/group_categories/#{project_groups.id}", @category_path_options.merge(:action => 'destroy', :group_category_id => project_groups.to_param)
    response.code.should == '401'
  end

  it "should split students between groups" do
    5.times { course_with_user('StudentEnrollment', {:course => @course}) }
    @user = @teacher
    name = 'Discussion Groups'
    json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param),
                    {
                        'name' => name,
                        'split_group_count' => 3
                    }
    )
    category = GroupCategory.find(json["id"])
    groups = category.groups.active
    groups.count.should == 3
    groups[0].users.count.should == 2
    groups[1].users.count.should == 2
    groups[2].users.count.should == 2
  end

  it "should create self signup groups" do
    @user = @teacher
    name = 'Discussion Groups'
    json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param),
                    {
                        'name' => name,
                        'self_signup' => 'enabled',
                        'create_group_count' => 3
                    }
    )
    category = GroupCategory.find(json["id"])
    category.self_signup.should == "enabled"
    groups = category.groups.active
    groups.count.should == 3
  end

  it "should create restricted self sign up groups" do
    @user = @teacher
    name = 'Discussion Groups'
    json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param),
                    {
                        'name' => name,
                        'self_signup' => 'restricted',
                        'create_group_count' => 3
                    }
    )
    category = GroupCategory.find(json["id"])
    category.self_signup.should == "restricted"
    groups = category.groups.active
    groups.count.should == 3
  end

  it "should not allow both 'enable_self_signup' and 'split_group_count'" do
    @user = @teacher
    name = 'Discussion Groups'
    raw_api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param),
                    {
                        'name' => name,
                        'enable_self_signup' => '1',
                        'split_group_count' => 3
                    }
    )
    response.code.should == '400'
  end

  it "should not allow 'create_group_count' without 'enable_self_signup'" do
    @user = @teacher
    name = 'Discussion Groups'
    raw_api_call(:post, "/api/v1/courses/#{@course.id}/group_categories", @category_path_options.merge(:action => 'create', :course_id => @course.to_param),
                 {
                     'name' => name,
                     'create_group_count' => 3
                 }
    )
    response.code.should == '400'
  end

  it "should not allow 'enable_self_signup' for a non course group" do
    @account = Account.default
    account_admin_user(:account => @account)
    name = 'Discussion Groups'
    raw_api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories", @category_path_options.merge(:action => 'create', :account_id => @account.to_param),
                 {
                     'name' => name,
                     'enable_self_signup' => '1',
                     'create_group_count' => 3
                 }
    )
    response.code.should == '400'
  end

  it "should not allow 'split_group_count' for a non course group" do
    @account = Account.default
    account_admin_user(:account => @account)
    name = 'Discussion Groups'
    raw_api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories", @category_path_options.merge(:action => 'create', :account_id => @account.to_param),
                 {
                     'name' => name,
                     'split_group_count' => 3
                 }
    )
    response.code.should == '400'
  end

end