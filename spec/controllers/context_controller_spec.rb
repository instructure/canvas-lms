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

describe ContextController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "GET 'roster'" do
    it "requires authorization" do
      get "roster", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "works when the context is a group in a course" do
      user_session(@student)
      @group = @course.groups.create!
      @group.add_user(@student, "accepted")
      get "roster", params: { group_id: @group.id }
      expect(assigns[:primary_users].each_value.first.collect(&:id)).to eq [@student.id]
      expect(assigns[:secondary_users].each_value.first.collect(&:id)).to match_array @course.admins
                                                                                             .map(&:id)
    end

    it "only shows active group members to students" do
      active_student = user_factory
      @course.enroll_student(active_student).accept!
      inactive_student = user_factory
      @course.enroll_student(inactive_student).deactivate

      @group = @course.groups.create!
      [@student, active_student, inactive_student].each { |u| @group.add_user(u, "accepted") }

      user_session(@student)
      get "roster", params: { group_id: @group.id }
      expect(assigns[:primary_users].each_value.first.collect(&:id)).to match_array [
        @student.id,
        active_student.id
      ]
    end

    it "only shows active course instructors to students" do
      active_teacher = user_factory
      @course.enroll_teacher(active_teacher).accept!
      inactive_teacher = user_factory
      @course.enroll_teacher(inactive_teacher).deactivate

      @group = @course.groups.create!
      @group.add_user(@student, "accepted")

      user_session(@student)
      get "roster", params: { group_id: @group.id }
      teacher_ids = assigns[:secondary_users].each_value.first.map(&:id)
      expect(teacher_ids & [active_teacher.id, inactive_teacher.id]).to eq [active_teacher.id]
    end

    it "only shows instructors in the same section as section-restricted student" do
      my_course = create_course
      my_student = user_factory(name: "mystudent")
      my_teacher = user_factory(name: "myteacher")
      other_teacher = user_factory(name: "otherteacher")
      section1 = my_course.course_sections.create!(name: "Section 1")
      section2 = my_course.course_sections.create!(name: "Section 2")
      my_course.enroll_user(my_student, "StudentEnrollment", section: section1, enrollment_state: "active", limit_privileges_to_course_section: true)
      my_course.enroll_user(my_teacher, "TeacherEnrollment", section: section1, enrollment_state: "active")
      my_course.enroll_user(other_teacher, "TeacherEnrollment", section: section2, enrollment_state: "active")

      my_group = my_course.groups.create!
      my_group.add_user(my_student, "accepted")

      user_session(my_student)
      get "roster", params: { group_id: my_group.id }
      teacher_ids = assigns[:secondary_users].each_value.first.map(&:id)
      expect(teacher_ids).to eq [my_teacher.id]
      expect(teacher_ids).not_to include other_teacher.id
    end

    it "shows all group members to admins" do
      active_student = user_factory
      @course.enroll_student(active_student).accept!
      inactive_student = user_factory
      @course.enroll_student(inactive_student).deactivate

      @group = @course.groups.create!
      [@student, active_student, inactive_student].each { |u| @group.add_user(u, "accepted") }
      user_session(@teacher)
      get "roster", params: { group_id: @group.id }
      expect(assigns[:primary_users].each_value.first.collect(&:id)).to match_array [
        @student.id,
        active_student.id,
        inactive_student.id
      ]
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(
        :tab_configuration,
        [{ "id" => Course::TAB_PEOPLE, "hidden" => true }]
      )
      get "roster", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    context "granular enrollment permissions" do
      it "teacher and student permissions are excluded from active_granular_enrollment_permissions when not enabled" do
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        %w[add_student_to_course add_teacher_to_course].each do |perm|
          RoleOverride.create!(context: Account.default, permission: perm, role: teacher_role, enabled: false)
        end
        %w[add_designer_to_course add_observer_to_course add_ta_to_course].each do |perm|
          RoleOverride.create!(context: Account.default, permission: perm, role: teacher_role, enabled: true)
        end
        user_session(@teacher)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:permissions][:active_granular_enrollment_permissions]).to eq(%w[TaEnrollment DesignerEnrollment ObserverEnrollment])
      end
    end

    context "student context cards" do
      it "is always enabled for teachers" do
        %w[manage_students manage_admin_users].each do |perm|
          RoleOverride.manage_role_override(Account.default, teacher_role, perm, override: false)
        end
        user_session(@teacher)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be true
      end

      it "is always disabled for students" do
        user_session(@student)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be_falsey
      end
    end

    context "when enable_user_notes is true" do
      before :once do
        a = Account.default
        a.enable_user_notes = true
        a.save!
      end

      context "when the deprecate_faculty_journal flag is disabled" do
        before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

        it "sets manage_user_notes permission ENV var to true for teachers" do
          user_session(@teacher)
          get :roster, params: { course_id: @course.id }
          expect(assigns[:js_env][:permissions][:manage_user_notes]).to be true
        end

        it "sets manage_user_notes permission ENV var to true for account admins" do
          account_admin_user
          user_session(@admin)
          get :roster, params: { course_id: @course.id }
          expect(assigns[:js_env][:permissions][:manage_user_notes]).to be true
        end

        it "sets manage_user_notes permission ENV var to false for students" do
          user_session(@student)
          get :roster, params: { course_id: @course.id }
          expect(assigns[:js_env][:permissions][:manage_user_notes]).to be false
        end
      end

      context "when the deprecated_faculty_journal flag is enabled" do
        it "sets manage_user_notes permission ENV var to false for teachers" do
          user_session(@teacher)
          get :roster, params: { course_id: @course.id }
          expect(assigns[:js_env][:permissions][:manage_user_notes]).to be false
        end
      end
    end

    context "when enable_user_notes is false" do
      before :once do
        a = Account.default
        a.enable_user_notes = false
        a.save!
      end

      it "sets manage_user_notes permission ENV var to false for teachers" do
        user_session(@teacher)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:permissions][:manage_user_notes]).to be false
      end

      it "sets manage_user_notes permission ENV var to false for account admins" do
        account_admin_user
        user_session(@admin)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:permissions][:manage_user_notes]).to be false
      end

      it "sets manage_user_notes permission ENV var to false for students" do
        user_session(@student)
        get :roster, params: { course_id: @course.id }
        expect(assigns[:js_env][:permissions][:manage_user_notes]).to be false
      end
    end
  end

  describe "GET 'roster_user'" do
    it "requires authorization" do
      get "roster_user", params: { course_id: @course.id, id: @user.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@teacher)
      @enrollment = @course.enroll_student(user_factory(active_all: true))
      @enrollment.accept!
      @student = @enrollment.user
      get "roster_user", params: { course_id: @course.id, id: @student.id }
      expect(assigns[:membership]).not_to be_nil
      expect(assigns[:membership]).to eql(@enrollment)
      expect(assigns[:user]).not_to be_nil
      expect(assigns[:user]).to eql(@student)
      expect(assigns[:topics]).not_to be_nil
      expect(assigns[:messages]).not_to be_nil
    end

    describe "across shards" do
      specs_require_sharding

      it "allows merged users from other shards to be referenced" do
        user1 = user_model
        course1 = course_factory(active_all: true)
        course1.enroll_user(user1)

        @shard2.activate do
          @user2 = user_model
          @course2 = course_factory(active_all: true)
          @course2.enroll_user(@user2)
        end

        UserMerge.from(user1).into(@user2)

        admin = user_model
        Account.site_admin.account_users.create!(user: admin)
        user_session(admin)

        get "roster_user", params: { course_id: course1.id, id: @user2.id }
        expect(response).to be_successful
      end
    end

    describe "hide_sections_on_course_users_page setting is Off" do
      before :once do
        @student2 = student_in_course(course: @course, active_all: true).user
      end

      it "sets js_env with hide sections setting to false" do
        @other_section = @course.course_sections.create! name: "Other Section FRD"
        user_session(@student)
        get "roster", params: { course_id: @course.id, id: @student.id }
        expect(assigns["js_env"][:course][:hideSectionsOnCourseUsersPage]).to be_falsey
      end

      it "sets js_env with hide sections setting to true" do
        @course.hide_sections_on_course_users_page = true
        @course.save!
        @other_section = @course.course_sections.create! name: "Other Section FRD"
        user_session(@student)
        get "roster", params: { course_id: @course.id, id: @student.id }
        expect(assigns["js_env"][:course][:hideSectionsOnCourseUsersPage]).to be_truthy
      end
    end

    describe "section visibility" do
      before :once do
        @other_section = @course.course_sections.create! name: "Other Section FRD"
        @course.enroll_teacher(@teacher, section: @other_section, allow_multiple_enrollments: true)
               .accept!
        @other_student = user_factory
        @course.enroll_student(
          @other_student,
          section: @other_section,
          limit_privileges_to_course_section: true
        )
               .accept!
      end

      it "prevents section-limited users from seeing users in other sections" do
        user_session(@student)
        get "roster_user", params: { course_id: @course.id, id: @other_student.id }
        expect(response).to be_successful

        user_session(@other_student)
        get "roster_user", params: { course_id: @course.id, id: @student.id }
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
      end

      it "limits enrollments by visibility for course default section" do
        user_session(@student)
        get "roster_user", params: { course_id: @course.id, id: @teacher.id }
        expect(response).to be_successful
        expect(assigns[:enrollments].map(&:course_section_id)).to match_array(
          [@course.default_section.id, @other_section.id]
        )
      end

      it "limits enrollments by visibility for other section" do
        user_session(@other_student)
        get "roster_user", params: { course_id: @course.id, id: @teacher.id }
        expect(response).to be_successful
        expect(assigns[:enrollments].map(&:course_section_id)).to match_array([@other_section.id])
      end

      it "lets admins see concluded students" do
        user_session(@teacher)
        @student.enrollments.first.complete!
        get "roster_user", params: { course_id: @course.id, id: @student.id }
        expect(response).to be_successful
      end

      it "lets admins see inactive students" do
        user_session(@teacher)
        @student.enrollments.first.deactivate
        get "roster_user", params: { course_id: @course.id, id: @student.id }
        expect(response).to be_successful
      end

      it "does not let students see inactive students" do
        another_student = user_factory
        @course.enroll_student(another_student, section: @course.default_section).accept!
        user_session(another_student)

        @student.enrollments.first.deactivate

        get "roster_user", params: { course_id: @course.id, id: @student.id }
        expect(response).to_not be_successful
      end

      context "hide course sections from students feature enabled" do
        it "sets js_env with hide sections setting to true for roster_user" do
          @course.hide_sections_on_course_users_page = true
          @course.save!
          @other_section = @course.course_sections.create! name: "Other Section FRD"
          user_session(@student)
          get "roster_user", params: { course_id: @course.id, id: @teacher.id }
          expect(assigns["js_env"][:course][:hideSectionsOnCourseUsersPage]).to be_truthy
        end

        it "sets js_env with hide sections setting to false for roster_user" do
          @course.hide_sections_on_course_users_page = false
          @course.save!
          @other_section = @course.course_sections.create! name: "Other Section FRD"
          user_session(@student)
          get "roster_user", params: { course_id: @course.id, id: @teacher.id }
          expect(assigns["js_env"][:course][:hideSectionsOnCourseUsersPage]).to be_falsey
        end
      end
    end

    context "profiles enabled" do
      before do
        account_admin_user
        course_with_student(active_all: true)

        account = Account.default
        account.settings = { enable_profiles: true }
        account.save!
      end

      it "does not show the dummy course as common" do
        expect(@admin.account.enable_profiles?).to be_truthy

        Course.ensure_dummy_course
        user_session(@admin)
        get "roster_user", params: { course_id: @course.id, id: @student.id }
        expect(assigns["user_data"][:common_contexts]).to be_empty
      end

      it "displays user short name in breadcrumb" do
        @student.short_name = "display"
        @student.save
        user_session(@admin)
        get "roster_user", params: { course_id: @course.id, id: @student.id }

        expect(assigns[:_crumbs]).to include(["People", "/courses/#{@course.id}/users", {}])
        expect(assigns[:_crumbs]).to include([@student.short_name.to_s, "/courses/#{@course.id}/users/#{@student.id}", {}])
      end
    end
  end

  describe "POST 'object_snippet'" do
    before do
      @obj = "<object data='test'></object>"
      allow(HostUrl).to receive(:is_file_host?).and_return(true)
      @data = Base64.encode64(@obj)
      @hmac = Canvas::Security.hmac_sha1(@data)
    end

    it "requires a valid HMAC" do
      post "object_snippet", params: { object_data: @data, s: "DENIED" }
      assert_status(400)
    end

    it "renders given a correct HMAC" do
      post "object_snippet", params: { object_data: @data, s: @hmac }
      expect(response).to be_successful
      expect(response["X-XSS-Protection"]).to eq "0"
    end
  end

  describe "GET 'prior_users" do
    before do
      user_session(@teacher)
      create_users_in_course(@course, 21)
      @course.student_enrollments.update_all(workflow_state: "completed")
    end

    it "paginates" do
      get :prior_users, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:prior_users].size).to be 20
    end
  end

  describe "GET 'undelete_index'" do
    it "works" do
      user_session(@teacher)
      assignment_model(course: @course)
      @assignment.destroy

      get :undelete_index, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:deleted_items]).to include(@assignment)
    end

    it "shows group_categories" do
      user_session(@teacher)
      category = GroupCategory.student_organized_for(@course)
      category.destroy

      get :undelete_index, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:deleted_items]).to include(category)
    end

    it "shows groups" do
      user_session(@teacher)
      category = GroupCategory.student_organized_for(@course)
      g1 = category.groups.create!(context: @course, name: "group_a")
      g1.destroy

      get :undelete_index, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:deleted_items]).to include(g1)
    end

    it "does now show group discussions that are not restorable" do
      group_assignment_discussion(course: @course)

      @root_topic.destroy
      user_session(@teacher)
      get :undelete_index, params: { group_id: @group }

      expect(response).to be_successful
      expect(assigns[:deleted_items]).not_to include(@topic)
    end

    describe "Rubric Associations" do
      before(:once) do
        assignment = assignment_model(course: @course)
        rubric = rubric_model({
                                context: @course,
                                title: "Test Rubric",
                                data: [{
                                  description: "Some criterion",
                                  points: 10,
                                  id: "crit1",
                                  ignore_for_scoring: true,
                                  ratings: [
                                    { description: "Good", points: 10, id: "rat1", criterion_id: "crit1" }
                                  ]
                                }]
                              })
        @association = rubric.associate_with(assignment, @course, purpose: "grading")
      end

      it "shows deleted rubric associations" do
        @association.destroy
        user_session(@teacher)
        get :undelete_index, params: { course_id: @course.id }
        expect(assigns[:deleted_items]).to include @association
      end

      it "does not show active rubric associations" do
        user_session(@teacher)
        get :undelete_index, params: { course_id: @course.id }
        expect(assigns[:deleted_items]).not_to include @association
      end
    end
  end

  describe "POST 'undelete_item'" do
    it "allows undeleting groups" do
      user_session(@teacher)
      category = GroupCategory.student_organized_for(@course)
      g1 = category.groups.create!(context: @course, name: "group_a")
      g1.destroy

      post :undelete_item, params: { course_id: @course.id, asset_string: g1.asset_string }
      expect(g1.reload.workflow_state).to eq "available"
      expect(g1.deleted_at).to be_nil
    end

    it "allows undeleting group_categories" do
      user_session(@teacher)
      category = GroupCategory.student_organized_for(@course)
      g1 = category.groups.create!(context: @course, name: "group_a")
      category.destroy

      post :undelete_item, params: { course_id: @course.id, asset_string: category.asset_string }
      expect(category.reload.deleted_at).to be_nil
      expect(g1.reload.deleted_at).to be_nil
      expect(g1.workflow_state).to eq "available"
    end

    it "does not allow dangerous sends" do
      user_session(@teacher)
      expect_any_instantiation_of(@course).not_to receive(:teacher_names)
      post :undelete_item, params: { course_id: @course.id, asset_string: "teacher_name_1" }
      expect(response).to have_http_status :internal_server_error
    end

    it "does not allow restoring unrestorable discussion topics" do
      group_assignment_discussion(course: @course)
      @root_topic.destroy

      expect(@topic.reload.restorable?).to be(false)

      user_session(@teacher)
      post :undelete_item, params: { group_id: @group.id, asset_string: @topic.asset_string }
      expect(response).to have_http_status :forbidden
    end

    it 'allows undeleting a "normal" association' do
      user_session(@teacher)
      assignment_model(course: @course)
      @assignment.destroy

      post :undelete_item, params: { course_id: @course.id, asset_string: @assignment.asset_string }
      expect(@assignment.reload).not_to be_deleted
    end

    it "allows undeleting wiki pages" do
      user_session(@teacher)
      page = @course.wiki_pages.create!(title: "some page")
      page.destroy

      post :undelete_item, params: { course_id: @course.id, asset_string: page.asset_string }
      expect(page.reload).not_to be_deleted
      expect(page.current_version).not_to be_nil
    end

    it "allows undeleting attachments" do
      # attachments are special because they use file_state
      user_session(@teacher)
      attachment_model
      @attachment.destroy

      post :undelete_item, params: { course_id: @course.id, asset_string: @attachment.asset_string }
      expect(@attachment.reload).not_to be_deleted
    end

    it "allows undeleting rubric associations" do
      assignment = assignment_model(course: @course)
      rubric = rubric_model({
                              context: @course,
                              title: "Test Rubric",
                              data: [{
                                description: "Some criterion",
                                points: 10,
                                id: "crit1",
                                ignore_for_scoring: true,
                                ratings: [
                                  { description: "Good", points: 10, id: "rat1", criterion_id: "crit1" }
                                ]
                              }]
                            })
      association = rubric.associate_with(assignment, @course, purpose: "grading")
      association.destroy

      user_session(@teacher)
      post :undelete_item, params: { course_id: @course.id, asset_string: association.asset_string }
      expect(association.reload).not_to be_deleted
    end
  end

  describe "GET 'roster_user_usage'" do
    before(:once) do
      page = @course.wiki_pages.create(title: "some page")
      AssetUserAccess.create!(
        { user_id: @student, asset_code: page.asset_string, context: @course, category: "pages" }
      )
    end

    it "returns accesses" do
      user_session(@teacher)

      get :roster_user_usage, params: { course_id: @course.id, user_id: @student.id }

      expect(response).to be_successful
      expect(assigns[:accesses].length).to eq 1
    end

    it "returns json" do
      user_session(@teacher)

      get :roster_user_usage, params: { course_id: @course.id, user_id: @student.id }, format: :json

      expect(response).to be_successful
      expect(json_parse(response.body).length).to eq 1
    end
  end
end
