# frozen_string_literal: true

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

require_relative "../api_spec_helper"
require_relative "../file_uploads_spec_helper"

describe "Group Categories API", type: :request do
  def category_json(category, user = @user)
    json = {
      "id" => category.id,
      "name" => category.name,
      "role" => category.role,
      "self_signup" => category.self_signup,
      "context_type" => category.context_type,
      "#{category.context_type.downcase}_id" => category.context_id,
      "created_at" => category.created_at.iso8601,
      "group_limit" => category.group_limit,
      "groups_count" => category.groups.size,
      "unassigned_users_count" => category.unassigned_users.count(:all),
      "protected" => false,
      "allows_multiple_memberships" => false,
      "auto_leader" => category.auto_leader,
      "is_member" => false
    }
    json["sis_group_category_id"] = category.sis_source_id if category.root_account.grants_any_right?(user, :read_sis, :manage_sis)
    json["sis_import_id"] = category.sis_batch_id if category.root_account.grants_right?(user, :manage_sis)
    json
  end

  before :once do
    @account = Account.default
    @category_path_options = { controller: "group_categories", format: "json" }
  end

  describe "course group categories" do
    before :once do
      @course = course_factory(course_name: "Math 101", account: @account, active_course: true)
      @category = GroupCategory.student_organized_for(@course)
    end

    describe "export" do
      let(:api_url) { "/api/v1/group_categories/#{@category.id}/export" }
      let(:api_route) do
        {
          controller: "group_categories",
          action: "export",
          group_category_id: @category.to_param,
          format: "csv"
        }
      end

      before :once do
        5.times do |n|
          @course.enroll_user(user_with_pseudonym(sis_user_id: "user_#{n}", username: "login_#{n}"), "StudentEnrollment", enrollment_state: "active")
          @course.enroll_user(user_factory, "TeacherEnrollment", enrollment_state: :active)
        end
      end

      context "basic roster" do
        shared_examples "basic course roster" do
          it "returns users for a group_category" do
            status = raw_api_call(:get, api_url, api_route)
            expect(status).to eq 200
            csv = CSV.parse(response.body)
            expect(csv.shift).to eq(%w[name canvas_user_id user_id login_id sections group_name])
            expect(csv.count).to eq(5)
            5.times do
              p = Pseudonym.by_unique_id(csv.first[3]).take
              expect(csv.shift).to eq([p.user.name, p.user_id.to_s, p.sis_user_id, p.unique_id, @course.name, nil])
            end
          end
        end

        context "future course should work" do
          before do
            @course.start_at = 1.week.from_now
            @course.restrict_enrollments_to_course_dates = true
            @course.save!
          end

          include_examples "basic course roster"
        end

        context "normal course" do
          include_examples "basic course roster"
        end
      end

      context "granular permissions" do
        it "succeeds" do
          @course.root_account.enable_feature!(:granular_permissions_manage_groups)
          status = raw_api_call(:get, api_url, api_route)
          expect(status).to eq 200
        end

        it "does not succeed if :manage_groups_add is not enabled" do
          @course.root_account.enable_feature!(:granular_permissions_manage_groups)
          @course.account.role_overrides.create!(
            permission: "manage_groups_manage",
            role: teacher_role,
            enabled: false
          )
          raw_api_call(:get, api_url, api_route)
          assert_unauthorized
        end
      end

      it "returns active group_memberships" do
        g1 = @category.groups.create!(name: "g1", context: @course)
        g2 = @category.groups.create!(name: "g2", sis_source_id: "g2sis", context: @course)
        u1 = Pseudonym.by_unique_id("login_0").take.user
        gm1 = g1.add_user(u1)
        gm1.destroy
        g2.add_user(u1)
        status = raw_api_call(:get, api_url, api_route)
        expect(status).to eq 200
        csv = CSV.parse(response.body)
        expect(csv.shift).to eq(%w[name canvas_user_id user_id login_id sections group_name canvas_group_id group_id])
        expect(csv.count).to eq(5)
        5.times do
          p = Pseudonym.by_unique_id(csv.first[3]).take
          next unless p.unique_id == "login_0"

          expect(csv.shift).to eq([p.user.name, p.user_id.to_s, p.sis_user_id, p.unique_id, @course.name, "g2", g2.id.to_s, "g2sis"])
        end
      end

      it "returns group_memberships in active groups" do
        g1 = @category.groups.create!(name: "g1", context: @course)
        u1 = Pseudonym.by_unique_id("login_0").take.user
        g1.add_user(u1)
        g1.destroy
        status = raw_api_call(:get, api_url, api_route)
        expect(status).to eq 200
        csv = CSV.parse(response.body)
        expect(csv.shift).to eq(%w[name canvas_user_id user_id login_id sections group_name])
        expect(csv.count).to eq(5)
        5.times do
          p = Pseudonym.by_unique_id(csv.first[3]).take
          expect(csv.shift).to eq([p.user.name, p.user_id.to_s, p.sis_user_id, p.unique_id, @course.name, nil])
        end
      end
    end

    describe "users" do
      let(:api_url) { "/api/v1/group_categories/#{@category2.id}/users.json" }
      let(:api_route) do
        {
          controller: "group_categories",
          action: "users",
          group_category_id: @category2.to_param,
          format: "json"
        }
      end

      before :once do
        @user = user_factory(name: "joe mcCool")
        @course.enroll_user(@user, "TeacherEnrollment", enrollment_state: :active)

        @user_waldo = user_factory(name: "waldo")
        @course.enroll_user(@user, "StudentEnrollment", enrollment_state: :active)

        6.times { course_with_student({ course: @course }) }

        @user = @course.teacher_enrollments.first.user
      end

      before do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        { "name" => "category", "split_group_count" => 3 })

        @user_antisocial = user_factory(name: "antisocial")
        @course.enroll_user(@user, "StudentEnrollment", enrollment_state: :active)

        @category2 = GroupCategory.find(json["id"])

        @category_users = @category2.groups.inject([]) { |result, group| result.concat(group.users) } << @user
        @category_assigned_users = @category2.groups.active.inject([]) { |result, group| result.concat(group.users) }
        @category_unassigned_users = @category_users - @category_assigned_users
      end

      it "returns users in a group_category" do
        expected_keys = %w[id name sortable_name short_name]
        json = api_call(:get, api_url, api_route)
        expect(json.count).to eq 8
        json.each do |user|
          expect((user.keys & expected_keys).sort).to eq expected_keys.sort
          expect(@category_users.map(&:id)).to include(user["id"])
        end
      end

      it "returns 401 for users outside the group_category" do
        user_factory # ?
        raw_api_call(:get, api_url, api_route)
        expect(response).to have_http_status :unauthorized
      end

      it "returns an error when search_term is fewer than 2 characters" do
        json = api_call(:get, api_url, api_route, { search_term: "a" }, {}, expected_status: 400)
        error = json["errors"].first
        verify_json_error(error, "search_term", "invalid", "2 or more characters is required")
      end

      it "returns a list of users" do
        expected_keys = %w[id name sortable_name short_name]

        json = api_call(:get, api_url, api_route, { search_term: "waldo" })

        expect(json.count).to eq 1
        json.each do |user|
          expect((user.keys & expected_keys).sort).to eq expected_keys.sort
          expect(@category_users.map(&:id)).to include(user["id"])
        end
      end

      it "returns a list of unassigned users" do
        expected_keys = %w[id name sortable_name short_name]

        json = api_call(:get, api_url, api_route, { search_term: "antisocial", unassigned: "true" })

        expect(json.count).to eq 1
        json.each do |user|
          expect((user.keys & expected_keys).sort).to eq expected_keys.sort
          expect(@category_unassigned_users.map(&:id)).to include(user["id"])
        end
      end

      it "includes custom student roles in search" do
        teacher = @user
        custom_student = user_factory(name: "blah")
        role = custom_student_role("CustomStudent", account: @course.account)
        @course.enroll_user(custom_student, "StudentEnrollment", role:)
        json = api_call_as_user(teacher, :get, api_url, api_route)
        expect(json.pluck("id")).to include custom_student.id
      end
    end

    describe "teacher actions with no group" do
      before :once do
        @name = "some group name"
        @user = user_factory(name: "joe mcCool")
        @course.enroll_user(@user, "TeacherEnrollment", enrollment_state: :active)
      end

      it "allows a teacher to update a category that creates groups" do
        json = api_call :put,
                        "/api/v1/group_categories/#{@category.id}",
                        @category_path_options.merge(action: "update",
                                                     group_category_id: @category.to_param),
                        { :name => @name, :self_signup => "enabled", "create_group_count" => 3 }
        category = GroupCategory.find(json["id"])
        expect(category.self_signup).to eq "enabled"
        groups = @category.groups.active
        expect(groups.count).to eq 3
      end

      it "does not allow a teacher to update a category in other courses" do
        og_course = @course
        course = course_factory(course_name: "Math 101", account: @account, active_course: true)
        category2 = GroupCategory.student_organized_for(course)
        json = api_call(:put,
                        "/api/v1/group_categories/#{category2.id}",
                        @category_path_options.merge(action: "update", group_category_id: category2.to_param),
                        { :name => @name, :self_signup => "enabled", "create_group_count" => 3, :course_id => og_course.id },
                        {},
                        { expected_status: 401 })
        expect(json["status"]).to eq "unauthorized"
        expect(category2.reload.name).to_not eq @name
      end

      it "allows a teacher to update a category and distribute students to new groups" do
        create_users_in_course(@course, 6)
        json = api_call :put,
                        "/api/v1/group_categories/#{@category.id}",
                        @category_path_options.merge(action: "update",
                                                     group_category_id: @category.to_param),
                        { name: @name, split_group_count: 3 }
        category = GroupCategory.find(json["id"])
        groups = category.groups.active
        expect(groups.count).to eq 3
        expect(groups[0].users.count).to eq 2
        expect(groups[1].users.count).to eq 2
        expect(groups[2].users.count).to eq 2
      end

      it "creates group category/groups and split students between groups" do
        create_users_in_course(@course, 6)
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        { "name" => @name, "split_group_count" => 3 })
        category = GroupCategory.find(json["id"])
        groups = category.groups.active
        expect(groups.count).to eq 3
        expect(groups[0].users.count).to eq 2
        expect(groups[1].users.count).to eq 2
        expect(groups[2].users.count).to eq 2
      end

      it "creates self signup groups" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        { "name" => @name, "self_signup" => "enabled", "create_group_count" => 3 })
        category = GroupCategory.find(json["id"])
        expect(category.self_signup).to eq "enabled"
        groups = category.groups.active
        expect(groups.count).to eq 3
      end

      it "creates restricted self sign up groups" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        {
                          "name" => @name,
                          "self_signup" => "restricted",
                          "create_group_count" => 3
                        })
        category = GroupCategory.find(json["id"])
        expect(category.self_signup).to eq "restricted"
        groups = category.groups.active
        expect(groups.count).to eq 3
      end

      it "ignores 'split_group_count' if 'enable_self_signup'" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        {
                          "name" => @name,
                          "enable_self_signup" => "1",
                          "split_group_count" => 3
                        })
        category = GroupCategory.find(json["id"])
        expect(category.self_signup).to eq "enabled"
        expect(category.groups.active).to be_empty
      end

      it "prefers 'split_group_count' over 'create_group_count' if not 'enable_self_signup'" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     course_id: @course.to_param),
                        {
                          "name" => @name,
                          "create_group_count" => 3,
                          "split_group_count" => 2
                        })
        category = GroupCategory.find(json["id"])
        expect(category.groups.active.size).to eq 2
      end

      describe "teacher actions with a group" do
        before :once do
          @study_group = group_model(name: @name,
                                     group_category: @category,
                                     context: @course,
                                     root_account_id: @account.id)
        end

        it "allows listing all of a course's group categories for teachers" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.to_param}/group_categories.json",
                          @category_path_options.merge(action: "index",
                                                       course_id: @course.to_param))
          expect(json.count).to eq 1
          expect(json.first["id"]).to eq @category.id
        end

        it "allows teachers to retrieve a group category" do
          json = api_call(:get,
                          "/api/v1/group_categories/#{@category.id}",
                          @category_path_options.merge(action: "show",
                                                       group_category_id: @category.to_param))
          expect(json["id"]).to eq @category.id
        end

        it "lists all groups in category for a teacher" do
          json = api_call(:get,
                          "/api/v1/group_categories/#{@category.id}/groups",
                          @category_path_options.merge(action: "groups",
                                                       group_category_id: @category.to_param))
          expect(json.first["id"]).to eq @study_group.id
        end

        it "allows a teacher to update a category for a course" do
          api_call :put,
                   "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(action: "update",
                                                group_category_id: @category.to_param),
                   { name: @name }
          category = GroupCategory.find(@category.id)
          expect(category.name).to eq @name
        end

        it "allows a teacher to update a category to self_signup enabled for a course" do
          api_call :put,
                   "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(action: "update",
                                                group_category_id: @category.to_param),
                   { name: @name, self_signup: "enabled" }
          category = GroupCategory.find(@category.id)
          expect(category.self_signup).to eq "enabled"
          expect(category.name).to eq @name
        end

        it "allows a teacher to update a category to self_signup restricted for a course" do
          api_call :put,
                   "/api/v1/group_categories/#{@category.id}",
                   @category_path_options.merge(action: "update",
                                                group_category_id: @category.to_param),
                   { name: @name, self_signup: "restricted" }
          category = GroupCategory.find(@category.id)
          expect(category.self_signup).to eq "restricted"
          expect(category.name).to eq @name
        end

        it "allows a teacher to delete a category for a course" do
          project_groups = @course.group_categories.build
          project_groups.name = @name
          project_groups.save
          expect(GroupCategory.find(project_groups.id)).not_to be_nil
          api_call :delete,
                   "/api/v1/group_categories/#{project_groups.id}",
                   @category_path_options.merge(action: "destroy",
                                                group_category_id: project_groups.to_param)
          expect(GroupCategory.find(project_groups.id).deleted_at).not_to be_nil
        end

        it "allows a teacher to delete the imported groups category for a course" do
          project_groups = @course.group_categories.build
          project_groups.name = @name
          project_groups.role = "imported"
          project_groups.save
          expect(GroupCategory.find(project_groups.id)).not_to be_nil
          api_call :delete,
                   "/api/v1/group_categories/#{project_groups.id}",
                   @category_path_options.merge(action: "destroy",
                                                group_category_id: project_groups.to_param)
          expect(GroupCategory.find(project_groups.id).deleted_at).not_to be_nil
        end

        it "does not allow a teacher to delete the communities category for a course" do
          project_groups = @course.group_categories.build
          project_groups.name = @name
          project_groups.role = "communities"
          project_groups.save
          expect(GroupCategory.find(project_groups.id)).not_to be_nil
          api_call :delete,
                   "/api/v1/group_categories/#{project_groups.id}",
                   @category_path_options.merge(action: "destroy",
                                                group_category_id: project_groups.to_param),
                   {},
                   {},
                   { expected_status: 401 }
          expect(GroupCategory.find(project_groups.id).deleted_at).to be_nil
        end

        it "allows a teacher to create a course group category" do
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/group_categories",
                          @category_path_options.merge(action: "create",
                                                       course_id: @course.to_param),
                          { "name" => @name })
          category = GroupCategory.find(json["id"])
          expect(json["context_type"]).to eq "Course"
          expect(category.name).to eq @name
          expect(json).to eq category_json(category)
        end
      end
    end

    describe "student actions" do
      before :once do
        @user = user_factory(name: "derrik hans")
        @course.enroll_user(@user, "StudentEnrollment", enrollment_state: :active)
      end

      it "does not allow listing of a course's group categories for students" do
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.to_param}/group_categories.json",
                     @category_path_options.merge(action: "index",
                                                  course_id: @course.to_param))
        expect(response).to have_http_status :unauthorized
      end

      it "does not list all groups in category for a student" do
        raw_api_call(:get,
                     "/api/v1/group_categories/#{@category.id}/groups",
                     @category_path_options.merge(action: "groups",
                                                  group_category_id: @category.to_param))
        expect(response).to have_http_status :unauthorized
      end

      it "does not allow a student to create a course group category" do
        name = "Discussion Groups"
        raw_api_call(:post,
                     "/api/v1/courses/#{@course.id}/group_categories",
                     @category_path_options.merge(action: "create",
                                                  course_id: @course.to_param),
                     { "name" => name })
        expect(response).to have_http_status :unauthorized
      end

      it "does not allow a teacher to delete the student groups category" do
        expect(GroupCategory.find(@category.id)).not_to be_nil
        raw_api_call :delete,
                     "/api/v1/group_categories/#{@category.id}",
                     @category_path_options.merge(action: "destroy",
                                                  group_category_id: @category.to_param)
        expect(response).to have_http_status :unauthorized
      end

      it "does not allow a student to delete a category for a course" do
        project_groups = @course.group_categories.build
        project_groups.name = "Course Project Groups"
        project_groups.save
        expect(GroupCategory.find(project_groups.id)).not_to be_nil
        raw_api_call :delete,
                     "/api/v1/group_categories/#{project_groups.id}",
                     @category_path_options.merge(action: "destroy",
                                                  group_category_id: project_groups.to_param)
        expect(response).to have_http_status :unauthorized
      end

      it "does not allow a student to update a category for a course" do
        raw_api_call :put,
                     "/api/v1/group_categories/#{@category.id}",
                     @category_path_options.merge(action: "update",
                                                  group_category_id: @category.to_param),
                     { name: "name" }
        expect(response).to have_http_status :unauthorized
      end
    end

    describe "POST 'assign_unassigned_members'" do
      it "requires :manage_groups permission" do
        course_with_teacher(active_all: true)
        @course.enroll_student(user_model)
        category = @course.group_categories.create(name: "Group Category")

        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: category.to_param),
                     { "sync" => true }
        assert_status(401)
      end

      it "requires valid group :category_id" do
        course_with_teacher_logged_in(active_all: true)
        category = @course.group_categories.create(name: "Group Category")

        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id + 1}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: (category.id + 1).to_param),
                     { "sync" => true }
        assert_status(404)
      end

      it "fails for student organized groups" do
        course_with_teacher_logged_in(active_all: true)
        category = GroupCategory.student_organized_for(@course)

        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: category.to_param),
                     { "sync" => true }
        assert_status(400)
      end

      it "fails for restricted self signup groups" do
        course_with_teacher_logged_in(active_all: true)
        category = @course.group_categories.build(name: "Group Category")
        category.configure_self_signup(true, true)
        category.save

        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: category.to_param),
                     { "sync" => true }
        assert_status(400)

        category.configure_self_signup(true, false)
        category.save

        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: category.to_param),
                     { "sync" => true }
        expect(response).to be_successful
      end

      it "otherwises assign ungrouped users to groups in the category" do
        course_with_teacher_logged_in(active_all: true)
        teacher = @user
        category = @course.group_categories.create(name: "Group Category")
        group1 = category.groups.create(name: "Group 1", context: @course)
        group2 = category.groups.create(name: "Group 2", context: @course)
        student1 = @course.enroll_student(user_model).user
        student2 = @course.enroll_student(user_model).user # not in a group
        group2.add_user(student1)

        @user = teacher
        raw_api_call :post,
                     "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                     @category_path_options.merge(action: "assign_unassigned_members",
                                                  group_category_id: category.to_param)

        expect(response).to be_successful

        run_jobs

        expect(group1.reload.users).to include(student2)
      end

      it "renders progress_json" do
        course_with_teacher_logged_in(active_all: true)
        category = @course.group_categories.create(name: "Group Category")

        expect do
          raw_api_call :post,
                       "/api/v1/group_categories/#{category.id}/assign_unassigned_members",
                       @category_path_options.merge(action: "assign_unassigned_members",
                                                    group_category_id: category.to_param)

          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json["url"]).to match Regexp.new("http://www.example.com/api/v1/progress/\\d+")
          expect(json["completion"]).to eq 0
        end.to change(Delayed::Job, :count).by(1)
      end
    end
  end

  describe "account group categories" do
    before :once do
      @communities = GroupCategory.communities_for(@account)
    end

    describe "admin actions" do
      before :once do
        @user = account_admin_user(account: @account)
      end

      it "allows listing all of an account's group categories for account admins" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                        @category_path_options.merge(action: "index",
                                                     account_id: @account.to_param))
        expect(json.count).to eq 1
        expect(json.first["id"]).to eq @communities.id
      end

      it "ignores 'split_group_count' for a non course group" do
        json = api_call(:post,
                        "/api/v1/accounts/#{@account.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     account_id: @account.to_param),
                        {
                          "name" => "category",
                          "split_group_count" => 3
                        })
        category = GroupCategory.find(json["id"])
        expect(category.groups.active).to be_empty
      end

      it "allows admins to retrieve a group category" do
        json = api_call(:get,
                        "/api/v1/group_categories/#{@communities.id}",
                        @category_path_options.merge(action: "show",
                                                     group_category_id: @communities.to_param))
        expect(json["id"]).to eq @communities.id
      end

      it "returns a 'not found' error if there is no group_category" do
        raw_api_call(:get,
                     "/api/v1/group_categories/9999999",
                     @category_path_options.merge(action: "show",
                                                  group_category_id: "9999999"))
        expect(response).to have_http_status :not_found
      end

      it "lists all groups in category for a admin" do
        @community = group_model(name: "Algebra Teacher",
                                 group_category: @communities,
                                 context: @account)
        json = api_call(:get,
                        "/api/v1/group_categories/#{@communities.id}/groups",
                        @category_path_options.merge(action: "groups",
                                                     group_category_id: @communities.to_param))
        expect(json.first["id"]).to eq @community.id
      end

      it "allows an admin to create an account group category" do
        json = api_call(:post,
                        "/api/v1/accounts/#{@account.id}/group_categories",
                        @category_path_options.merge(action: "create",
                                                     sis_group_category_id: "gc101",
                                                     account_id: @account.to_param),
                        { "name" => "name" })
        category = GroupCategory.find(json["id"])
        expect(json["context_type"]).to eq "Account"
        expect(category.name).to eq "name"
        expect(category.sis_source_id).to eq "gc101"
        expect(json).to eq category_json(category)
      end

      it "allows an admin to update a category for an account" do
        api_call :put,
                 "/api/v1/group_categories/#{@communities.id}",
                 @category_path_options.merge(action: "update",
                                              sis_group_category_id: "gc101",
                                              group_category_id: @communities.to_param),
                 { name: "name" }
        category = GroupCategory.find(@communities.id)
        expect(category.name).to eq "name"
        expect(category.sis_source_id).to eq "gc101"
      end

      it "allows an admin to delete a category for an account" do
        account_category = GroupCategory.create(name: "Groups", context: @account)
        expect(GroupCategory.find(@communities.id)).not_to be_nil
        raw_api_call :delete,
                     "/api/v1/group_categories/#{account_category.id}",
                     @category_path_options.merge(action: "destroy",
                                                  group_category_id: account_category.to_param)
        expect(GroupCategory.find(account_category.id).deleted_at).not_to be_nil
      end

      it "does not allow 'enable_self_signup' for a non course group" do
        raw_api_call(:post,
                     "/api/v1/accounts/#{@account.id}/group_categories",
                     @category_path_options.merge(action: "create",
                                                  account_id: @account.to_param),
                     {
                       "name" => "name",
                       "enable_self_signup" => "1",
                       "create_group_count" => 3
                     })
        expect(response).to have_http_status :bad_request
      end

      describe "sis permissions" do
        let(:json) do
          api_call(:get,
                   "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                   @category_path_options.merge(action: "index",
                                                account_id: @account.to_param))
        end
        let(:admin) { admin_role(root_account_id: @account.resolved_root_account_id) }

        before do
          @user = User.create!(name: "billy")
          @account.account_users.create(user: @user)
        end

        it "shows SIS fields if the user has permission", priority: 3 do
          expect(json[0]).to have_key("sis_group_category_id")
          expect(json[0]).to have_key("sis_import_id")
        end

        it "shows only sis_group_category_id without manage_sis permission", priority: 3 do
          @account.role_overrides.create(role: admin, enabled: false, permission: :manage_sis)
          expect(json[0]).to have_key("sis_group_category_id")
          expect(json[0]).not_to have_key("sis_import_id")
        end

        it "does not show SIS fields if the user doesn't have permission", priority: 3 do
          @account.role_overrides.create(role: admin, enabled: false, permission: :read_sis)
          @account.role_overrides.create(role: admin, enabled: false, permission: :manage_sis)
          expect(json[0]).not_to have_key("sis_group_category_id")
          expect(json[0]).not_to have_key("sis_import_id")
        end
      end
    end

    it "does not allow non-admins to list an account's group categories" do
      raw_api_call(:get,
                   "/api/v1/accounts/#{@account.to_param}/group_categories.json",
                   @category_path_options.merge(action: "index",
                                                account_id: @account.to_param))
      expect(response).to have_http_status :unauthorized
    end

    it "does not allow non-admins to retrieve a group category" do
      raw_api_call(:get,
                   "/api/v1/group_categories/#{@communities.id}",
                   @category_path_options.merge(action: "show",
                                                group_category_id: @communities.to_param))
      expect(response).to have_http_status :unauthorized
    end

    it "does not allow a non-admin to delete a category for an account" do
      account_category = GroupCategory.create(name: "Groups", context: @account)
      raw_api_call :delete,
                   "/api/v1/group_categories/#{account_category.id}",
                   @category_path_options.merge(action: "destroy",
                                                group_category_id: account_category.to_param)
      expect(response).to have_http_status :unauthorized
    end

    it "does not list all groups in category for a non-admin" do
      raw_api_call(:get,
                   "/api/v1/group_categories/#{@communities.id}/groups",
                   @category_path_options.merge(action: "groups",
                                                group_category_id: @communities.to_param))
      expect(response).to have_http_status :unauthorized
    end

    it "does not allow a non-admin to create an account group category" do
      raw_api_call(:post,
                   "/api/v1/accounts/#{@account.id}/group_categories",
                   @category_path_options.merge(action: "create",
                                                account_id: @account.to_param),
                   { "name" => "name" })
      expect(response).to have_http_status :unauthorized
    end

    it "does not allow a non-admin to update a category for an account" do
      raw_api_call :put,
                   "/api/v1/group_categories/#{@communities.id}",
                   @category_path_options.merge(action: "update",
                                                group_category_id: @communities.to_param),
                   { name: "name" }
      expect(response).to have_http_status :unauthorized
    end
  end
end
