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
      "#{category.context_type.downcase}_id" => category.context_id,
      'group_limit' => category.group_limit,
      'groups_count' => category.groups.size,
      'unassigned_users_count' => category.unassigned_users.count
    }
  end

  before do
    @account = Account.default
    @category_path_options = {:controller => "group_categories", :format => "json"}
  end

  describe "course group categories" do
    before do
      @course = course(:course_name => 'Math 101', :account => @account, :active_course => true)
      @category = GroupCategory.student_organized_for(@course)
    end

    describe "users" do
      let(:api_url) { "/api/v1/group_categories/#{@category2.id}/users.json" }
      let(:api_route) do
        {
            :controller => 'group_categories',
            :action => 'users',
            :group_category_id => @category2.to_param,
            :format => 'json'
        }
      end

      before do
        @user = user(:name => "joe mcCool")
        @course.enroll_user(@user,'TeacherEnrollment',:enrollment_state => :active)

        @user_waldo = user(:name => "waldo")
        @course.enroll_user(@user,'StudentEnrollment',:enrollment_state => :active)


        6.times { course_with_student({:course => @course}) }
        @user = @course.teacher_enrollments.first.user

        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        { 'name' => 'category', 'split_group_count' => 3 })

        @user_antisocial = user(:name => "antisocial")
        @course.enroll_user(@user,'StudentEnrollment',:enrollment_state => :active)

        @category2 = GroupCategory.find(json["id"])

        @category_users = @category2.groups.inject([]){|result, group| result.concat(group.users)} << @user
        @category_assigned_users = @category2.groups.active.inject([]){|result, group| result.concat(group.users)}
        @category_unassigned_users = @category_users - @category_assigned_users
      end

      it "should return users in a group_category" do
        expected_keys = %w{id name sortable_name short_name}
        json = api_call(:get, api_url, api_route)
        json.count.should == 8
        json.each do |user|
          (user.keys & expected_keys).sort.should == expected_keys.sort
          @category_users.map(&:id).should include(user['id'])
        end
      end

      it "should return 401 for users outside the group_category" do
        user  # ?
        raw_api_call(:get, api_url, api_route)
        response.code.should == '401'
      end

      it "returns an error when search_term is fewer than 3 characters" do
        json = api_call(:get, api_url, api_route, {:search_term => 'ab'}, {}, :expected_status => 400)
        error = json["errors"].first
        verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
      end

      it "returns a list of users" do
        expected_keys = %w{id name sortable_name short_name}

        json = api_call(:get, api_url, api_route, {:search_term => 'waldo'})

        json.count.should == 1
        json.each do |user|
          (user.keys & expected_keys).sort.should == expected_keys.sort
          @category_users.map(&:id).should include(user['id'])
        end
      end

      it "returns a list of unassigned users" do
        expected_keys = %w{id name sortable_name short_name}

        json = api_call(:get, api_url, api_route, {:search_term => 'antisocial', :unassigned => 'true'})

        json.count.should == 1
        json.each do |user|
          (user.keys & expected_keys).sort.should == expected_keys.sort
          @category_unassigned_users.map(&:id).should include(user['id'])
        end
      end
    end

    describe "teacher actions with no group" do
      before do
        @name = 'some group name'
        @user = user(:name => "joe mcCool")
        @course.enroll_user(@user,'TeacherEnrollment',:enrollment_state => :active)
      end

      it "should allow a teacher to update a category that creates groups" do
        json = api_call :put, "/api/v1/group_categories/#{@category.id}",
                        @category_path_options.merge(:action => 'update',
                                                     :group_category_id => @category.to_param),
                        { :name => @name, :self_signup => 'enabled','create_group_count' => 3 }
        category = GroupCategory.find(json["id"])
        category.self_signup.should == "enabled"
        groups = @category.groups.active
        groups.count.should == 3
      end

      it "should allow a teacher to update a category and distribute students to new groups" do
        6.times { course_with_student({:course => @course}) }
        @user = @course.teacher_enrollments.first.user
        json = api_call :put, "/api/v1/group_categories/#{@category.id}",
                        @category_path_options.merge(:action => 'update',
                                                     :group_category_id => @category.to_param),
                        { :name => @name, :split_group_count => 3 }
        category = GroupCategory.find(json["id"])
        groups = category.groups.active
        groups.count.should == 3
        groups[0].users.count.should == 2
        groups[1].users.count.should == 2
        groups[2].users.count.should == 2
      end

      it "should create group category/groups and split students between groups" do
        6.times { course_with_student({:course => @course}) }
        @user = @course.teacher_enrollments.first.user
        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        { 'name' => @name, 'split_group_count' => 3 })
        category = GroupCategory.find(json["id"])
        groups = category.groups.active
        groups.count.should == 3
        groups[0].users.count.should == 2
        groups[1].users.count.should == 2
        groups[2].users.count.should == 2
      end

      it "should create self signup groups" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        { 'name' => @name, 'self_signup' => 'enabled', 'create_group_count' => 3 })
        category = GroupCategory.find(json["id"])
        category.self_signup.should == "enabled"
        groups = category.groups.active
        groups.count.should == 3
      end

      it "should create restricted self sign up groups" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        {
                          'name' => @name,
                          'self_signup' => 'restricted',
                          'create_group_count' => 3
                        }
        )
        category = GroupCategory.find(json["id"])
        category.self_signup.should == "restricted"
        groups = category.groups.active
        groups.count.should == 3
      end

      it "should ignore 'split_group_count' if 'enable_self_signup'" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        {
                          'name' => @name,
                          'enable_self_signup' => '1',
                          'split_group_count' => 3
                        }
        )
        category = GroupCategory.find(json["id"])
        category.self_signup.should == "enabled"
        category.groups.active.should be_empty
      end

      it "should prefer 'split_group_count' over 'create_group_count' if not 'enable_self_signup'" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :course_id => @course.to_param),
                        {
                          'name' => @name,
                          'create_group_count' => 3,
                          'split_group_count' => 2
                        }
        )
        category = GroupCategory.find(json["id"])
        category.groups.active.size.should == 2
      end

      describe "teacher actions with a group" do
        before do
          @study_group = group_model(:name => @name, :group_category => @category,
                                     :context => @course)
        end

        it "should allow listing all of a course's group categories for teachers" do
          json = api_call(:get, "/api/v1/courses/#{@course.to_param}/group_categories.json",
                          @category_path_options.merge(:action => 'index',
                                                       :course_id => @course.to_param))
          json.count.should == 1
          json.first['id'].should == @category.id
        end

        it "should allow teachers to retrieve a group category" do
          json = api_call(:get, "/api/v1/group_categories/#{@category.id}",
                          @category_path_options.merge(:action => 'show',
                                                       :group_category_id => @category.to_param))
          json['id'].should == @category.id
        end

        it "should list all groups in category for a teacher" do
          json = api_call(:get, "/api/v1/group_categories/#{@category.id}/groups",
                          @category_path_options.merge(:action => 'groups',
                                                       :group_category_id => @category.to_param))
          json.first['id'].should == @study_group.id
        end

        it "should list all groups in category for a teacher" do
          json = api_call(:get, "/api/v1/group_categories/#{@category.id}/groups",
                          @category_path_options.merge(:action => 'groups',
                                                       :group_category_id => @category.to_param))
          json.first['id'].should == @study_group.id
        end

        it "should allow a teacher to update a category for a course" do
          api_call :put, "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(:action => 'update',
                                                :group_category_id => @category.to_param),
                   {:name => @name}
          category = GroupCategory.find(@category.id)
          category.name.should == @name
        end

        it "should allow a teacher to update a category to self_signup enabled for a course" do
          api_call :put, "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(:action => 'update',
                                                :group_category_id => @category.to_param),
                   { :name => @name, :self_signup => 'enabled' }
          category = GroupCategory.find(@category.id)
          category.self_signup.should == "enabled"
          category.name.should == @name
        end

        it "should allow a teacher to update a category to self_signup restricted for a course" do
          api_call :put, "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(:action => 'update',
                                                :group_category_id => @category.to_param),
                   { :name => @name, :self_signup => 'restricted' }
          category = GroupCategory.find(@category.id)
          category.self_signup.should == "restricted"
          category.name.should == @name
        end

        it "should allow a teacher to delete a category for a course" do
          project_groups = @course.group_categories.build
          project_groups.name = @name
          project_groups.save
          GroupCategory.find(project_groups.id).should_not == nil
          api_call :delete, "/api/v1/group_categories/#{project_groups.id}",
                   @category_path_options.merge(:action => 'destroy',
                                                :group_category_id => project_groups.to_param)
          GroupCategory.find(project_groups.id).deleted_at.should_not == nil
        end

        it "should allow a teacher to create a course group category" do
          json = api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                          @category_path_options.merge(:action => 'create',
                                                       :course_id => @course.to_param),
                          {'name' => @name})
          category = GroupCategory.find(json["id"])
          json["context_type"].should == "Course"
          category.name.should == @name
          json.should == category_json(category)
        end
      end
    end

    describe "student actions" do
      before do
        @user = user(:name => "derrik hans")
        @course.enroll_user(@user,'StudentEnrollment',:enrollment_state => :active)
      end

      it "should not allow listing of a course's group categories for students" do
        raw_api_call(:get, "/api/v1/courses/#{@course.to_param}/group_categories.json",
                     @category_path_options.merge(:action => 'index',
                                                  :course_id => @course.to_param))
        response.code.should == '401'
      end

      it "should not list all groups in category for a student" do
        raw_api_call(:get, "/api/v1/group_categories/#{@category.id}/groups",
                     @category_path_options.merge(:action => 'groups',
                                                  :group_category_id => @category.to_param))
        response.code.should == '401'
      end
      it "should not allow a student to create a course group category" do
        name = 'Discussion Groups'
        raw_api_call(:post, "/api/v1/courses/#{@course.id}/group_categories",
                     @category_path_options.merge(:action => 'create',
                                                  :course_id => @course.to_param),
                     {'name' => name})
        response.code.should == '401'
      end

      it "should not allow a teacher to delete the student groups category" do
        GroupCategory.find(@category.id).should_not == nil
        raw_api_call :delete, "/api/v1/group_categories/#{@category.id}",
                     @category_path_options.merge(:action => 'destroy',
                                                  :group_category_id => @category.to_param)
        response.code.should == '401'
      end

      it "should not allow a student to delete a category for a course" do
        project_groups = @course.group_categories.build
        project_groups.name = "Course Project Groups"
        project_groups.save
        GroupCategory.find(project_groups.id).should_not == nil
        raw_api_call :delete, "/api/v1/group_categories/#{project_groups.id}",
                     @category_path_options.merge(:action => 'destroy',
                                                  :group_category_id => project_groups.to_param)
        response.code.should == '401'
      end

      it "should not allow a student to update a category for a course" do
        raw_api_call :put, "/api/v1/group_categories/#{@category.id}",
                     @category_path_options.merge(:action => 'update',
                                                  :group_category_id => @category.to_param),
                     {:name => 'name'}
        response.code.should == '401'
      end
    end

    describe "POST 'assign_unassigned_members'" do
      it "should require :manage_groups permission" do
        course_with_teacher(:active_all => true)
        student = @course.enroll_student(user_model).user
        category = @course.group_categories.create(:name => "Group Category")

        user_session(student)
        raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => category.to_param),
                     {'sync' => true}
        response.status.should == '401 Unauthorized'
      end

      it "should require valid group :category_id" do
        course_with_teacher_logged_in(:active_all => true)
        category = @course.group_categories.create(:name => "Group Category")

        raw_api_call :post, "/api/v1/group_categories/#{category.id + 1}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => (category.id + 1).to_param),
                     {'sync' => true}
        response.status.should == '404 Not Found'
      end

      it "should fail for student organized groups" do
        course_with_teacher_logged_in(:active_all => true)
        category = GroupCategory.student_organized_for(@course)

        raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => category.to_param),
                     {'sync' => true}
        response.status.should == '400 Bad Request'
      end

      it "should fail for restricted self signup groups" do
        course_with_teacher_logged_in(:active_all => true)
        category = @course.group_categories.build(:name => "Group Category")
        category.configure_self_signup(true, true)
        category.save

        raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => category.to_param),
                     {'sync' => true}
        response.status.should == '400 Bad Request'

        category.configure_self_signup(true, false)
        category.save

        raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => category.to_param),
                     {'sync' => true}
        response.should be_success
      end

      it "should otherwise assign ungrouped users to groups in the category" do
        course_with_teacher_logged_in(:active_all => true)
        teacher = @user
        category = @course.group_categories.create(:name => "Group Category")
        group1 = category.groups.create(:name => "Group 1", :context => @course)
        group2 = category.groups.create(:name => "Group 2", :context => @course)
        student1 = @course.enroll_student(user_model).user
        student2 = @course.enroll_student(user_model).user # not in a group
        group2.add_user(student1)

        @user = teacher
        raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(:action => 'assign_unassigned_members',
                                                  :group_category_id => category.to_param)

        response.should be_success

        run_jobs

        group1.reload.users.should include(student2)
      end

      it "should render progress_json" do
        course_with_teacher_logged_in(:active_all => true)
        category = @course.group_categories.create(:name => "Group Category")

        expect {
          raw_api_call :post, "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                       @category_path_options.merge(:action => 'assign_unassigned_members',
                                                    :group_category_id => category.to_param)

          response.should be_success
          json = JSON.parse(response.body)
          json['url'].should =~ Regexp.new("http://www.example.com/api/v1/progress/\\d+")
          json['completion'].should == 0
        }.to change(Delayed::Job, :count).by(1)
      end
    end
  end

  describe "account group categories" do
    before do
      @communities = GroupCategory.communities_for(@account)
    end

    describe "admin actions" do
      before do
        @user = account_admin_user(:account => @account)
      end

      it "should allow listing all of an account's group categories for account admins" do
        json = api_call(:get, "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                        @category_path_options.merge(:action => 'index',
                                                     :account_id => @account.to_param))
        json.count.should == 1
        json.first['id'].should == @communities.id
      end

      it "should ignore 'split_group_count' for a non course group" do
        json = api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :account_id => @account.to_param),
                        {
                            'name' => 'category',
                            'split_group_count' => 3
                        }
        )
        category = GroupCategory.find(json["id"])
        category.groups.active.should be_empty
      end

      it "should allow admins to retrieve a group category" do
        json = api_call(:get, "/api/v1/group_categories/#{@communities.id}",
                        @category_path_options.merge(:action => 'show',
                                                     :group_category_id => @communities.to_param))
        json['id'].should == @communities.id
      end

      it "should return a 'not found' error if there is no group_category" do
        raw_api_call(:get, "/api/v1/group_categories/9999999",
                     @category_path_options.merge(:action => 'show',
                                                  :group_category_id => "9999999"))
        response.code.should == '404'
      end

      it "should list all groups in category for a admin" do
        @community = group_model(:name => "Algebra Teacher",
                                 :group_category => @communities, :context => @account)
        json = api_call(:get, "/api/v1/group_categories/#{@communities.id}/groups",
                        @category_path_options.merge(:action => 'groups',
                                                     :group_category_id => @communities.to_param))
        json.first['id'].should == @community.id
      end

      it "should allow an admin to create an account group category" do
        json = api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories",
                        @category_path_options.merge(:action => 'create',
                                                     :account_id => @account.to_param),
                        {'name' => 'name'})
        category = GroupCategory.find(json["id"])
        json["context_type"].should == "Account"
        category.name.should == 'name'
        json.should == category_json(category)
      end

      it "should allow an admin to update a category for an account" do
        api_call :put, "/api/v1/group_categories/#{@communities.id}",
                 @category_path_options.merge(:action => 'update',
                                              :group_category_id => @communities.to_param),
                 {:name => 'name'}
        category = GroupCategory.find(@communities.id)
        category.name.should == 'name'
      end


      it "should allow an admin to delete a category for an account" do
        account_category = GroupCategory.create(:name => 'Groups', :context => @account)
        GroupCategory.find(@communities.id).should_not == nil
        raw_api_call :delete, "/api/v1/group_categories/#{account_category.id}",
                     @category_path_options.merge(:action => 'destroy',
                                                  :group_category_id => account_category.to_param)
        GroupCategory.find(account_category.id).deleted_at.should_not be_nil
      end

      it "should not allow 'enable_self_signup' for a non course group" do
        raw_api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories",
                     @category_path_options.merge(:action => 'create',
                                                  :account_id => @account.to_param),
                     {
                       'name' => 'name',
                       'enable_self_signup' => '1',
                       'create_group_count' => 3
                     }
        )
        response.code.should == '400'
      end
    end

    it "should not allow non-admins to list an account's group categories" do
      raw_api_call(:get, "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                   @category_path_options.merge(:action => 'index',
                                                :account_id => @account.to_param))
      response.code.should == '401'
    end

    it "should not allow non-admins to retrieve a group category" do
      raw_api_call(:get, "/api/v1/group_categories/#{@communities.id}",
                   @category_path_options.merge(:action => 'show',
                                                :group_category_id => @communities.to_param))
      response.code.should == '401'
    end

    it "should not allow a non-admin to delete a category for an account" do
      account_category = GroupCategory.create(:name => 'Groups', :context => @account)
      raw_api_call :delete, "/api/v1/group_categories/#{account_category.id}",
                   @category_path_options.merge(:action => 'destroy',
                                                :group_category_id => account_category.to_param)
      response.code.should == '401'
    end

    it "should not list all groups in category for a non-admin" do
      raw_api_call(:get, "/api/v1/group_categories/#{@communities.id}/groups",
                   @category_path_options.merge(:action => 'groups',
                                                :group_category_id => @communities.to_param))
      response.code.should == '401'
    end

    it "should not allow a non-admin to create an account group category" do
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/group_categories",
                   @category_path_options.merge(:action => 'create',
                                                :account_id => @account.to_param),
                   {'name' => 'name'})
      response.code.should == '401'
    end

    it "should not allow a non-admin to update a category for an account" do
      raw_api_call :put, "/api/v1/group_categories/#{@communities.id}",
                   @category_path_options.merge(:action => 'update',
                                                :group_category_id => @communities.to_param),
                   {:name => 'name'}
      response.code.should == '401'
    end
  end
end
