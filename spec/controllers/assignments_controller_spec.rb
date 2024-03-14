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

require_relative "../lti2_spec_helper"

describe AssignmentsController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    course_assignment
  end

  def course_assignment(course = nil)
    course ||= @course
    @group = course.assignment_groups.create(name: "some group")
    @assignment = course.assignments.create(
      title: "some assignment",
      assignment_group: @group,
      due_at: 1.week.from_now
    )
    @assignment
  end

  describe "GET 'index'" do
    it "throws 404 error without a valid context id" do
      get "index", params: { course_id: "notvalid" }
      assert_status(404)
    end

    it "returns unauthorized without a valid session" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 3, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "sets WEIGHT_FINAL_GRADES in js_env" do
      user_session @teacher
      get "index", params: { course_id: @course.id }

      expect(assigns[:js_env][:WEIGHT_FINAL_GRADES]).to eq(@course.apply_group_weights?)
    end

    it "js_env HAS_ASSIGNMENTS is true when the course has assignments" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:HAS_ASSIGNMENTS]).to be(true)
    end

    it "js_env HAS_ASSIGNMENTS is false when the course does not have assignments" do
      user_session(@teacher)
      @assignment.workflow_state = "deleted"
      @assignment.save!
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:HAS_ASSIGNMENTS]).to be(false)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env SIS_INTEGRATION_SETTINGS_ENABLED is true when AssignmentUtil.sis_integration_settings_enabled? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:sis_integration_settings_enabled?).and_return(true)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:SIS_INTEGRATION_SETTINGS_ENABLED]).to be(true)
    end

    it "js_env SIS_INTEGRATION_SETTINGS_ENABLED is false when AssignmentUtil.sis_integration_settings_enabled? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:sis_integration_settings_enabled?).and_return(false)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:SIS_INTEGRATION_SETTINGS_ENABLED]).to be(false)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env SIS_NAME is SIS when @context does not respond_to assignments" do
      user_session(@teacher)
      allow(@course).to receive(:respond_to?).and_return(false)
      allow(controller).to receive(:set_js_assignment_data).and_return({ js_env: {} })
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("SIS")
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return("Foo Bar")
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("Foo Bar")
    end

    it "js_env POST_TO_SIS_DEFAULT is false when sis_default_grade_export is false on the account" do
      user_session(@teacher)
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: false }
      a.save!
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:POST_TO_SIS_DEFAULT]).to be(false)
    end

    it "js_env POST_TO_SIS_DEFAULT is true when sis_default_grade_export is true on the account" do
      user_session(@teacher)
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:POST_TO_SIS_DEFAULT]).to be(true)
    end

    it "sets QUIZ_LTI_ENABLED in js_env if quizzes 2 is available" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be true
    end

    it "does not set QUIZ_LTI_ENABLED in js_env if 'newquizzes_on_quiz_page' is enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "does not set QUIZ_LTI_ENABLED in js_env if url is voided" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://void.url.inseng.net"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "does not set QUIZ_LTI_ENABLED in js_env if quizzes 2 is not available" do
      user_session @teacher
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "does not set QUIZ_LTI_ENABLED in js_env if quizzes_next is not enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "sets FLAGS/newquizzes_on_quiz_page in js_env if 'newquizzes_on_quiz_page' is enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:newquizzes_on_quiz_page]).to be_truthy
    end

    it "does not set FLAGS/newquizzes_on_quiz_page in js_env if 'newquizzes_on_quiz_page' is disabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.disable_feature! :newquizzes_on_quiz_page
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:newquizzes_on_quiz_page]).to be_falsey
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(true)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(false)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:assignment_max_name_length).and_return(15)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    context "course grading scheme defaults" do
      it "sets COURSE_DEFAULT_GRADING_SCHEME_ID to 0 in js_env if default canvas grading scheme is selected" do
        Account.site_admin.enable_feature!(:grading_scheme_updates)

        user_session @teacher
        @course.update_attribute :grading_standard_id, 0
        expect(@course.grading_standard_id).to eq 0

        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:COURSE_DEFAULT_GRADING_SCHEME_ID]).to eq 0
      end

      it "sets COURSE_DEFAULT_GRADING_SCHEME_ID to grading scheme id in js_env if a grading scheme is selected" do
        Account.site_admin.enable_feature!(:grading_scheme_updates)

        user_session @teacher
        @standard = @course.grading_standards.create!(title: "course standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })
        @course.update_attribute :grading_standard, @standard
        expect(@course.grading_standard_id).to eq @standard.id

        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:COURSE_DEFAULT_GRADING_SCHEME_ID]).to eq @standard.id
      end

      it "sets COURSE_DEFAULT_GRADING_SCHEME_ID to nil in js_env if course grading schemes are not enabled" do
        Account.site_admin.enable_feature!(:grading_scheme_updates)

        user_session @teacher
        expect(@course.grading_standard_id).to be_nil

        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:COURSE_DEFAULT_GRADING_SCHEME_ID]).to be_nil
      end

      it "sets COURSE_DEFAULT_GRADING_SCHEME_ID to account value if course has none" do
        Account.site_admin.enable_feature!(:grading_scheme_updates)
        gs = GradingStandard.new(context: @course.account, title: "My Grading Standard", data: { "A" => 0.94, "B" => 0, })
        gs.save!
        @course.account.update_attribute :grading_standard_id, gs.id

        user_session @teacher
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(@course.account.grading_standard_id).to eq gs.id
        expect(assigns[:js_env][:COURSE_DEFAULT_GRADING_SCHEME_ID]).to eq gs.id
      end
    end

    context "draft state" do
      it "creates a default group if none exist" do
        user_session(@student)

        get "index", params: { course_id: @course.id }

        expect(@course.reload.assignment_groups.count).to eq 1
      end

      it "separates manage_assignments and manage_grades permissions" do
        user_session(@teacher)
        @course.account.role_overrides.create! role: teacher_role, permission: "manage_assignments_edit", enabled: false
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_grades]).to be_truthy
        expect(assigns[:js_env][:PERMISSIONS][:manage_assignments]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage_course]).to be_truthy
      end
    end

    describe "per-assignment permissions" do
      let(:assignment_permissions) { assigns[:js_env][:PERMISSIONS][:by_assignment_id] }

      before do
        @course.enable_feature!(:moderated_grading)

        @assignment = @course.assignments.create!(
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )

        ta_in_course(active_all: true)
      end

      it "sets the 'update' attribute to true when user is the final grader" do
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(true)
      end

      it "sets the 'update' attribute to true when user has the Select Final Grade permission" do
        user_session(@ta)
        get "index", params: { course_id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(true)
      end

      it "sets the 'update' attribute to false when user does not have the Select Final Grade permission" do
        @course.account.role_overrides.create!(permission: :select_final_grade, enabled: false, role: ta_role)
        user_session(@ta)
        get "index", params: { course_id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(false)
      end
    end
  end

  describe "GET 'show_moderate'" do
    before do
      user_session(@teacher)
      course_with_user("TeacherEnrollment", { active_all: true, course: @course })
      @other_teacher = @user
      @assignment = @course.assignments.create!(
        moderated_grading: true,
        final_grader: @other_teacher,
        grader_count: 2,
        workflow_state: "published"
      )
    end

    it "renders the page when the current user is the selected moderator" do
      user_session(@other_teacher)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_status(200)
    end

    it "renders unauthorized when the current user is not the selected moderator" do
      user_session(@teacher)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_unauthorized
    end

    it "renders unauthorized when no moderator is selected and the user is not an admin" do
      @assignment.update!(final_grader: nil)
      user_session(@teacher)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_status(401)
    end

    it "renders unauthorized when no moderator is selected and the user is an admin without " \
       "'Select Final Grade for Moderation' permission" do
      @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
      @assignment.update!(final_grader: nil)
      user_session(account_admin_user)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_status(401)
    end

    it "renders the page when the current user is an admin and not the selected moderator" do
      account_admin_user(account: @course.root_account)
      user_session(@admin)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_status(200)
    end

    it "renders the page when no moderator is selected and the user is an admin with " \
       "'Select Final Grade for Moderation' permission" do
      @assignment.update!(final_grader: nil)
      user_session(account_admin_user)
      get "show_moderate", params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_status(200)
    end

    describe "js_env" do
      let_once(:grader_1) do
        course_with_user("TeacherEnrollment", { active_all: true, course: @course })
        @user
      end
      let_once(:grader_2) do
        course_with_user("TeacherEnrollment", { active_all: true, course: @course })
        @user
      end

      let(:env) { assigns[:js_env] }

      before :once do
        @assignment.grade_student(@student, grader: grader_1, provisional: true, score: 10)
        @assignment.grade_student(@student, grader: grader_2, provisional: true, score: 5)
      end

      before do
        @assignment.update(
          moderated_grading: true,
          final_grader: @other_teacher,
          grader_count: 2
        )
        user_session(@other_teacher)
      end

      it "includes ASSIGNMENT.course_id" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:ASSIGNMENT][:course_id]).to be(@course.id)
      end

      it "includes ASSIGNMENT.id" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:ASSIGNMENT][:id]).to be(@assignment.id)
      end

      it "includes ASSIGNMENT.grades_published" do
        @assignment.update!(grades_published_at: 1.day.ago)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:ASSIGNMENT][:grades_published]).to be(true)
      end

      it "includes ASSIGNMENT.muted" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:ASSIGNMENT][:muted]).to be(true)
      end

      it "includes ASSIGNMENT.title" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:ASSIGNMENT][:title]).to eql(@assignment.title)
      end

      it "optionally sets CURRENT_USER.can_view_grader_identities to true" do
        @assignment.update(grader_names_visible_to_final_grader: true)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:CURRENT_USER][:can_view_grader_identities]).to be(true)
      end

      it "optionally sets CURRENT_USER.can_view_grader_identities to false" do
        @assignment.update(grader_names_visible_to_final_grader: false)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:CURRENT_USER][:can_view_grader_identities]).to be(false)
      end

      it "optionally sets CURRENT_USER.can_view_student_identities to true" do
        @assignment.update(anonymous_grading: false)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:CURRENT_USER][:can_view_student_identities]).to be(true)
      end

      it "optionally sets CURRENT_USER.can_view_student_identities to false" do
        @assignment.update(anonymous_grading: true)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:CURRENT_USER][:can_view_student_identities]).to be(false)
      end

      describe "CURRENT_USER.grader_id" do
        it "is the id of the user when the user can see other grader identities" do
          @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
          get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
          expect(env[:CURRENT_USER][:grader_id]).to eql(@other_teacher.id)
        end

        context "when the user cannot see other grader identities" do
          before do
            @assignment.update(grader_names_visible_to_final_grader: false)
          end

          it "is the anonymous_id of the associated moderation grader when the user has graded" do
            @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
            get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
            expect(env[:CURRENT_USER][:grader_id]).to eql("other")
          end

          it "is nil when the user has not graded" do
            get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
            expect(env[:CURRENT_USER][:grader_id]).to be_nil
          end
        end
      end

      it "includes CURRENT_USER.id" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:CURRENT_USER][:id]).to eql(@other_teacher.id)
      end

      describe "FINAL_GRADER.grader_id" do
        it "is the id of the final grader when the current user can see other grader identities" do
          @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
          get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
          expect(env[:FINAL_GRADER][:grader_id]).to eql(@other_teacher.id)
        end

        context "when the current user cannot see other grader identities" do
          before do
            @assignment.update(grader_names_visible_to_final_grader: false)
          end

          it "is the anonymous_id of the final grader's moderation grader when the final grader has graded" do
            @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
            get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
            expect(env[:FINAL_GRADER][:grader_id]).to eql("other")
          end

          it "is nil when the final grader has not graded" do
            get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
            expect(env[:FINAL_GRADER][:grader_id]).to be_nil
          end
        end
      end

      it "includes FINAL_GRADER.id when the assignment has a final grader" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:FINAL_GRADER][:id]).to eql(@other_teacher.id)
      end

      it "sets FINAL_GRADER to nil when the assignment does not have a final grader" do
        user_session(account_admin_user)
        @assignment.update(final_grader: nil)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:FINAL_GRADER]).to be_nil
      end

      it "includes moderation graders in GRADERS" do
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        moderation_grader_ids = @assignment.moderation_graders.map(&:id)
        expect(env[:GRADERS].pluck(:id)).to match_array(moderation_grader_ids)
      end

      it "does not include the final grader in GRADERS" do
        @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:GRADERS].map { |grader| grader[:id].to_s }).not_to include(@other_teacher.id.to_s)
      end

      it "sets selectable to false when the grader is removed from the course" do
        user_session(account_admin_user)
        @assignment.moderation_graders.create!(anonymous_id: "other", user: grader_1)
        grader_1.enrollments.first.destroy
        get :show_moderate, params: { course_id: @course.id, assignment_id: @assignment.id }
        expect(env[:GRADERS].first["grader_selectable"]).to be(false)
      end
    end
  end

  describe "GET 'show'" do
    it "returns 404 on non-existent assignment" do
      user_session(@student)

      get "show", params: { course_id: @course.id, id: Assignment.maximum(:id) + 100 }
      assert_status(404)
    end

    context "with public course" do
      let(:course) { course_factory(active_all: true, is_public: true) }
      let(:assignment) { assignment_model(course:, submission_types: "online_url") }

      it "doesn't fail on a public course with a nil user" do
        get "show", params: { course_id: course.id, id: assignment.id }
        assert_status(200)
      end

      it "doesn't fail on a public course with a nil user EVEN IF filter_speed_grader_by_student_group is in play" do
        course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
        course.update!(filter_speed_grader_by_student_group: true)
        expect(course.reload.filter_speed_grader_by_student_group).to be_truthy
        get "show", params: { course_id: course.id, id: assignment.id }
        assert_status(200)
      end
    end

    it "returns unauthorized if not enrolled" do
      get "show", params: { course_id: @course.id, id: @assignment.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@student)
      a = @course.assignments.create(title: "some assignment")

      get "show", params: { course_id: @course.id, id: a.id }
      expect(@course.reload.assignment_groups).not_to be_empty
      expect(assigns[:unlocked]).not_to be_nil
      expect(assigns[:js_env][:media_comment_asset_string]).to eq @student.asset_string
    end

    it "renders student-specific js_env" do
      user_session(@student)
      a = @course.assignments.create(title: "some assignment")
      get "show", params: { course_id: @course.id, id: a.id }
      expect(assigns[:js_env][:SUBMISSION_ID]).to eq a.submissions.find_by(user: @student).id
    end

    it "renders teacher-specific js_env" do
      user_session(@teacher)
      a = @course.assignments.create(title: "some assignment")
      get "show", params: { course_id: @course.id, id: a.id }
      expect(assigns[:js_env][:SUBMISSION_ID]).to be_nil
    end

    context "direct share options" do
      it "shows direct share options when the user can use it" do
        user_session(@teacher)
        get "show", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:can_direct_share]).to be true
      end

      describe "with manage_course_content_add permission disabled" do
        before do
          RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
        end

        it "does not show direct share options if the course is active" do
          user_session(@teacher)
          get "show", params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:can_direct_share]).to be false
        end

        describe "when the course is concluded" do
          before do
            @course.complete!
          end

          it "shows direct share options when the user can use it" do
            user_session(@teacher)

            get "show", params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:can_direct_share]).to be true
          end

          it "does not show direct share options when the user can't use it" do
            user_session(@student)

            get "show", params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:can_direct_share]).to be false
          end
        end
      end
    end

    context "when the assignment is an external tool" do
      subject { get "show", params: { course_id: assignment.course.id, id: assignment.id } }

      let(:assignment) { assignment_model }

      before { user_session(assignment.course.teachers.first) }

      context "and a default line item was never created" do
        let(:launch_url) { "https://www.my-tool.com/login" }
        let(:content_tag) do
          ContentTag.create!(
            context: assignment,
            content_type: "ContextExternalTool",
            url: launch_url
          )
        end

        let(:key) do
          DeveloperKey.create!(
            scopes: [
              TokenScopes::LTI_AGS_LINE_ITEM_SCOPE,
              TokenScopes::LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE,
              TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE,
              TokenScopes::LTI_AGS_SCORE_SCOPE
            ]
          )
        end

        let(:external_tool) do
          external_tool_1_3_model(
            context: assignment.course,
            opts: {
              url: launch_url,
              developer_key: key
            }
          )
        end

        before do
          # For this context, the assignment and tag must
          # be created before the tool
          assignment.update!(
            external_tool_tag: content_tag,
            submission_types: "external_tool"
          )
          external_tool
        end

        it { is_expected.to be_successful }

        it "creates the default line item" do
          expect do
            subject
          end.to change {
            Lti::LineItem.where(assignment:).count
          }.from(0).to(1)
        end
      end
    end

    context "when the assignment uses the plagiarism platform" do
      include_context "lti2_spec_helper"

      let(:assignment) { @course.assignments.create(title: "some assignment") }

      before do
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true

        user_session(@student)

        AssignmentConfigurationToolLookup.create!(
          assignment:,
          tool: message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: message_handler.id
        )
      end

      it "assigns 'similarity_pledge'" do
        pledge = "I made this"
        @course.account.update(turnitin_pledge: pledge)
        get "show", params: { course_id: @course.id, id: assignment.id }
        expect(assigns[:similarity_pledge]).to eq pledge
      end
    end

    it "uses the vericite pledge if vericite is enabled" do
      user_session(@student)
      a = @course.assignments.create(title: "some assignment")
      pledge = "vericite pledge"
      allow_any_instance_of(Assignment).to receive(:vericite_enabled?).and_return(true)
      allow_any_instance_of(Course).to receive(:vericite_pledge).and_return(pledge)
      get "show", params: { course_id: @course.id, id: a.id }
      expect(assigns[:similarity_pledge]).to eq pledge
    end

    it "uses the closest pledge when vericite is enabled but no pledge is set" do
      user_session(@student)
      a = @course.assignments.create(title: "some assignment", vericite_enabled: true)
      allow(@course).to receive(:vericite_pledge).and_return("")
      get "show", params: { course_id: @course.id, id: a.id }
      expect(assigns[:similarity_pledge]).to eq "This assignment submission is my own, original work"
    end

    it "uses the turnitin pledge if turnitin is enabled" do
      user_session(@student)
      a = @course.assignments.create(title: "some assignment")
      pledge = "tii pledge"
      allow_any_instance_of(Assignment).to receive(:turnitin_enabled?).and_return(true)
      @course.account.update(turnitin_pledge: pledge)
      get "show", params: { course_id: @course.id, id: a.id }
      expect(assigns[:similarity_pledge]).to eq pledge
    end

    it "assigns submission variable if current user and submitted" do
      user_session(@student)
      @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(response).to be_successful
      expect(assigns[:current_user_submission]).not_to be_nil
      expect(assigns[:assigned_assessments]).to eq []
    end

    it "doesn't explode when fielding a JSON request" do
      user_session(@student)
      get "show", params: { course_id: @course.id, id: @assignment.id }, format: :json
      expect(response.body).to include("endpoint does not support json")
      expect(response.code.to_i).to eq(400)
    end

    it "assigns (active) peer review requests" do
      @assignment.peer_reviews = true
      @assignment.save!
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
      @student3 = student_in_course(enrollment_state: "inactive").user
      sub1 = @assignment.submit_homework(@student1, submission_type: "online_url", url: "http://www.example.com/1")
      sub2 = @assignment.submit_homework(@student2, submission_type: "online_url", url: "http://www.example.com/2")
      sub3 = @assignment.submit_homework(@student3, submission_type: "online_url", url: "http://www.example.com/3")
      sub2.assign_assessor(sub1)
      sub3.assign_assessor(sub1)
      user_session(@student1)
      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:current_user_submission]).to eq sub1
      expect(assigns[:assigned_assessments].map(&:submission)).to eq [sub2]
    end

    it "redirects to wiki page if assignment is linked to wiki page" do
      @course.conditional_release = true
      @course.save!
      user_session(@student)
      @assignment.reload.submission_types = "wiki_page"
      @assignment.save!

      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(response).to be_redirect
    end

    it "does not redirect to wiki page" do
      @course.conditional_release = false
      @course.save!
      user_session(@student)
      @assignment.submission_types = "wiki_page"
      @assignment.save!

      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(response).not_to be_redirect
    end

    it "redirects to discussion if assignment is linked to discussion" do
      user_session(@student)
      @assignment.submission_types = "discussion_topic"
      @assignment.save!

      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(response).to be_redirect
    end

    it "does not redirect to discussion for observer if assignment is linked to discussion but read_forum is false" do
      course_with_observer(active_all: true, course: @course)
      user_session(@observer)
      @assignment.submission_types = "discussion_topic"
      @assignment.save!

      RoleOverride.create!(context: @course.account,
                           permission: "read_forum",
                           role: observer_role,
                           enabled: false)

      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(response).not_to be_redirect
      expect(response).to be_successful
    end

    describe "assignments_2_student" do
      before do
        @course.enable_feature!(:assignments_2_student)
        @course.root_account.enable_feature!(:instui_nav)
        @course.save!
      end

      context "when not logged in" do
        it "redirects to the login page for a non-public course" do
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(response).to redirect_to(login_url)
        end

        it "renders the 'old' assignment page layout for a public course" do
          @course.update!(is_public: true)
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(response).to render_template("assignments/show")
        end
      end

      context "when logged in as a student" do
        before do
          user_session(@student)
        end

        it "sets crumb to the assignment title" do
          get "show", params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:_crumbs][3][1]).to include("/courses/#{@course.id}/assignments/#{@assignment.id}")
          expect(assigns[:_crumbs][3][0]).to include(@assignment.title)
        end

        it "does not render the 'old' assignment page layout" do
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(response).not_to render_template("assignments/show")
        end

        it "sets unlock date as a prerequisite for date locked assignment" do
          @assignment.unlock_at = 1.week.from_now
          @assignment.lock_at = 2.weeks.from_now
          @assignment.due_at = 10.days.from_now
          @assignment.submission_types = "text_tool"
          @assignment.save!

          get "show", params: { course_id: @course.id, id: @assignment.id }

          expect(assigns[:js_env][:PREREQS][:unlock_at]).to eq(@assignment.unlock_at)
        end

        it "sets the previous assignment as a prerequisite for assignment in module with prerequisite requirement" do
          @mod = @course.context_modules.create!(name: "Module 1")
          @mod2 = @course.context_modules.create!(name: "Module 2")

          @assignment2 = @course.assignments.create(title: "another assignment")

          @tag = @mod.add_item(type: "assignment", id: @assignment.id)
          @mod2.add_item(type: "assignment", id: @assignment2.id)
          @mod.completion_requirements = { @tag.id => { type: "must_mark_done" } }
          @mod2.prerequisites = "module_#{@mod.id}"
          @mod.save!
          @mod2.save!

          get "show", params: { course_id: @course.id, id: @assignment2.id }

          expect(assigns[:js_env][:PREREQS][:items].first[:prev][:title]).to eq(@assignment.title)
        end

        it "sets belongs to unpublished module when assignment is part of a unpublished module" do
          @mod = @course.context_modules.create!(name: "Unpublished module")
          @mod.unpublish
          @mod.add_item(type: "assignment", id: @assignment.id)

          get "show", params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env][:belongs_to_unpublished_module]).to be(true)
        end

        it "sets stickers_enabled in the ENV" do
          @course.root_account.enable_feature!(:submission_stickers)
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env][:stickers_enabled]).to be true
        end

        context "peer reviews" do
          before do
            @assignment.update!(peer_reviews: true, submission_types: "text_entry")
            @reviewee = User.create!(name: "John Connor")
            @course.enroll_user(@reviewee, "StudentEnrollment", enrollment_state: "active")
            @assignment.assign_peer_review(@student, @reviewee)

            @student_submission = @assignment.submission_for_student(@student)
            @reviewee_submission =  @assignment.submission_for_student(@reviewee)

            @reviewee_submission_id = CanvasSchema.id_from_object(
              @reviewee_submission,
              CanvasSchema.resolve_type(nil, @reviewee_submission, nil),
              nil
            )
            @student_submission_id = CanvasSchema.id_from_object(
              @student_submission,
              CanvasSchema.resolve_type(nil, @student_submission, nil),
              nil
            )

            @course.enable_feature!(:peer_reviews_for_a2)
            @course.enable_feature!(:assignments_2_student)
          end

          it "sets SUBMISSION_ID coresponding to the reviewee when reviewee_id param is present" do
            user_session(@student)

            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq @reviewee_submission_id
          end

          it "sets SUBMISSION_ID coresponding to the reviewee when anonymous_asset_id param is present" do
            user_session(@student)

            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq @reviewee_submission_id
          end

          it "sets SUBMISSION_ID to NULL when the reviewee_id is not valid" do
            user_session(@student)

            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: 9999 }
            expect(assigns[:js_env][:SUBMISSION_ID]).to be_nil
          end

          it "sets SUBMISSION_ID to NULL when the anonymous_asset_id is not valid" do
            user_session(@student)

            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: 9999 }
            expect(assigns[:js_env][:SUBMISSION_ID]).to be_nil
          end

          it "sets the student SUBMISSION_ID when peer_reviews_for_a2 FF is off and reviewee_id param is present" do
            @course.disable_feature!(:peer_reviews_for_a2)

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq @student_submission.id
          end

          it "sets the student SUBMISSION_ID when peer_reviews_for_a2 FF is off and anonymous_asset_id param is present" do
            @course.disable_feature!(:peer_reviews_for_a2)

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq @student_submission.id
          end

          it "sets the peer_review_mode_enabled to true when peer_reviews_for_a2 FF is ON and reviewee_id is present" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:peer_review_mode_enabled]).to be true
          end

          it "sets the peer_review_mode_enabled to true when peer_reviews_for_a2 FF is ON and anonymous_asset_id is present" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:peer_review_mode_enabled]).to be true
          end

          it "sets the peer_review_mode_enabled to false when peer_reviews_for_a2 FF is ON with no presence of reviewee_id and anonymous_asset_id" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env][:peer_review_mode_enabled]).to be false
          end

          it "sets peer_review_available to false when reviewee_id is present and one of the submissions have not been submitted" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:peer_review_available]).to be false
          end

          it "sets peer_review_available to false when anonymous_asset_id is present and one of the submissions have not been submitted" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:peer_review_available]).to be false
          end

          it "sets peer_review_available to true when the submissions have been graded" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
            @assignment.submit_homework(@reviewee, submission_type: "online_url", url: "http://www.google.com")

            @assignment.grade_student(@student, grade: 10, grader: @teacher)
            @assignment.grade_student(@reviewee, grade: 10, grader: @teacher)

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:peer_review_available]).to be true
          end

          it "sets peer_review_available to true when reviewee_id is present and both submissions have been submitted" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
            @assignment.submit_homework(@reviewee, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:peer_review_available]).to be true
          end

          it "sets peer_review_available to true when anonymous_asset_id is present and both submissions have been submitted" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
            @assignment.submit_homework(@reviewee, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:peer_review_available]).to be true
          end

          it "sets peer_review_available value to the reviewee name when anonymous_peer_reviews is false" do
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
            @assignment.submit_homework(@reviewee, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:peer_display_name]).to eq @reviewee.name
          end

          it "sets peer_display_name value to 'Anonymous student' when anonymous_peer_reviews is true" do
            @assignment.update_attribute(:anonymous_peer_reviews, true)
            @assignment.submit_homework(@student, submission_type: "online_url", url: "http://www.google.com")
            @assignment.submit_homework(@reviewee, submission_type: "online_url", url: "http://www.google.com")

            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:peer_display_name]).to eq "Anonymous student"
          end

          it "sets the reviewee_id value when peer_review_mode_enabled is true and reviewee_id is present" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:reviewee_id]).to eq @reviewee.id.to_s
          end

          it "sets the anonymous_asset_id value when peer_review_mode_enabled is true and anonymous_asset_id is present" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, anonymous_asset_id: @reviewee_submission.anonymous_id }
            expect(assigns[:js_env][:anonymous_asset_id]).to eq @reviewee_submission.anonymous_id
          end

          it "sets the REVIEWER_SUBMISSION_ID value when peer_review_mode_enabled is true" do
            user_session(@student)
            get "show", params: { course_id: @course.id, id: @assignment.id, reviewee_id: @reviewee.id }
            expect(assigns[:js_env][:REVIEWER_SUBMISSION_ID]).to eq @student_submission_id
          end
        end
      end

      context "when logged in as an observer" do
        let(:observer) do
          observer = User.create!
          @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)

          observer
        end

        before do
          user_session(observer)
        end

        before { request.cookies["k5_observed_user_for_#{observer.id}"] = @student.id }

        it "shows data for the first observed student, by sortable name when no cookie" do
          allow(CanvasSchema).to receive(:id_from_object) { |submission| submission.user_id.to_s }

          @student.update!(name: "Zzzzz")

          prior_student = User.create!(name: "Aaaaa")
          @course.enroll_student(prior_student, enrollment_state: "active")
          @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "pending", associated_user_id: prior_student.id)

          request.cookies.delete("k5_observed_user_for_#{observer.id}")
          get "show", params: { course_id: @course.id, id: @assignment.id }

          aggregate_failures do
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq prior_student.id.to_s
            expect(assigns[:js_env][:enrollment_state]).to eq :invited
          end
        end

        it "shows data for the selected observed student from cookie" do
          allow(CanvasSchema).to receive(:id_from_object) { |submission| submission.user_id.to_s }

          @student.update!(name: "Zzzzz")

          prior_student = User.create!(name: "Aaaaa")
          @course.enroll_student(prior_student, enrollment_state: "active")
          @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "pending", associated_user_id: prior_student.id)

          get "show", params: { course_id: @course.id, id: @assignment.id }

          aggregate_failures do
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq @student.id.to_s
            expect(assigns[:js_env][:enrollment_state]).to eq :active
          end
        end

        it "shows data for the observer when viewing their own enrollment" do
          allow(CanvasSchema).to receive(:id_from_object) { |submission| submission.user_id.to_s }

          @course.enroll_student(observer, enrollment_state: "active")

          get "show", params: { course_id: @course.id, id: @assignment.id }

          aggregate_failures do
            expect(assigns[:js_env][:SUBMISSION_ID]).to eq observer.id.to_s
            expect(assigns[:js_env][:enrollment_state]).to eq :active
            expect(flash[:notice]).to be_nil
          end
        end

        it "shows the old assignments page if this user is not observing any students" do
          observer.observer_enrollments.first.update!(associated_user: nil)

          get "show", params: { course_id: @course.id, id: @assignment.id }
          expect(flash[:notice]).to match(/^No student is being observed.*return to the dashboard\.$/)
          expect(assigns[:js_env]).not_to have_key(:SUBMISSION_ID)
        end

        it "sets js_env variables" do
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).to have_key(:OBSERVER_OPTIONS)
          expect(assigns[:js_env][:OBSERVER_OPTIONS][:OBSERVED_USERS_LIST].is_a?(Array)).to be true
          expect(assigns[:js_env][:OBSERVER_OPTIONS][:CAN_ADD_OBSERVEE]).to be false
        end
      end
    end

    it "does not show locked external tool assignments" do
      user_session(@student)

      @assignment.lock_at = 1.week.ago
      @assignment.due_at = 10.days.ago
      @assignment.unlock_at = 2.weeks.ago
      @assignment.submission_types = "external_tool"
      @assignment.save
      # This is usually a ContentExternalTool, but it only needs to
      # be true here because we aren't redirecting to it.
      allow_any_instance_of(Assignment).to receive(:external_tool_tag).and_return(true)

      get "show", params: { course_id: @course.id, id: @assignment.id }

      expect(assigns[:locked]).to be_truthy
      # make sure that the show.html.erb template is rendered, because
      # in normal cases we redirect to the assignment's external_tool_tag.
      expect(response).to render_template("assignments/show")
    end

    it "requires login for external tools in a public course" do
      @course.update_attribute(:is_public, true)
      @course.context_external_tools.create!(
        shared_secret: "test_secret",
        consumer_key: "test_key",
        name: "test tool",
        domain: "example.com"
      )
      @assignment.submission_types = "external_tool"
      @assignment.build_external_tool_tag(url: "http://example.com/test")
      @assignment.save!

      get "show", params: { course_id: @course.id, id: @assignment.id }
      assert_require_login
    end

    it "sets 'ROOT_OUTCOME_GROUP' for external tool assignments in the teacher view" do
      user_session(@teacher)
      @assignment.submission_types = "external_tool"
      @assignment.build_external_tool_tag(url: "http://example.com/test")
      @assignment.save!

      get "show", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:ROOT_OUTCOME_GROUP]).not_to be_nil
    end

    it "sets first_annotation_submission to true if it's the first submission and the assignment is annotatable" do
      user_session(@student)
      attachment = attachment_model(content_type: "application/pdf", display_name: "file.pdf", user: @teacher)
      assignment = @course.assignments.create!(
        title: "annotate",
        annotatable_attachment: attachment,
        submission_types: "student_annotation"
      )
      get :show, params: { course_id: @course.id, id: assignment.id }
      expect(assigns(:first_annotation_submission)).to be true
      expect(assigns.dig(:js_env, :FIRST_ANNOTATION_SUBMISSION)).to be true
    end

    it "sets first_annotation_submission to false if the assignment is not annotatable" do
      user_session(@student)
      assignment = @course.assignments.create!(title: "text", submission_types: "text_entry")
      get :show, params: { course_id: @course.id, id: assignment.id }
      expect(assigns(:first_annotation_submission)).to be false
      expect(assigns.dig(:js_env, :FIRST_ANNOTATION_SUBMISSION)).to be false
    end

    it "sets first_annotation_submission to false if the student has already submitted" do
      user_session(@student)
      attachment = attachment_model(content_type: "application/pdf", display_name: "file.pdf", user: @teacher)
      assignment = @course.assignments.create!(
        title: "annotate",
        annotatable_attachment: attachment,
        submission_types: "student_annotation"
      )
      assignment.submit_homework(
        @student,
        submission_type: "student_annotation",
        annotatable_attachment_id: attachment.id
      )
      get :show, params: { course_id: @course.id, id: assignment.id }
      expect(assigns(:first_annotation_submission)).to be false
      expect(assigns.dig(:js_env, :FIRST_ANNOTATION_SUBMISSION)).to be false
    end

    context "page views enabled" do
      before do
        Setting.set("enable_page_views", "db")
        @old_thread_context = Thread.current[:context]
        Thread.current[:context] = { request_id: SecureRandom.uuid }
        allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
        allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
      end

      after do
        Thread.current[:context] = @old_thread_context
      end

      it "logs an AUA as an assignment view for an external tool assignment" do
        user_session(@student)
        @course.context_external_tools.create!(
          shared_secret: "test_secret",
          consumer_key: "test_key",
          name: "test tool",
          domain: "example.com"
        )
        @assignment.submission_types = "external_tool"
        @assignment.build_external_tool_tag(url: "http://example.com/test")
        @assignment.save!

        get "show", params: { course_id: @course.id, id: @assignment.id }
        expect(response).to be_successful
        aua = AssetUserAccess.where(user_id: @student, context_type: "Course", context_id: @course).first
        expect(aua.asset_category).to eq "assignments"
        expect(aua.asset_code).to eq @assignment.asset_string
      end
    end

    describe "js_env" do
      before do
        user_session @teacher
      end

      describe "filter_speed_grader_by_student_group" do
        it "is included in the SETTINGS hash" do
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env][:SETTINGS]).to have_key :filter_speed_grader_by_student_group
        end

        describe "setting value" do
          context "when the course has the 'Filter SpeedGrader by Student Group' setting enabled" do
            before(:once) do
              @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
              @course.update!(filter_speed_grader_by_student_group: true)

              category = @course.group_categories.create!(name: "category")
              category.create_groups(2)
            end

            let(:category) { @course.group_categories.first }
            let(:group_filter_setting) { assigns[:js_env][:SETTINGS][:filter_speed_grader_by_student_group] }

            it "is set to true for non-group assignments" do
              get :show, params: { course_id: @course.id, id: @assignment.id }
              expect(group_filter_setting).to be true
            end

            it "is set to true for group assignments that grade students individually" do
              @assignment.update!(group_category: category, grade_group_students_individually: true)
              get :show, params: { course_id: @course.id, id: @assignment.id }
              expect(group_filter_setting).to be true
            end

            it "is set to false for non-group assignments that do not grade students individually" do
              @assignment.update!(group_category: category)
              get :show, params: { course_id: @course.id, id: @assignment.id }
              expect(group_filter_setting).to be false
            end

            it "is included when assignment is an external tool type" do
              @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
              get :show, params: { course_id: @course.id, id: @assignment.id }
              expect(assigns[:js_env][:SETTINGS]).to have_key(:filter_speed_grader_by_student_group)
            end
          end
        end

        context "when filter_speed_grader_by_student_group? is true" do
          before :once do
            @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
            @course.update!(filter_speed_grader_by_student_group: true)

            category = @course.group_categories.create!(name: "category")
            category.create_groups(2)
          end

          it "includes all group categories for the course if the assignment does not belong to a specific category" do
            get :show, params: { course_id: @course.id, id: @assignment.id }
            group_category_ids = assigns[:js_env][:group_categories].pluck("id")
            expect(group_category_ids).to eq @course.group_categories.map(&:id)
          end

          it "includes only the relevant group category if the assignment is a group assignment" do
            assignment_category = @course.group_categories.create!(name: "special category")
            @assignment.update!(group_category: assignment_category, grade_group_students_individually: true)

            get :show, params: { course_id: @course.id, id: @assignment.id }
            group_category_ids = assigns[:js_env][:group_categories].pluck("id")
            expect(group_category_ids).to contain_exactly(assignment_category.id)
          end

          it "includes the gradebook settings student group id if the group is valid for this assignment" do
            first_group_id = @course.groups.first.id.to_s
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                "filter_rows_by" => {
                  "student_group_id" => first_group_id
                }
              }
            }
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env][:selected_student_group_id]).to eq first_group_id
          end

          it "does not set selected_student_group_id if the selected group is not eligible for this assignment" do
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                "filter_rows_by" => {
                  "student_group_id" => @course.groups.first.id.to_s
                }
              }
            }

            assignment_category = @course.group_categories.create!(name: "special category")
            @assignment.update!(group_category: assignment_category)

            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "does not set selected_student_group_id if no group is selected" do
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "does not set selected_student_group_id if the selected group has been deleted" do
            @teacher.preferences[:gradebook_settings] = {
              @course.id => {
                "filter_rows_by" => {
                  "student_group_id" => @course.groups.second.id.to_s
                }
              }
            }
            @course.groups.second.destroy!

            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "includes group_categories when assignment is an external tool type" do
            @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).to have_key(:group_categories)
          end

          it "includes selected_student_group_id when assignment is an external tool type" do
            @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
            first_group_id = @course.groups.first.id.to_s
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                "filter_rows_by" => {
                  "student_group_id" => first_group_id
                }
              }
            }
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).to have_key(:selected_student_group_id)
          end
        end

        context "when filter_speed_grader_by_student_group? is false" do
          it "does not include the course group categories" do
            @course.group_categories.create!(name: "category")
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).not_to have_key :group_categories
          end

          it "does not include the gradebook settings student group id" do
            @teacher.preferences[:gradebook_settings] = {
              @course.id => {
                "filter_rows_by" => {
                  "student_group_id" => "23"
                }
              }
            }
            get :show, params: { course_id: @course.id, id: @assignment.id }
            expect(assigns[:js_env]).not_to have_key :selected_student_group_id
          end
        end
      end

      describe "speed_grader_url" do
        it "is included when user can view SpeedGrader and assignment is published" do
          user_session @teacher
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).to have_key :speed_grader_url
        end

        it "is not included when user cannot view SpeedGrader" do
          user_session @student
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).not_to have_key :speed_grader_url
        end

        it "is not included when assignment is not published" do
          @assignment.unpublish
          user_session @teacher
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).not_to have_key :speed_grader_url
        end

        it "includes speed_grader_url when assignment is an external tool type" do
          @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).to have_key(:speed_grader_url)
        end
      end

      describe "mastery_scales" do
        it "sets mastery_scales env when account has mastery scales enabled" do
          @course.root_account.enable_feature!(:account_level_mastery_scales)
          outcome_proficiency_model(@course)
          get :show, params: { course_id: @course.id, id: @assignment.id }
          expect(assigns[:js_env]).to have_key :ACCOUNT_LEVEL_MASTERY_SCALES
          expect(assigns[:js_env]).to have_key :MASTERY_SCALE
        end
      end

      context "when viewing as a student with the assignments_2_student flag enabled" do
        let(:course) { @course }
        let(:assignment) { @assignment }
        let(:student) { @student }

        before do
          course.enable_feature!(:assignments_2_student)
          assignment.update!(submission_types: "online_upload")
          user_session(student)

          # stub this call because for some reason the invocation in
          # render_a2_student_view takes long enough that it causes
          # requests to time out
          allow(CanvasSchema).to receive(:resolve_type).and_return(Types::SubmissionType)
        end

        describe "CONTEXT_MODULE_ITEM" do
          context "when viewing an assignment with a 'mark as done' requirement" do
            let(:module1) { course.context_modules.create!(name: "a module") }
            let(:module1_assignment_item) { module1.content_tags.find_by!(content_type: "Assignment", content_id: assignment.id) }

            before do
              module1.add_item(id: assignment.id, type: "assignment")
              module1.completion_requirements = [{ id: module1_assignment_item.id, type: "must_mark_done" }]
              module1.save!

              module1.context_module_progressions.create!(user: student)
            end

            it "sets 'id' to the module item ID" do
              get :show, params: { course_id: course.id, id: assignment.id }
              expect(assigns[:js_env][:CONTEXT_MODULE_ITEM][:id]).to eq module1_assignment_item.id
            end

            it "sets 'module_id' to the module ID" do
              get :show, params: { course_id: course.id, id: assignment.id }
              expect(assigns[:js_env][:CONTEXT_MODULE_ITEM][:module_id]).to eq module1.id
            end

            it "sets 'done' to true if the user has completed the item" do
              module1_assignment_item.context_module_action(student, :done)

              get :show, params: { course_id: course.id, id: assignment.id }
              expect(assigns[:js_env][:CONTEXT_MODULE_ITEM][:done]).to be true
            end

            it "sets 'done' to false if the user has not completed the item" do
              get :show, params: { course_id: course.id, id: assignment.id }
              expect(assigns[:js_env][:CONTEXT_MODULE_ITEM][:done]).to be false
            end

            it "uses the module item ID specified by the 'module_item_id' param if one is passed in" do
              module2 = course.context_modules.create!(name: "another module")
              module2.add_item(id: assignment.id, type: "assignment")

              module2_assignment_item = module2.content_tags.find_by!(content_type: "Assignment", content_id: assignment.id)
              module2.completion_requirements = [{ id: module2_assignment_item.id, type: "must_mark_done" }]
              module2.save!

              get :show, params: { course_id: course.id, id: assignment.id, module_item_id: module2_assignment_item.id }
              expect(assigns[:js_env][:CONTEXT_MODULE_ITEM][:id]).to eq module2_assignment_item.id
            end
          end

          it "is not included when the assignment does not have a 'mark as done' requirement" do
            get :show, params: { course_id: course.id, id: assignment.id }

            expect(assigns[:js_env]).not_to have_key :CONTEXT_MODULE_ITEM
          end
        end

        describe "SIMILARITY_PLEDGE" do
          let(:turnitin_assignment) do
            course.assignments.create!(
              submission_types: "online_upload",
              turnitin_enabled: true
            )
          end
          let(:vericite_assignment) do
            course.assignments.create!(
              lti_context_id: "blah",
              submission_types: "online_upload",
              vericite_enabled: true
            )
          end
          let(:pledge_settings) { assigns[:js_env][:SIMILARITY_PLEDGE] }

          def enable_vericite!(comments: "vericite comments")
            plugin = Canvas::Plugin.find(:vericite)
            plugin_setting = PluginSetting.find_by(name: plugin.id) || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
            plugin_setting.posted_settings = { comments: }
            plugin_setting.save!
          end

          it "is included if the assignment returns a tool EULA URL" do
            allow(controller).to receive(:tool_eula_url).and_return("http://some.url")
            get :show, params: { course_id: course.id, id: turnitin_assignment.id }
            expect(assigns[:js_env]).to have_key(:SIMILARITY_PLEDGE)
          end

          it "is included if the account includes pledge text" do
            course.account.update!(turnitin_pledge: "a pledge")

            get :show, params: { course_id: course.id, id: turnitin_assignment.id }
            expect(assigns[:js_env]).to have_key(:SIMILARITY_PLEDGE)
          end

          it "is included if vericite is enabled instead of turnitin" do
            enable_vericite!

            get :show, params: { course_id: course.id, id: vericite_assignment.id }
            expect(assigns[:js_env]).to have_key(:SIMILARITY_PLEDGE)
          end

          it "is included if tool_settings_tool returns a valid tool" do
            tool = course.context_external_tools.create!(
              name: "a",
              url: "http://www.google.com",
              consumer_key: "12345",
              shared_secret: "secret"
            )
            assignment.tool_settings_tool = tool
            assignment.save!

            get :show, params: { course_id: course.id, id: assignment.id }
            expect(assigns[:js_env]).to have_key(:SIMILARITY_PLEDGE)
          end

          it "is not included if neither turnitin nor vericite is enabled and no appropriate tool exists" do
            get :show, params: { course_id: course.id, id: assignment.id }
            expect(assigns[:js_env]).not_to have_key(:SIMILARITY_PLEDGE)
          end

          it "includes the assignment tool URL in the EULA_URL field" do
            allow(controller).to receive(:tool_eula_url).and_return("http://some.url")
            get :show, params: { course_id: course.id, id: turnitin_assignment.id }
            expect(pledge_settings[:EULA_URL]).to eq "http://some.url"
          end

          it "includes the pledge text in the PLEDGE_TEXT field" do
            course.account.update!(turnitin_pledge: "a pledge")

            get :show, params: { course_id: course.id, id: turnitin_assignment.id }
            expect(pledge_settings[:PLEDGE_TEXT]).to eq "a pledge"
          end

          describe "COMMENTS" do
            before do
              course.account.update!(turnitin_comments: "turnitin comments")
            end

            it "includes turnitin comments if turnitin is enabled" do
              get :show, params: { course_id: course.id, id: turnitin_assignment.id }

              expect(pledge_settings[:COMMENTS]).to eq "turnitin comments"
            end

            it "includes vericite comments if vericite is enabled" do
              enable_vericite!

              get :show, params: { course_id: course.id, id: vericite_assignment.id }
              expect(pledge_settings[:COMMENTS]).to eq "vericite comments"
            end
          end
        end
      end

      it "sets can_manage_groups permissions in the ENV" do
        get :show, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:PERMISSIONS]).to include can_manage_groups: true
      end

      it "does not sets can_edit_grades permissions in the ENV for students" do
        get :show, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:PERMISSIONS]).not_to include :can_edit_grades
      end
    end
  end

  describe "GET 'tool_launch'" do
    subject { get "tool_launch", params: { course_id: @course.id, assignment_id: @assignment.id } }

    context "with non-external_tool assignment" do
      before do
        @assignment.update(submission_types: "online_upload")
      end

      it "notifies user and redirects back to assignments page" do
        subject
        expect(response).to be_redirect
        expect(flash[:error]).to match(/The assignment you requested is not associated with an LTI tool./)
      end
    end

    context "with external_tool assignment" do
      let(:url) { "http://example.com/test" }
      let(:tool) { external_tool_model(context: @course, opts: { url:, assignment_selection: { enabled: true } }) }

      before do
        @assignment.update(submission_types: "external_tool")
        @assignment.build_external_tool_tag(url:, content: tool)
        @assignment.save!
      end

      context "with a2_enabled_tool feature flag enabled" do
        before do
          Account.site_admin.enable_feature!(:external_tools_for_a2)
        end

        it "renders the LTI tool launch associated with assignment" do
          user_session(@student)
          subject
          expect(response).to be_successful
          expect(assigns[:lti_launch]).to be_present
          expect(assigns[:js_env][:LTI_TOOL]).to eq("true")
        end
      end

      context "with a2_enabled_tool feature flag disabled" do
        before do
          Account.site_admin.disable_feature!(:external_tools_for_a2)
        end

        it "renders the LTI tool launch associated with assignment" do
          user_session(@student)
          subject
          expect(response).to be_successful
          expect(assigns[:lti_launch]).to be_present
          expect(assigns[:js_env][:LTI_TOOL]).to be_nil
        end
      end
    end
  end

  describe "GET 'syllabus'" do
    it "requires authorization" do
      # controller.use_rails_error_handling!
      get "syllabus", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 1, "hidden" => true }])
      get "syllabus", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      @course.update_attribute(:syllabus_body, "<p>Here is your syllabus.</p>")
      user_session(@student)
      get "syllabus", params: { course_id: @course.id }
      expect(assigns[:syllabus_body]).not_to be_nil
    end

    context "assigning @course_home_sub_navigation" do
      before :once do
        @tool = external_tool_model(context: @course, opts: { course_home_sub_navigation: { enabled: true, visibility: "admins" } })
      end

      it "shows admin-level course_home_sub_navigation external tools for teachers" do
        user_session(@teacher)

        get "syllabus", params: { course_id: @course.id }
        expect(assigns[:course_home_sub_navigation_tools].size).to eq 1
      end

      it "rejects admin-level course_home_sub_navigation external tools for students" do
        user_session(@student)

        get "syllabus", params: { course_id: @course.id }
        expect(assigns[:course_home_sub_navigation_tools].size).to eq 0
      end
    end
  end

  describe "PUT 'toggle_mute'" do
    it "requires authorization" do
      put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: "json"
      assert_unauthorized
    end

    context "while logged in" do
      before do
        user_session(@teacher)
      end

      context "with moderated grading on" do
        before do
          @assignment.update!(moderated_grading: true, grader_count: 1)
        end

        it "fails if grades are not published, and status is false" do
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: false }, format: "json"
          assert_unauthorized
        end

        it "mutes if grades are not published, and status is true" do
          @assignment.update!(muted: false)
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: "json"
          @assignment.reload
          expect(@assignment).to be_muted
        end
      end

      it "mutes if status is true" do
        @assignment.update!(muted: false)
        put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: "json"
        @assignment.reload
        expect(@assignment).to be_muted
      end

      it "unmutes if status is false" do
        @assignment.update_attribute(:muted, true)
        put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: false }, format: "json"
        @assignment.reload
        expect(@assignment).not_to be_muted
      end

      describe "anonymize_students" do
        it "is included in the response" do
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: "json"
          assignment_json = json_parse(response.body)["assignment"]
          expect(assignment_json).to have_key("anonymize_students")
        end

        it "is true if the assignment is anonymous and muted" do
          @assignment.update!(anonymous_grading: true)
          @assignment.unmute!
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: "json"
          assignment_json = json_parse(response.body)["assignment"]
          expect(assignment_json.fetch("anonymize_students")).to be true
        end

        it "is false if the assignment is anonymous and unmuted" do
          @assignment.update!(anonymous_grading: true)
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: "json"
          assignment_json = json_parse(response.body)["assignment"]
          expect(assignment_json.fetch("anonymize_students")).to be false
        end

        it "is false if the assignment is not anonymous" do
          put "toggle_mute", params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: "json"
          assignment_json = json_parse(response.body)["assignment"]
          expect(assignment_json.fetch("anonymize_students")).to be false
        end
      end
    end
  end

  describe "GET 'new'" do
    it "requires authorization" do
      # controller.use_rails_error_handling!
      get "new", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "defaults to unpublished for draft state" do
      @course.require_assignment_group

      get "new", params: { course_id: @course.id }

      expect(assigns[:assignment].workflow_state).to eq "unpublished"
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "new", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "new", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return("Foo Bar")
      get "new", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("Foo Bar")
    end

    it "sets the root folder ID in the ENV" do
      user_session(@teacher)
      root_folder = Folder.root_folders(@course).first
      get "new", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:ROOT_FOLDER_ID]).to eq root_folder.id
    end

    context "with ?quiz_lti query param" do
      it "uses quizzes 2 if available" do
        tool = @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
        user_session(@teacher)
        get "new", params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:assignment].quiz_lti?).to be true
        expect(assigns[:assignment].external_tool_tag.content).to eq tool
        expect(assigns[:assignment].external_tool_tag.url).to eq tool.url
      end

      it "falls back to normal behaviour if quizzes 2 is not set up" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id, quiz: true }
        expect(assigns[:assignment].quiz_lti?).to be false
      end
    end

    it "set active_tab to assignments" do
      get "new", params: { course_id: @course.id, quiz_lti: true }
      expect(assigns[:active_tab]).to eq("assignments")
    end

    context "when newquizzes_on_quiz_page FF is set" do
      before do
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.root_account.enable_feature! :newquizzes_on_quiz_page
        @course.root_account.enable_feature! :instui_nav
      end

      it "sets active tab to quizzes for new quizzes" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:active_tab]).to eq("quizzes")
      end

      it "sets crumb to Quizzes for new quizzes" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(["Quizzes", "/courses/#{@course.id}/quizzes", {}])
      end

      it "sets crumb to Create Quiz for new quizzes" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(["Create Quiz", nil, {}])
      end

      it "sets crumb to Create Assignment for new assignments" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id }
        expect(assigns[:_crumbs]).to include(["Create New Assignment", nil, {}])
      end

      it "sets crumb to Edit Quiz for new quizzes" do
        user_session(@teacher)
        post "edit", params: { course_id: @course.id, id: @assignment.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(["Edit Quiz", nil, {}])
      end

      it "sets crumb to Edit Assignment for new assignments" do
        user_session(@teacher)
        post "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:_crumbs]).to include(["Edit Assignment", nil, {}])
      end

      it "sets active tab to quizzes for editing quizzes" do
        user_session(@teacher)
        post "edit", params: { course_id: @course.id, id: @assignment.id, quiz_lti: true }
        expect(assigns[:active_tab]).to eq("quizzes")
      end

      it "sets crumb to Quizzes for editing quizzes" do
        user_session(@teacher)
        post "new", params: { course_id: @course.id, id: @assignment.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(["Quizzes", "/courses/#{@course.id}/quizzes", {}])
      end
    end
  end

  describe "POST 'create'" do
    it "sets the lti_context_id if provided" do
      user_session(@student)
      lti_context_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_context_id:)
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment", secure_params: jwt } }
      expect(assigns[:assignment].lti_context_id).to eq lti_context_id
    end

    it "requires authorization" do
      # controller.use_rails_error_handling!
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment" } }
      assert_unauthorized
    end

    it "creates assignment" do
      user_session(@student)
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment" } }
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "creates assignment when no groups exist yet" do
      user_session(@student)
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment", assignment_group_id: "" } }
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "sets updating_user on created assignment" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment", submission_types: "discussion_topic" } }
      a = assigns[:assignment]
      expect(a).not_to be_nil
      expect(a.discussion_topic).not_to be_nil
      expect(a.discussion_topic.user_id).to eql(@teacher.id)
    end

    it "defaults to unpublished if draft state is enabled" do
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment" } }
      expect(assigns[:assignment]).to be_unpublished
    end

    it "assigns to a group" do
      user_session(@student)
      group2 = @course.assignment_groups.create!(name: "group2")
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment", assignment_group_id: group2.to_param } }
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
      expect(assigns[:assignment].assignment_group).to eq group2
    end

    it "does not assign to a group from a different course" do
      user_session(@student)
      course2 = Account.default.courses.create!
      group2 = course2.assignment_groups.create!(name: "group2")
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment", assignment_group_id: group2.to_param } }
      expect(response).to be_not_found
    end

    it "uses the default post-to-SIS setting" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      post "create", params: { course_id: @course.id, assignment: { title: "some assignment" } }
      expect(assigns[:assignment]).to be_post_to_sis
    end

    it "sets important_dates if provided" do
      post "create", params: { course_id: @course.id, assignment: { important_dates: true } }
      expect(assigns[:assignment].important_dates).to be true
    end
  end

  describe "GET 'edit'" do
    include_context "grading periods within controller" do
      let(:course) { @course }
      let(:teacher) { @teacher }
      let(:request_params) { [:edit, params: { course_id: course, id: @assignment }] }
    end

    shared_examples "course feature flags for Anonymous Moderated Marking" do
      before do
        user_session(@teacher)
      end

      it "is false when the feature flag is not enabled" do
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][js_env_attribute]).to be false
      end

      it "is true when the feature flag is enabled" do
        @course.enable_feature!(feature_flag)
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][js_env_attribute]).to be true
      end
    end

    it "js_env CANCEL_TO points to quizzes when quiz_lti? is true" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get "new", params: { course_id: @course.id, quiz_lti: true }
      expect(assigns[:js_env][:CANCEL_TO]).to include("quizzes")
    end

    it "js_env CANCEL_TO points to assignments when quiz_lti? is not included" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get "new", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:CANCEL_TO]).to include("assignments")
    end

    it "js_env CANCEL_TO points to assignments when newquizzes_on_quiz_page feature flag is off" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get "new", params: { course_id: @course.id, quiz_lti: true }
      expect(assigns[:js_env][:CANCEL_TO]).to include("assignments")
    end

    it "sets the root folder ID in the ENV" do
      user_session(@teacher)
      root_folder = Folder.root_folders(@course).first
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:ROOT_FOLDER_ID]).to eq root_folder.id
    end

    it "sets can_manage_groups permissions in the ENV" do
      user_session(@teacher)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:PERMISSIONS]).to include can_manage_groups: true
    end

    it "sets can_edit_grades permissions in the ENV for teachers" do
      user_session(@teacher)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:PERMISSIONS]).to include can_edit_grades: true
    end

    it "requires authorization" do
      # controller.use_rails_error_handling!
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      assert_unauthorized
    end

    it "finds assignment" do
      user_session(@student)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:assignment]).to eql(@assignment)
    end

    it "sets 'ROOT_OUTCOME_GROUP' in js_env" do
      user_session @teacher
      get "edit", params: { course_id: @course.id, id: @assignment.id }

      expect(assigns[:js_env][:ROOT_OUTCOME_GROUP]).not_to be_nil
    end

    it "bootstraps the correct assignment info to js_env" do
      user_session(@teacher)
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @assignment.tool_settings_tool = tool

      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:ASSIGNMENT]["id"]).to eq @assignment.id
      expect(assigns[:js_env][:ASSIGNMENT_OVERRIDES]).to eq []
      expect(assigns[:js_env][:COURSE_ID]).to eq @course.id
      expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_ID]).to eq tool.id
      expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_TYPE]).to eq tool.class.to_s
    end

    it "bootstrap the assignment originality report visibility settings to js_env" do
      user_session(@teacher)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:REPORT_VISIBILITY_SETTING]).to eq("immediate")
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return("Foo Bar")
      get "edit", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("Foo Bar")
    end

    it "js_env AVAILABLE_MODERATORS includes the name and id for each available moderator" do
      user_session(@teacher)
      @assignment.update!(grader_count: 2, moderated_grading: true)
      get :edit, params: { course_id: @course.id, id: @assignment.id }
      expected_moderators = @course.instructors.map { |user| { name: user.name, id: user.id } }
      expect(assigns[:js_env][:AVAILABLE_MODERATORS]).to match_array expected_moderators
    end

    it "js_env MODERATED_GRADING_MAX_GRADER_COUNT is the max grader count for the assignment" do
      user_session(@teacher)
      get :edit, params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:MODERATED_GRADING_MAX_GRADER_COUNT]).to eq @assignment.moderated_grading_max_grader_count
    end

    context "when the root account does not have a default tool url set" do
      subject { get :edit, params: { course_id: course.id, id: @assignment.id } }

      let(:course) { @course }
      let(:root_account) { course.root_account }

      before do
        user_session(@teacher)
      end

      context "js_env SUBMISSION_TYPE_SELECTION_TOOLS" do
        let(:tool_settings) do
          {
            base_title: "my title",
            external_url: "https://tool.launch.url",
            selection_width: 750,
            selection_height: 480,
            icon_url: nil,
          }
        end

        let(:domain) { "justanexamplenotarealwebsite.com" }

        let(:tool) do
          factory_with_protected_attributes(@course.context_external_tools,
                                            domain:,
                                            url: "http://www.justanexamplenotarealwebsite.com/tool1",
                                            shared_secret: "test123",
                                            consumer_key: "test123",
                                            name: tool_settings[:base_title],
                                            settings: {
                                              submission_type_selection: tool_settings
                                            })
        end

        it "is correctly set" do
          tool
          Setting.set("submission_type_selection_allowed_launch_domains", domain)
          subject
          expect(assigns[:js_env][:SUBMISSION_TYPE_SELECTION_TOOLS][0]).to include(
            base_title: tool_settings[:base_title],
            title: tool_settings[:base_title],
            selection_width: tool_settings[:selection_width],
            selection_height: tool_settings[:selection_height]
          )
        end

        context "the tool includes a description propery" do
          let(:description) { "This is a description" }
          let(:tool_settings) do
            res = super()
            res[:description] = description
            res
          end

          it "includes the launch points" do
            tool
            Setting.set("submission_type_selection_allowed_launch_domains", domain)
            subject
            expect(assigns[:js_env][:SUBMISSION_TYPE_SELECTION_TOOLS][0])
              .to include(description:)
          end
        end
      end

      it 'does not set "DEFAULT_ASSIGNMENT_TOOL_URL"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_URL)).to be_nil
      end

      it 'does not set "DEFAULT_ASSIGNMENT_TOOL_NAME"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_NAME)).to be_nil
      end
    end

    context "when the root account has a default tool url and name set" do
      let(:course) { @course }
      let(:root_account) { course.root_account }
      let(:default_url) { "https://www.my-tool.com/blti" }
      let(:default_name) { "Default Name" }
      let(:button_text) { "Click Me" }
      let(:info_message) { "Some information for you." }

      before do
        root_account.settings[:default_assignment_tool_url] = default_url
        root_account.settings[:default_assignment_tool_name] = default_name
        root_account.settings[:default_assignment_tool_button_text] = button_text
        root_account.settings[:default_assignment_tool_info_message] = info_message
        root_account.save!
        user_session(@teacher)
        get :edit, params: { course_id: course.id, id: @assignment.id }
      end

      it 'sets "DEFAULT_ASSIGNMENT_TOOL_URL"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_URL)).to eq default_url
      end

      it 'sets "DEFAULT_ASSIGNMENT_TOOL_NAME"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_NAME)).to eq default_name
      end

      it 'sets "DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT)).to eq button_text
      end

      it 'sets "DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE)).to eq info_message
      end
    end

    describe "js_env ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED" do
      before do
        user_session(@teacher)
      end

      it "is true when the course has anonymous_instructor_annotations on" do
        @course.enable_feature!(:anonymous_instructor_annotations)
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be true
      end

      it "is true when the account has anonymous_instructor_annotations on" do
        @course.account.enable_feature!(:anonymous_instructor_annotations)
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be true
      end

      it "is false when the course has anonymous_instructor_annotations off" do
        @course.disable_feature!(:anonymous_instructor_annotations)
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be false
      end

      it "is false when the account has anonymous_instructor_annotations off" do
        @course.account.disable_feature!(:anonymous_instructor_annotations)
        get "edit", params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be false
      end
    end

    context "plagiarism detection platform" do
      include_context "lti2_spec_helper"

      let(:service_offered) do
        [
          {
            "endpoint" => "http://originality.docker/eula",
            "action" => ["GET"],
            "@id" => "http://originality.docker/lti/v2/services#vnd.Canvas.Eula",
            "@type" => "RestService"
          }
        ]
      end

      before do
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true
        allow(Lti::ToolProxy).to receive(:find_active_proxies_for_context).with(@course) { Lti::ToolProxy.where(id: tool_proxy.id) }
        tool_proxy.resources << resource_handler
        tool_proxy.update!(context: @course)

        AssignmentConfigurationToolLookup.create!(
          assignment: @assignment,
          tool: message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: message_handler.id
        )
      end

      it "bootstraps the correct message_handler id for LTI 2 tools to js_env" do
        user_session(@teacher)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_ID]).to eq message_handler.id
      end

      it "bootstraps the correct EULA link for the associated LTI 2 tool" do
        tool_proxy.raw_data["tool_profile"]["service_offered"] = service_offered
        tool_proxy.save!

        user_session(@student)
        get "show", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:EULA_URL]).to eq service_offered[0]["endpoint"]
      end
    end

    context "redirects" do
      before do
        user_session(@teacher)
      end

      it "to quiz" do
        assignment_quiz [], course: @course
        get "edit", params: { course_id: @course.id, id: @quiz.assignment.id }
        expect(response).to redirect_to controller.edit_course_quiz_path(@course, @quiz)
      end

      it "to discussion topic" do
        group_assignment_discussion course: @course
        get "edit", params: { course_id: @course.id, id: @root_topic.assignment.id }
        expect(response).to redirect_to controller.edit_course_discussion_topic_path(@course, @root_topic)
      end

      it "to wiki page" do
        @course.conditional_release = true
        @course.save!
        wiki_page_assignment_model course: @course
        get "edit", params: { course_id: @course.id, id: @page.assignment.id }
        expect(response).to redirect_to controller.edit_course_wiki_page_path(@course, @page)
      end

      it "includes return_to" do
        assignment_quiz [], course: @course
        get "edit", params: { course_id: @course.id, id: @quiz.assignment.id, return_to: "flibberty" }
        expect(response.redirect_url).to match(/\?return_to=flibberty/)
      end
    end

    context "conditional release" do
      before do
        allow(ConditionalRelease::Service).to receive(:env_for).and_return({ dummy: "cr-assignment" })
      end

      it "defines env when enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        user_session(@teacher)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:dummy]).to eq "cr-assignment"
      end

      it "does not define env when not enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
        user_session(@teacher)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:dummy]).to be_nil
      end
    end

    describe "js_env ANONYMOUS_GRADING_ENABLED" do
      it_behaves_like "course feature flags for Anonymous Moderated Marking" do
        let(:js_env_attribute) { :ANONYMOUS_GRADING_ENABLED }
        let(:feature_flag) { :anonymous_marking }
      end
    end

    describe "js_env MODERATED_GRADING_ENABLED" do
      it_behaves_like "course feature flags for Anonymous Moderated Marking" do
        let(:js_env_attribute) { :MODERATED_GRADING_ENABLED }
        let(:feature_flag) { :moderated_grading }
      end
    end

    describe "ANNOTATED_DOCUMENT" do
      before(:once) do
        @attachment = attachment_model(content_type: "application/pdf", display_name: "file.pdf", user: @teacher)
        @assignment.update!(annotatable_attachment: @attachment)
      end

      before do
        @assignment.update!(annotatable_attachment: @attachment)
        user_session(@teacher)
      end

      it "is not present when the assignment is not annotatable" do
        @assignment.update!(annotatable_attachment: nil)
        get :edit, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env]).not_to have_key(:ANNOTATED_DOCUMENT)
      end

      it "contains the attachment id when the assignment is annotatable" do
        get :edit, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:ANNOTATED_DOCUMENT][:id]).to eq @assignment.annotatable_attachment_id
      end

      it "contains the attachment display_name when the assignment is annotatable" do
        get :edit, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:ANNOTATED_DOCUMENT][:display_name]).to eq @attachment.display_name
      end

      it "contains the attachment context_type when the assignment is annotatable" do
        get :edit, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:ANNOTATED_DOCUMENT][:context_type]).to eq @attachment.context_type
      end

      it "contains the attachment context_id when the assignment is annotatable" do
        get :edit, params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:ANNOTATED_DOCUMENT][:context_id]).to eq @attachment.context_id
      end
    end

    describe "js_env NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED" do
      it "sets NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED in js_env as true if enabled" do
        user_session(@teacher)
        Account.site_admin.enable_feature!(:new_quizzes_assignment_build_button)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED]).to be(true)
      end

      it "sets NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED in js_env as false if disabled" do
        user_session(@teacher)
        Account.site_admin.disable_feature!(:new_quizzes_assignment_build_button)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED]).to be(false)
      end
    end

    describe "js_env UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED" do
      it "sets UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED in js_env as true if enabled" do
        user_session(@teacher)
        Account.site_admin.enable_feature!(:update_assignment_submission_type_launch_button)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED]).to be(true)
      end

      it "sets UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED in js_env as false if disabled" do
        user_session(@teacher)
        Account.site_admin.disable_feature!(:update_assignment_submission_type_launch_button)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED]).to be(false)
      end
    end

    describe "js_env HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED" do
      it "sets HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED in js_env as true if enabled" do
        user_session(@teacher)
        Account.site_admin.enable_feature!(:hide_zero_point_quizzes_option)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED]).to be(true)
      end

      it "sets HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED in js_env as false if disabled" do
        user_session(@teacher)
        Account.site_admin.disable_feature!(:hide_zero_point_quizzes_option)
        get "edit", params: { course_id: @course.id, id: @assignment.id }
        expect(assigns[:js_env][:HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED]).to be(false)
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "requires authorization" do
      delete "destroy", params: { course_id: @course.id, id: @assignment.id }
      assert_unauthorized
    end

    it "deletes assignments if authorized" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment]).not_to be_frozen
      expect(assigns[:assignment]).to be_deleted
    end
  end

  describe "POST 'publish'" do
    it "requires authorization" do
      post "publish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }
      assert_unauthorized
    end

    it "publishes unpublished assignments" do
      user_session(@teacher)
      @assignment = @course.assignments.build(title: "New quiz!", workflow_state: "unpublished")
      @assignment.save!

      expect(@assignment).not_to be_published
      post "publish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }

      expect(@assignment.reload).to be_published
    end

    context "granular_permissions" do
      before do
        @course.root_account.enable_feature!(:granular_permissions_manage_assignments)
      end

      it "requires authorization" do
        post "publish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }
        assert_unauthorized
      end

      it "publishes unpublished assignments" do
        user_session(@teacher)
        @assignment = @course.assignments.build(title: "New quiz!", workflow_state: "unpublished")
        @assignment.save!

        expect(@assignment).not_to be_published
        post "publish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }

        expect(@assignment.reload).to be_published
      end
    end
  end

  describe "POST 'unpublish'" do
    it "requires authorization" do
      post "unpublish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }
      assert_unauthorized
    end

    it "unpublishes published quizzes" do
      user_session(@teacher)
      @assignment = @course.assignments.create(title: "New quiz!", workflow_state: "published")

      expect(@assignment).to be_published
      post "unpublish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }

      expect(@assignment.reload).not_to be_published
    end

    context "granular_permissions" do
      before do
        @course.root_account.enable_feature!(:granular_permissions_manage_assignments)
      end

      it "requires authorization" do
        post "unpublish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }
        assert_unauthorized
      end

      it "unpublishes published quizzes" do
        user_session(@teacher)
        @assignment = @course.assignments.create(title: "New quiz!", workflow_state: "published")

        expect(@assignment).to be_published
        post "unpublish_quizzes", params: { course_id: @course.id, quizzes: [@assignment.id] }

        expect(@assignment.reload).not_to be_published
      end
    end
  end

  describe "GET 'peer reviews'" do
    before do
      user_session(@teacher)
      @assignment = @course.assignments.create(title: "Peer Review Assignment", workflow_state: "published")
      @assignment.update!(peer_reviews: true, submission_types: "text_entry")
      @student2 = User.create!(name: "Bob Travis")
      @student3 = User.create!(name: "Samantha Lee")
      @student4 = User.create!(name: "Jim Carey")
      @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")
      @course.enroll_user(@student3, "StudentEnrollment", enrollment_state: "active")
      @course.enroll_user(@student4, "StudentEnrollment", enrollment_state: "active")
      @assignment.assign_peer_review(@student2, @student3)
      @assignment.assign_peer_review(@student3, @student4)
    end

    it "all visible students are listed in the assign peer review dropdown" do
      get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Sa" }
      expect(assigns[:students_dropdown_list].length).to eq(4)
    end

    context "when Search By Reviewer option is selected" do
      it "students instance variable contains the assessors who match the search term" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Sa", selected_option: "reviewer" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end

      it "students instance variable contains the assessors who match the search term parameter when search term has extraneous spaces" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: " Samantha   Lee ", selected_option: "reviewer" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end

      it "students instance variable contains the assessors who match the search term parameter when search term has the users last name first" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Lee, Samantha", selected_option: "reviewer" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end

      it "students instance variable has no assessors when search term does not match any assessor names" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Hello World", selected_option: "reviewer" }
        expect(assigns[:students].length).to eq(0)
      end
    end

    context "when Search By Peer Review option is selected" do
      it "students instance variable contains assessor whose assigned assessments contains the student matching the search term" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Jim Carey", selected_option: "student" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end

      it "students instance variable contains assessor whose assigned assessments contains the student matching the search term when search term has extraneous spaces" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: " Jim  Carey  ", selected_option: "student" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end

      it "students instance variable contains assessor whose assigned assessments contains the student matching the search term when search term is last name first" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "Carey, Jim", selected_option: "student" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"))
      end
    end

    context "when All option is selected" do
      it "students instance variable contains both the assessor and asset that contain the search term" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "sa", selected_option: "all" }
        expect(assigns[:students]).to include(have_attributes(name: "Samantha Lee"), have_attributes(name: "Bob Travis"))
      end

      it "students instance variable contains the assessor when there are no peer reviews assigned to the assessor" do
        get "peer_reviews", params: { course_id: @course.id, assignment_id: @assignment.id, search_term: "ji", selected_option: "all" }
        expect(assigns[:students]).to include(have_attributes(name: "Jim Carey"))
      end
    end
  end
end
