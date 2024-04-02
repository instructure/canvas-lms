# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "feedjira"

describe GroupsController do
  before :once do
    course_with_teacher(active_all: true)
    students = create_users_in_course(@course, 3, return_type: :record)
    @student1, @student2, @student3 = students
    @student = @student1
  end

  describe "GET context_index" do
    context "student context cards" do
      it "is always enabled for teachers" do
        %w[manage_students manage_admin_users].each do |perm|
          RoleOverride.manage_role_override(Account.default, teacher_role, perm, override: false)
        end
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be true
      end

      it "is always disabled for students" do
        user_session(@student)
        get "index", params: { course_id: @course.id }
        cards_enabled = assigns[:js_env] && assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]
        expect(cards_enabled).to be_falsey
      end
    end

    it "requires authorization" do
      user_session(user_factory) # logged in user_factory without course access
      category1 = @course.group_categories.create(name: "category 1")
      category2 = @course.group_categories.create(name: "category 2")
      @course.groups.create(name: "some group", group_category: category1)
      @course.groups.create(name: "some other group", group_category: category1)
      @course.groups.create(name: "some third group", group_category: category2)
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@teacher)
      category1 = @course.group_categories.create(name: "category 1")
      category2 = @course.group_categories.create(name: "category 2")
      g1 = @course.groups.create(name: "some group", group_category: category1)
      g2 = @course.groups.create(name: "some other group", group_category: category1)
      g3 = @course.groups.create(name: "some third group", group_category: category2)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:groups]).not_to be_empty
      expect(assigns[:groups].length).to be(3)
      expect(assigns[:groups] - [g1, g2, g3]).to be_empty
      expect(assigns[:categories].length).to be(2)
    end

    it "returns groups in sorted by group category name, then group name for student view" do
      user_session(@student)
      category1 = @course.group_categories.create(name: "1")
      category2 = @course.group_categories.create(name: "2")
      category3 = @course.group_categories.create(name: "11")
      groups = []
      groups << @course.groups.create(name: "11", group_category: category1)
      groups << @course.groups.create(name: "2", group_category: category1)
      groups << @course.groups.create(name: "1", group_category: category1)
      groups << @course.groups.create(name: "22", group_category: category2)
      groups << @course.groups.create(name: "2", group_category: category2)
      groups << @course.groups.create(name: "3", group_category: category2)
      groups << @course.groups.create(name: "4", group_category: category3)
      groups << @course.groups.create(name: "44", group_category: category3)
      groups << @course.groups.create(name: "4.5", group_category: category3)
      groups.each { |g| g.add_user @student, "accepted" }
      get "index", params: { course_id: @course.id, per_page: 50 }, format: "json"
      expect(response).to be_successful
      expect(assigns[:paginated_groups]).not_to be_empty
      expect(assigns[:paginated_groups].length).to be(9)
      # Check group category ordering
      expect(assigns[:paginated_groups][0].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][1].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][2].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][3].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][4].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][5].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][6].group_category.name).to eql("11")
      expect(assigns[:paginated_groups][7].group_category.name).to eql("11")
      expect(assigns[:paginated_groups][8].group_category.name).to eql("11")
      # Check group name ordering
      expect(assigns[:paginated_groups][0].name).to eql("1")
      expect(assigns[:paginated_groups][1].name).to eql("2")
      expect(assigns[:paginated_groups][2].name).to eql("11")
      expect(assigns[:paginated_groups][3].name).to eql("2")
      expect(assigns[:paginated_groups][4].name).to eql("3")
      expect(assigns[:paginated_groups][5].name).to eql("22")
      expect(assigns[:paginated_groups][6].name).to eql("4")
      expect(assigns[:paginated_groups][7].name).to eql("4.5")
      expect(assigns[:paginated_groups][8].name).to eql("44")
    end

    it "does not 500 for admins that can view but cannot manage groups" do
      a = Account.default
      role = custom_account_role("groups-view-only", account: a)
      a.role_overrides.create! role:, permission: "manage_groups", enabled: false
      a.role_overrides.create! role:, permission: "read_roster", enabled: true
      a.role_overrides.create! role:, permission: "view_group_pages", enabled: true

      my_admin = User.create!(name: "my admin")
      a.account_users.create!(user: my_admin, role:)

      course_with_teacher(active_all: true)
      user_session(my_admin)
      category1 = @course.group_categories.create(name: "category 1")
      @course.groups.create(name: "some group", group_category: category1)
      get "index", params: { course_id: @course.id, section_restricted: true }, format: :json
      expect(response).to have_http_status :ok
    end

    it "don't filter out inactive students if json and param set" do
      course_with_teacher(active_all: true)
      students = create_users_in_course(@course, 2, return_type: :record)
      student1, student2 = students
      category1 = @course.group_categories.create(name: "category 1")
      g = @course.groups.create(name: "some group", group_category: category1)
      g.add_user(student1)
      g.add_user(student2)
      student2.enrollments.first.deactivate
      user_session(student1)
      get "index",
          params: { course_id: @course.id,
                    include: "users",
                    include_inactive_users: true },
          format: :json
      parsed_json = json_parse(response.body)
      expect(parsed_json.length).to eq 1
      users_json = parsed_json.first["users"]
      expect(users_json).not_to be_nil
      expect(users_json.length).to eq 2
      ids_json = users_json.to_set { |u| u["id"] }
      expect(ids_json).to eq [student1.id, student2.id].to_set
      names_json = users_json.to_set { |u| u["name"] }
      expect(names_json).to eq [student1.name, student2.name].to_set
      expect(response).to be_successful
    end

    context "section_restricted" do
      before do
        # Create a section restricted user in their own section
        @section1 = @course.course_sections.first
        @other_section = @course.course_sections.create!(name: "Other Section")
        @section_restricted_student = @course.enroll_student(user_model, section: @other_section, enrollment_state: "active").user
        @section_restricted_student_2 = @course.enroll_student(user_model, section: @other_section, enrollment_state: "active").user
        @section_restricted_student_3 = @course.enroll_student(user_model, section: @other_section, enrollment_state: "active").user
        @other_student = @course.enroll_student(user_model, section: @section1, enrollment_state: "active").user
        Enrollment.limit_privileges_to_course_section!(@course, @section_restricted_student, true)
        Enrollment.limit_privileges_to_course_section!(@course, @section_restricted_student_2, true)
        Enrollment.limit_privileges_to_course_section!(@course, @section_restricted_student_3, true)
      end

      context "teacher assigned group category" do
        before do
          # Create a groupset that allows self-signup and requires group members to be in same section
          @group_category = GroupCategory.create(name: "Groups", context: @course)
          @group_category.save!
        end

        it "does not show section restricted students groups with non-section members" do
          # Group with the restricted user
          group_with_section_restricted_user = @course.groups.create(name: "restricted 1", group_category: @group_category)
          group_with_section_restricted_user.add_user(@section_restricted_student)
          group_with_section_restricted_user.save

          # Group with student from another section
          group_with_user_in_different_section = @course.groups.create(name: "different section", group_category: @group_category)
          group_with_user_in_different_section.add_user(@other_student)
          group_with_user_in_different_section.save

          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(1)
          expect(assigns[:groups].length).to be(1)
          expect(assigns[:groups][0].id).to eql(group_with_section_restricted_user.id)
        end

        it "does not hide group if you are a group member" do
          # Group with a section_restricted user
          group_with_section_restricted_user = @course.groups.create(name: "restricted 1", group_category: @group_category)
          group_with_section_restricted_user.add_user(@section_restricted_student_2)
          group_with_section_restricted_user.save

          # Group with student from another section
          group_with_user_in_different_section = @course.groups.create(name: "different section", group_category: @group_category)
          group_with_user_in_different_section.add_user(@other_student)
          group_with_user_in_different_section.add_user(@section_restricted_student)
          group_with_user_in_different_section.save

          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(2)
          expect(assigns[:groups].length).to be(2)
          expect(assigns[:groups].map(&:id).sort).to eql(@group_category.groups.map(&:id).sort)
        end
      end

      context "self-signup non-section restricted group category" do
        it "does not hide any groups from section restricted students" do
          # Group Category that does not restrict sections of students
          @group_category_non_restricted = GroupCategory.student_organized_for(@course)
          @group_category_non_restricted.configure_self_signup(true, false)
          @group_category_non_restricted.save!

          # Group with the restricted user
          group_with_section_restricted_user = @course.groups.create(name: "restricted 1", group_category: @group_category_non_restricted)
          group_with_section_restricted_user.add_user(@section_restricted_student)
          group_with_section_restricted_user.save

          # Group with student from another section
          group_with_user_in_different_section = @course.groups.create(name: "different section", group_category: @group_category_non_restricted)
          group_with_user_in_different_section.add_user(@other_student)
          group_with_user_in_different_section.save

          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(2)
          expect(assigns[:groups].length).to be(2)
          expect(assigns[:groups].map(&:id).sort).to eql(@group_category_non_restricted.groups.map(&:id).sort)
        end
      end

      context "self-signup restricted group category" do
        before do
          # Create a groupset that allows self-signup and requires group members to be in same section
          @group_category = GroupCategory.student_organized_for(@course)
          @group_category.configure_self_signup(true, true)
          @group_category.group_limit = 2
          @group_category.save!
        end

        it "does not remove groups for teachers" do
          # Group with the restricted user
          group_with_section_restricted_user = @course.groups.create(name: "restricted 1", group_category: @group_category)
          group_with_section_restricted_user.add_user(@section_restricted_student)
          group_with_section_restricted_user.save

          # Group with student from another section
          group_with_user_in_different_section = @course.groups.create(name: "different section", group_category: @group_category)
          group_with_user_in_different_section.add_user(@other_student)
          group_with_user_in_different_section.save

          # Teacher
          user_session(@teacher)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(2)
          expect(assigns[:groups].length).to be(2)
          expect(assigns[:groups].map(&:id).sort).to eql(@group_category.groups.map(&:id).sort)
        end

        it "does not remove empty groups" do
          # Empty Group
          group_with_user_in_different_section = @course.groups.create(name: "Empty group", group_category: @group_category)
          group_with_user_in_different_section.save

          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(1)
          expect(assigns[:groups].length).to be(1)
          expect(assigns[:groups][0].id).to eql(group_with_user_in_different_section.id)
        end

        it "does not remove full groups if users have the same section as the current user" do
          # Group with the second restricted user
          group_with_section_restricted_user_2 = @course.groups.create(name: "restricted and full group", group_category: @group_category)
          group_with_section_restricted_user_2.add_user(@section_restricted_student_2)
          group_with_section_restricted_user_2.add_user(@section_restricted_student_3)
          group_with_section_restricted_user_2.save

          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(1)
          expect(assigns[:groups].length).to be(1)
          expect(assigns[:groups][0].id).to eql(group_with_section_restricted_user_2.id)
        end

        it "does not show groups with students from other sections to section restricted students" do
          # Group with the restricted user
          group_with_section_restricted_user = @course.groups.create(name: "restricted 1", group_category: @group_category)
          group_with_section_restricted_user.add_user(@section_restricted_student)
          group_with_section_restricted_user.save

          # Group with student from another section
          group_with_user_in_different_section = @course.groups.create(name: "different section", group_category: @group_category)
          group_with_user_in_different_section.add_user(@other_student)
          group_with_user_in_different_section.save
          # Restricted user is logged in
          user_session(@section_restricted_student)
          get "index", params: { course_id: @course.id, section_restricted: true }, format: :json

          expect(response).to be_successful
          expect(json_parse(response.body).length).to be(1)
          expect(assigns[:groups].length).to be(1)
          expect(assigns[:groups][0].id).to eql(group_with_section_restricted_user.id)
        end
      end
    end
  end

  describe "GET index" do
    it "splits up current and previous groups" do
      course1 = @course
      group_with_user(group_context: course1, user: @student, active_all: true)
      group1 = @group

      course_with_teacher(active_all: true)
      course2 = @course

      course2.soft_conclude!
      course2.save!

      create_enrollments(course2, [@student])
      group_with_user(group_context: course2, user: @student, active_all: true)
      group2 = @group

      user_session(@student)

      get "index"
      expect(assigns[:current_groups]).to eq([group1])
      expect(assigns[:previous_groups]).to eq([group2])
    end

    it "does not show restricted previous groups" do
      group_with_user(group_context: @course, user: @student, active_all: true)

      @course.soft_conclude!
      @course.restrict_student_past_view = true
      @course.save!

      user_session(@student)

      get "index"
      expect(assigns[:current_groups]).to eq([])
      expect(assigns[:previous_groups]).to eq([])
    end

    it 'puts groups in courses in terms concluded for students in "previous groups"' do
      @course.enrollment_term.set_overrides(@course.account, "StudentEnrollment" => { end_at: 1.week.ago })
      group_with_user(group_context: @course, user: @student, active_all: true)
      user_session(@student)
      get "index"
      expect(assigns[:current_groups]).to eq([])
      expect(assigns[:previous_groups]).to eq([@group])
    end

    describe "pagination" do
      before :once do
        group_with_user(group_context: @course, user: @student, active_all: true)
        group_with_user(group_context: @course, user: @student, active_all: true)
      end

      before do
        user_session(@student)
      end

      it "does not paginate non-json" do
        get "index", params: { per_page: 1 }
        expect(assigns[:current_groups]).to eq @student.current_groups.by_name
        expect(response.headers["Link"]).to be_nil
      end

      it "paginates json" do
        get "index", params: { per_page: 1 }, format: "json"
        expect(assigns[:groups]).to eq [@student.current_groups.by_name.first]
        expect(response.headers["Link"]).not_to be_nil
      end
    end
  end

  describe "GET show" do
    it "requires authorization" do
      @group = Account.default.groups.create!(name: "some group")
      get "show", params: { id: @group.id }
      expect(assigns[:group]).to eql(@group)
      assert_unauthorized
    end

    it "assigns variables" do
      @group = Account.default.groups.create!(name: "some group")
      @user = user_model
      user_session(@user)
      @group.add_user(@user)
      get "show", params: { id: @group.id }
      expect(response).to be_successful
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:context]).to eql(@group)
      expect(assigns[:stream_items]).to eql([])
    end

    it "allows user to join self-signup groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(name: "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(name: "some group", group_category: category1)

      get "show", params: { course_id: @course.id, id: g1.id, join: 1 }
      g1.reload
      expect(g1.users.map(&:id)).to include @student.id
    end

    it "allows user to leave self-signup groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(name: "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(name: "some group", group_category: category1)
      g1.add_user(@student)

      get "show", params: { course_id: @course.id, id: g1.id, leave: 1 }
      g1.reload
      expect(g1.users.map(&:id)).not_to include @student.id
    end

    it "allows user to join student organized groups" do
      user_session(@student)
      category1 = GroupCategory.student_organized_for(@course)
      g1 = @course.groups.create!(name: "some group", group_category: category1, join_level: "parent_context_auto_join")

      get "show", params: { course_id: @course.id, id: g1.id, join: 1 }
      g1.reload
      expect(g1.users.map(&:id)).to include @student.id
    end

    it "allows user to leave student organized groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(name: "category 1", role: "student_organized")
      g1 = @course.groups.create!(name: "some group", group_category: category1)
      g1.add_user(@student)

      get "show", params: { course_id: @course.id, id: g1.id, leave: 1 }
      g1.reload
      expect(g1.users.map(&:id)).not_to include @student.id
    end

    it "allows teachers to view after conclusion" do
      @teacher.enrollments.first.conclude
      user_session(@teacher)
      category = @course.group_categories.create(name: "category")
      group = @course.groups.create(name: "some group", group_category: category)

      get "show", params: { id: group.id }

      expect(response).to be_successful
      expect(assigns[:group]).to eql(group)
    end
  end

  describe "GET new" do
    it "requires authorization" do
      @group = @course.groups.create!(name: "some group")
      get "new", params: { course_id: @course.id }
      assert_unauthorized
    end
  end

  describe "POST add_user" do
    it "requires authorization" do
      @group = Account.default.groups.create!(name: "some group")
      post "add_user", params: { group_id: @group.id }
      assert_unauthorized
    end

    it "adds user" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "PG 1", group_category: @category)
      @user = user_factory(active_all: true)
      post "add_user", params: { group_id: @group.id, user_id: @user.id }
      expect(response).to be_successful
      expect(assigns[:membership]).not_to be_nil
      expect(assigns[:membership].user).to eql(@user)
    end

    it "checks user section in restricted self-signup category" do
      user_session(@teacher)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, "StudentEnrollment").user
      user2 = section2.enroll_user(user_model, "StudentEnrollment").user
      group_category = @course.group_categories.build(name: "My Category")
      group_category.configure_self_signup(true, true)
      group_category.save
      group = group_category.groups.create(context: @course)
      group.add_user(user1)

      post "add_user", params: { group_id: group.id, user_id: user2.id }
      expect(response).not_to be_successful
      expect(assigns[:membership]).not_to be_nil
      expect(assigns[:membership].user).to eql(user2)
      expect(assigns[:membership].errors[:user_id]).not_to be_nil
    end
  end

  describe "DELETE remove_user" do
    it "requires authorization" do
      @group = Account.default.groups.create!(name: "some group")
      @user = user_factory(active_all: true)
      @group.add_user(@user)
      delete "remove_user", params: { group_id: @group.id, user_id: @user.id, id: @user.id }
      assert_unauthorized
    end

    it "removes user" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "PG 1", group_category: @category)
      @group.add_user(@user)
      delete "remove_user", params: { group_id: @group.id, user_id: @user.id, id: @user.id }
      expect(response).to be_successful
      @group.reload
      expect(@group.users).to be_empty
    end
  end

  describe "POST create" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id, group: { name: "some group" } }
      assert_unauthorized
    end

    it "creates new group" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, group: { name: "some group" } }
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].name).to eql("some group")
    end

    it "creates new group (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      post "create", params: { course_id: @course.id, group: { name: "some group" } }
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].name).to eql("some group")
    end

    it "does not create new group if :manage_groups_add is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(
        permission: "manage_groups_add",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      post "create", params: { course_id: @course.id, group: { name: "some group" } }
      assert_unauthorized
    end

    it "honors group[group_category_id] when permitted" do
      user_session(@teacher)
      group_category = @course.group_categories.create(name: "some category")
      post "create", params: { course_id: @course.id, group: { name: "some group", group_category_id: group_category.id } }
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].group_category).to eq group_category
    end

    it "does not honor group[group_category_id] when not permitted" do
      user_session(@student)
      group_category = @course.group_categories.create(name: "some category")
      post "create", params: { course_id: @course.id, group: { name: "some group", group_category_id: group_category.id } }
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].group_category).to eq GroupCategory.student_organized_for(@course)
    end

    it "fails when group[group_category_id] would be honored but doesn't exist" do
      user_session(@student)
      @course.group_categories.create(name: "some category")
      post "create", params: { course_id: @course.id, group: { name: "some group", group_category_id: 11_235 } }
      expect(response).not_to be_successful
    end

    describe "quota" do
      before do
        Setting.set("group_default_quota", 11.megabytes)
      end

      context "teacher" do
        before do
          user_session(@teacher)
        end

        it "ignores the storage_quota_mb parameter" do
          post "create", params: { course_id: @course.id, group: { name: "a group", storage_quota_mb: 22 } }
          expect(assigns[:group].storage_quota_mb).to eq 11
        end
      end

      context "account admin" do
        before do
          account_admin_user
          user_session(@admin)
        end

        it "sets the storage_quota_mb parameter" do
          post "create", params: { course_id: @course.id, group: { name: "a group", storage_quota_mb: 22 } }
          expect(assigns[:group].storage_quota_mb).to eq 22
        end
      end
    end
  end

  describe "PUT update" do
    it "requires authorization" do
      @group = @course.groups.create!(name: "some group")
      put "update", params: { course_id: @course.id, id: @group.id, group: { name: "new name" } }
      assert_unauthorized
    end

    it "updates group" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      put "update", params: { course_id: @course.id, id: @group.id, group: { name: "new name" } }
      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].name).to eql("new name")
    end

    it "updates group (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      put "update", params: { course_id: @course.id, id: @group.id, group: { name: "new name" } }
      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].name).to eql("new name")
    end

    it "does not update group if :manage_groups_manage is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(
        permission: "manage_groups_manage",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      put "update", params: { course_id: @course.id, id: @group.id, group: { name: "new name" } }
      assert_unauthorized
    end

    it "honors group[group_category_id]" do
      user_session(@teacher)
      group_category = @course.group_categories.create(name: "some category")
      @group = @course.groups.create!(name: "some group")
      put "update", params: { course_id: @course.id, id: @group.id, group: { group_category_id: group_category.id } }
      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].group_category).to eq group_category
    end

    it "fails when group[group_category_id] doesn't exist" do
      user_session(@teacher)
      group_category = @course.group_categories.create(name: "some category")
      @group = @course.groups.create!(name: "some group", group_category:)
      put "update", params: { course_id: @course.id, id: @group.id, group: { group_category_id: 11_235 } }
      expect(response).not_to be_successful
    end

    it "is able to unset a leader" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      @group.add_user(@student1)
      @group.update_attribute(:leader, @student1)
      put "update", params: { course_id: @course.id, id: @group.id, group: { leader: nil } }
      expect(@group.reload.leader).to be_nil
    end

    it "doesn't overwrite stuck sis fields" do
      user_session(@teacher)
      original_name = "some group"
      @group = @course.groups.create!(name: original_name)
      put "update", params: { course_id: @course.id, id: @group.id, override_sis_stickiness: false, group: { name: "new name" } }

      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].name).to eql(original_name)
    end

    describe "quota" do
      before :once do
        @group = @course.groups.build(name: "teh gruop")
        @group.storage_quota_mb = 11
        @group.save!
      end

      context "teacher" do
        before do
          user_session(@teacher)
        end

        it "ignores the quota parameter" do
          put "update", params: { course_id: @course.id, id: @group.id, group: { name: "the group", storage_quota_mb: 22 } }
          @group.reload
          expect(@group.name).to eq "the group"
          expect(@group.storage_quota_mb).to eq 11
        end
      end

      context "account admin" do
        before do
          account_admin_user
          user_session(@admin)
        end

        it "updates group quota" do
          put "update", params: { course_id: @course.id, id: @group.id, group: { name: "the group", storage_quota_mb: 22 } }
          @group.reload
          expect(@group.name).to eq "the group"
          expect(@group.storage_quota_mb).to eq 22
        end
      end
    end
  end

  describe "DELETE destroy" do
    it "requires authorization" do
      @group = @course.groups.create!(name: "some group")
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      assert_unauthorized
    end

    it "deletes group" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group]).not_to be_frozen
      expect(assigns[:group]).to be_deleted
      expect(@course.groups).to include(@group)
      expect(@course.groups.active).not_to include(@group)
    end

    it "deletes group (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group]).not_to be_frozen
      expect(assigns[:group]).to be_deleted
      expect(@course.groups).to include(@group)
      expect(@course.groups.active).not_to include(@group)
    end

    it "does not delete group if :manage_groups_delete is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      @course.account.role_overrides.create!(
        permission: "manage_groups_delete",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      assert_unauthorized
    end
  end

  describe "GET 'unassigned_members'" do
    it "includes all users if the category is student organized" do
      user_session(@teacher)
      u1 = @student1
      u2 = @student2
      u3 = @student3

      group = @course.groups.create(name: "Group 1", group_category: GroupCategory.student_organized_for(@course))
      group.add_user(u1)
      group.add_user(u2)

      get "unassigned_members", params: { course_id: @course.id, category_id: group.group_category.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_nil
      expect(data["users"].pluck("user_id").sort)
        .to eq [u1, u2, u3].map(&:id).sort
    end

    it "includes only users not in a group in the category otherwise" do
      user_session(@teacher)
      u1 = @student1
      u2 = @student2
      u3 = @student3

      group_category1 = @course.group_categories.create(name: "Group Category 1")
      group1 = @course.groups.create(name: "Group 1", group_category: group_category1)
      group1.add_user(u1)

      group_category2 = @course.group_categories.create(name: "Group Category 2")
      group2 = @course.groups.create(name: "Group 1", group_category: group_category2)
      group2.add_user(u2)

      group_category3 = @course.group_categories.create(name: "Group Category 3")
      group3 = @course.groups.create(name: "Group 1", group_category: group_category3)
      group3.add_user(u2)
      group3.add_user(u3)

      get "unassigned_members", params: { course_id: @course.id, category_id: group1.group_category.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_nil
      expect(data["users"].pluck("user_id").sort)
        .to eq [u2, u3].map(&:id).sort

      get "unassigned_members", params: { course_id: @course.id, category_id: group2.group_category.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_nil
      expect(data["users"].pluck("user_id").sort)
        .to eq [u1, u3].map(&:id).sort

      get "unassigned_members", params: { course_id: @course.id, category_id: group3.group_category.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_nil
      expect(data["users"].pluck("user_id")).to eq [u1.id]
    end

    it "includes the users' sections when available" do
      user_session(@teacher)
      u1 = @student1

      group = @course.groups.create(name: "Group 1", group_category: GroupCategory.student_organized_for(@course))
      group.add_user(u1)

      get "unassigned_members", params: { course_id: @course.id, category_id: group.group_category.id }
      data = json_parse
      expect(data["users"].first["sections"].first["section_id"]).to eq @course.default_section.id
      expect(data["users"].first["sections"].first["section_code"]).to eq @course.default_section.section_code
    end
  end

  describe "GET 'context_group_members'" do
    it "includes the users' sections when available" do
      user_session(@teacher)
      u1 = @student1
      group = @course.groups.create(name: "Group 1", group_category: GroupCategory.student_organized_for(@course))
      group.add_user(u1)

      get "context_group_members", params: { group_id: group.id }
      data = json_parse
      expect(data.first["sections"].first["section_id"]).to eq @course.default_section.id
      expect(data.first["sections"].first["section_code"]).to eq @course.default_section.section_code
    end

    it "requires :read_roster permission" do
      u1 = @student1
      u2 = @student2
      group = @course.groups.create(name: "Group 1")
      group.add_user(u1)

      # u1 in the group has :read_roster permission
      user_session(u1)
      get "context_group_members", params: { group_id: group.id }
      expect(response).to be_successful

      # u2 outside the group doesn't have :read_roster permission, since the
      # group isn't self-signup and is invitation only (clear controller
      # context permission cache, though)
      controller.instance_variable_set(:@context_all_permissions, nil)
      user_session(u2)
      get "context_group_members", params: { group_id: group.id }
      expect(response).not_to be_successful
    end
  end

  describe "GET 'public_feed.atom'" do
    before :once do
      group_with_user(active_all: true)
      @dt = @group.discussion_topics.create!(title: "hi", message: "intros", user: @user)
      @wp = @group.wiki_pages.create! title: "a page"
    end

    it "requires authorization" do
      get "public_feed", params: { feed_code: @group.feed_code + "x" }, format: "atom"
      expect(assigns[:problem]).to match(/The verification code is invalid/)
    end

    it "includes absolute path for rel='self' link" do
      get "public_feed", params: { feed_code: @group.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.feed_url).to match(%r{http://})
    end

    it "includes an author for each entry" do
      get "public_feed", params: { feed_code: @group.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all? { |e| e.author.present? }).to be_truthy
    end

    it "excludes unpublished things" do
      get "public_feed", params: { feed_code: @group.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.size).to eq 2

      @wp.unpublish
      @dt.unpublish! # yes, you really have to shout to unpublish a discussion topic :(

      get "public_feed", params: { feed_code: @group.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.size).to eq 0
    end
  end

  describe "GET 'accept_invitation'" do
    before :once do
      @communities = GroupCategory.communities_for(Account.default)
      group_model(group_category: @communities)
      user_factory(active_user: true)
      @membership = @group.add_user(@user, "invited", false)
    end

    before do
      user_session(@user)
    end

    it "creates invitations" do
      get "accept_invitation", params: { group_id: @group.id, uuid: @membership.uuid }
      @group.reload
      expect(@group.has_member?(@user)).to be_truthy
      expect(@group.group_memberships.where(workflow_state: "invited").count).to eq 0
    end

    it "rejects an invalid invitation uuid" do
      get "accept_invitation", params: { group_id: @group.id, uuid: @membership.uuid + "x" }
      @group.reload
      expect(@group.has_member?(@user)).to be_falsey
      expect(@group.group_memberships.where(workflow_state: "invited").count).to eq 1
    end
  end

  describe "GET users" do
    before do
      category = @course.group_categories.create(name: "Study Groups")
      @group = @course.groups.create(name: "some group", group_category: category)
      @group.add_user(@student)

      assignment = @course.assignments.create({
                                                name: "test assignment",
                                                group_category: category
                                              })
      file = Attachment.create! context: @student, filename: "homework.pdf", uploaded_data: StringIO.new("blah blah blah")
      @sub = assignment.submit_homework(@student, attachments: [file], submission_type: "online_upload")
    end

    it "includes group submissions if param is present" do
      user_session(@teacher)
      get "users", params: { group_id: @group.id, include: ["group_submissions"] }
      json = json_parse(response.body)

      expect(response).to be_successful
      expect(json.count).to equal 1
      expect(json[0]["group_submissions"][0]).to equal @sub.id
    end

    it "does not include group submissions if param is absent" do
      user_session(@teacher)
      get "users", params: { group_id: @group.id }
      json = json_parse(response.body)

      expect(response).to be_successful
      expect(json.count).to equal 1
      expect(json[0]["group_submissions"]).to equal nil
    end

    describe "inactive students" do
      before :once do
        course_with_teacher(active_all: true)
        students = create_users_in_course(@course, 3, return_type: :record)
        @student1, @student2, @student3 = students
        category1 = @course.group_categories.create(name: "category 1")
        @group = @course.groups.create(name: "some group", group_category: category1)
        @group.add_user(@student1)
        @group.add_user(@student2)
        @group.add_user(@student3)
        @student2.enrollments.first.deactivate
        @student3.enrollments.first.update(start_at: 1.day.from_now, end_at: 2.days.from_now) # technically "inactive" but not really
      end

      it "include active status if requested" do
        user_session(@teacher)
        get "users", params: { group_id: @group.id, include: ["active_status"] }
        json = json_parse(response.body)
        expect(json.length).to eq 3
        expect(json.detect { |r| r["id"] == @student1.id }["is_inactive"]).to be_falsey
        expect(json.detect { |r| r["id"] == @student2.id }["is_inactive"]).to be_truthy
        expect(json.detect { |r| r["id"] == @student3.id }["is_inactive"]).to be_falsey
      end

      it "don't include active status if not requested" do
        user_session(@teacher)
        get "users", params: { group_id: @group.id }
        json = json_parse(response.body)
        expect(json.first["is_inactive"]).to be_nil
      end
    end
  end

  describe "POST create_file" do
    let(:course) { Course.create! }
    let(:group_category) { course.group_categories.create!(name: "just a category") }
    let(:group) { course.groups.create!(name: "just a group", group_category:) }
    let(:assignment) { course.assignments.create!(title: "hi", submission_types: "online_upload") }

    context "as a teacher" do
      before do
        user_session(teacher)
      end

      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:progress) { Progress.last }
      let(:request_params) do
        { course_id: course.id, group_id: group.id, filename: "An attachment!", url: "http://nowhere" }
      end

      it "creates a Progress object with an assignment as the context when the assignment_id parameter is included" do
        put "create_file", params: request_params.merge({ assignment_id: assignment.id })
        expect(progress.context).to eq(assignment)
      end

      it "creates a Progress object with the current user as the context when no assignment parameter is included" do
        put "create_file", params: request_params
        expect(progress.context).to eq(teacher)
      end
    end

    context "as a student" do
      before do
        @student = course.enroll_student(User.create!, enrollment_state: "active").user
        group.add_user(@student, "accepted")
        user_session(@student)
      end

      let(:request_params) do
        { group_id: group.id, assignment_id: assignment.id, filename: "An attachment!", url: "http://nowhere" }
      end

      let(:created_attachment) { group.attachments.first }

      it "uses the 'submissions' folder for assignment submissions" do
        put "create_file", params: request_params.merge(submit_assignment: true)
        expect(created_attachment.folder).to eq group.submissions_folder
      end

      it "uses the default folder for non-submissions" do
        put "create_file", params: request_params
        expect(created_attachment.folder).to eq Folder.unfiled_folder(group)
      end

      it "does not check quota if submit_assignment is true" do
        put "create_file", params: request_params.merge(submit_assignment: true)
        expect_any_instance_of(Attachment).not_to receive(:get_quota)
      end
    end
  end
end
