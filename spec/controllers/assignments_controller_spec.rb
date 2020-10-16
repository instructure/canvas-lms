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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lti2_spec_helper')

describe AssignmentsController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    course_assignment
  end

  def course_assignment(course = nil)
    course ||= @course
    @group = course.assignment_groups.create(:name => "some group")
    @assignment = course.assignments.create(
      :title => "some assignment",
      :assignment_group => @group,
      :due_at => Time.zone.now + 1.week
    )
    @assignment
  end

  describe "GET 'index'" do
    it "should throw 404 error without a valid context id" do
      #controller.use_rails_error_handling!
      get 'index', params: {:course_id => 'notvalid'}
      assert_status(404)
    end

    it "should return unauthorized without a valid session" do
      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>3,'hidden'=>true}])
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should set WEIGHT_FINAL_GRADES in js_env" do
      user_session @teacher
      get 'index', params: {course_id: @course.id}

      expect(assigns[:js_env][:WEIGHT_FINAL_GRADES]).to eq(@course.apply_group_weights?)
    end

    it "js_env HAS_ASSIGNMENTS is true when the course has assignments" do
      user_session(@teacher)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:HAS_ASSIGNMENTS]).to eq(true)
    end

    it "js_env HAS_ASSIGNMENTS is false when the course does not have assignments" do
      user_session(@teacher)
      @assignment.workflow_state = 'deleted'
      @assignment.save!
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:HAS_ASSIGNMENTS]).to eq(false)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env SIS_INTEGRATION_SETTINGS_ENABLED is true when AssignmentUtil.sis_integration_settings_enabled? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:sis_integration_settings_enabled?).and_return(true)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:SIS_INTEGRATION_SETTINGS_ENABLED]).to eq(true)
    end

    it "js_env SIS_INTEGRATION_SETTINGS_ENABLED is false when AssignmentUtil.sis_integration_settings_enabled? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:sis_integration_settings_enabled?).and_return(false)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:SIS_INTEGRATION_SETTINGS_ENABLED]).to eq(false)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env SIS_NAME is SIS when @context does not respond_to assignments" do
      user_session(@teacher)
      allow(@course).to receive(:respond_to?).and_return(false)
      allow(controller).to receive(:set_js_assignment_data).and_return({:js_env => {}})
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:SIS_NAME]).to eq('SIS')
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return('Foo Bar')
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:SIS_NAME]).to eq('Foo Bar')
    end

    it "js_env POST_TO_SIS_DEFAULT is false when sis_default_grade_export is false on the account" do
      user_session(@teacher)
      a = @course.account
      a.settings[:sis_default_grade_export] = {locked: false, value: false}
      a.save!
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:POST_TO_SIS_DEFAULT]).to eq(false)
    end

    it "js_env POST_TO_SIS_DEFAULT is true when sis_default_grade_export is true on the account" do
      user_session(@teacher)
      a = @course.account
      a.settings[:sis_default_grade_export] = {locked: false, value: true}
      a.save!
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:POST_TO_SIS_DEFAULT]).to eq(true)
    end

    it "should set QUIZ_LTI_ENABLED in js_env if quizzes 2 is available" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.settings[:provision] = {'lti' => 'lti url'}
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be true
    end

    it "should not set QUIZ_LTI_ENABLED in js_env if 'newquizzes_on_quiz_page' is enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.settings[:provision] = {'lti' => 'lti url'}
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "should not set QUIZ_LTI_ENABLED in js_env if url is voided" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://void.url.inseng.net'
      )
      @course.root_account.settings[:provision] = {'lti' => 'lti url'}
      @course.root_account.save!
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "should not set QUIZ_LTI_ENABLED in js_env if quizzes 2 is not available" do
      user_session @teacher
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "should not set QUIZ_LTI_ENABLED in js_env if quizzes_next is not enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:QUIZ_LTI_ENABLED]).to be false
    end

    it "should set FLAGS/newquizzes_on_quiz_page in js_env if 'newquizzes_on_quiz_page' is enabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:FLAGS][:newquizzes_on_quiz_page]).to be_truthy
    end

    it "should not set FLAGS/newquizzes_on_quiz_page in js_env if 'newquizzes_on_quiz_page' is disabled" do
      user_session @teacher
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.disable_feature! :newquizzes_on_quiz_page
      get 'index', params: {course_id: @course.id}
      expect(assigns[:js_env][:FLAGS][:newquizzes_on_quiz_page]).to be_falsey
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(true)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(false)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:assignment_max_name_length).and_return(15)
      get 'index', params: {:course_id => @course.id}
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    context "draft state" do
      it "should create a default group if none exist" do
        user_session(@student)

        get 'index', params: {:course_id => @course.id}

        expect(@course.reload.assignment_groups.count).to eq 1
      end

      it "should separate manage_assignments and manage_grades permissions" do
        user_session(@teacher)
        @course.account.role_overrides.create! role: teacher_role, permission: 'manage_assignments', enabled: false
        get 'index', params: {course_id: @course.id}
        expect(assigns[:js_env][:PERMISSIONS][:manage_grades]).to be_truthy
        expect(assigns[:js_env][:PERMISSIONS][:manage_assignments]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage]).to be_falsey
        expect(assigns[:js_env][:PERMISSIONS][:manage_course]).to be_truthy
      end
    end

    describe "per-assignment permissions" do
      let(:assignment_permissions) { assigns[:js_env][:PERMISSIONS][:by_assignment_id] }

      before(:each) do
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
        get 'index', params: {course_id: @course.id}
        expect(assignment_permissions[@assignment.id][:update]).to eq(true)
      end

      it "sets the 'update' attribute to true when user has the Select Final Grade permission" do
        user_session(@ta)
        get 'index', params: {course_id: @course.id}
        expect(assignment_permissions[@assignment.id][:update]).to eq(true)
      end

      it "sets the 'update' attribute to false when user does not have the Select Final Grade permission" do
        @course.account.role_overrides.create!(permission: :select_final_grade, enabled: false, role: ta_role)
        user_session(@ta)
        get 'index', params: {course_id: @course.id}
        expect(assignment_permissions[@assignment.id][:update]).to eq(false)
      end
    end
  end

  describe "GET 'show_moderate'" do
    before(:each) do
      user_session(@teacher)
      course_with_user('TeacherEnrollment', {active_all: true, course: @course})
      @other_teacher = @user
      @assignment = @course.assignments.create!(
        moderated_grading: true,
        final_grader: @other_teacher,
        grader_count: 2,
        workflow_state: 'published'
      )
    end

    it "renders the page when the current user is the selected moderator" do
      user_session(@other_teacher)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_status(200)
    end

    it "renders unauthorized when the current user is not the selected moderator" do
      user_session(@teacher)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_unauthorized
    end

    it "renders unauthorized when no moderator is selected and the user is not an admin" do
      @assignment.update!(final_grader: nil)
      user_session(@teacher)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_status(401)
    end

    it "renders unauthorized when no moderator is selected and the user is an admin without " \
    "'Select Final Grade for Moderation' permission" do
      @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
      @assignment.update!(final_grader: nil)
      user_session(account_admin_user)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_status(401)
    end

    it "renders the page when the current user is an admin and not the selected moderator" do
      account_admin_user(account: @course.root_account)
      user_session(@admin)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_status(200)
    end

    it "renders the page when no moderator is selected and the user is an admin with " \
    "'Select Final Grade for Moderation' permission" do
      @assignment.update!(final_grader: nil)
      user_session(account_admin_user)
      get 'show_moderate', params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_status(200)
    end

    describe "js_env" do
      let_once(:grader_1) do
        course_with_user('TeacherEnrollment', {active_all: true, course: @course})
        @user
      end
      let_once(:grader_2) do
        course_with_user('TeacherEnrollment', {active_all: true, course: @course})
        @user
      end

      let(:env) { assigns[:js_env] }

      before :once do
        @assignment.grade_student(@student, grader: grader_1, provisional: true, score: 10)
        @assignment.grade_student(@student, grader: grader_2, provisional: true, score: 5)
      end

      before :each do
        @assignment.update(
          moderated_grading: true,
          final_grader: @other_teacher,
          grader_count: 2
        )
        user_session(@other_teacher)
      end

      it "includes ASSIGNMENT.course_id" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:ASSIGNMENT][:course_id]).to be(@course.id)
      end

      it "includes ASSIGNMENT.id" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:ASSIGNMENT][:id]).to be(@assignment.id)
      end

      it "includes ASSIGNMENT.grades_published" do
        @assignment.update!(grades_published_at: 1.day.ago)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:ASSIGNMENT][:grades_published]).to be(true)
      end

      it "includes ASSIGNMENT.muted" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:ASSIGNMENT][:muted]).to be(true)
      end

      it "includes ASSIGNMENT.title" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:ASSIGNMENT][:title]).to eql(@assignment.title)
      end

      it "optionally sets CURRENT_USER.can_view_grader_identities to true" do
        @assignment.update(grader_names_visible_to_final_grader: true)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:CURRENT_USER][:can_view_grader_identities]).to be(true)
      end

      it "optionally sets CURRENT_USER.can_view_grader_identities to false" do
        @assignment.update(grader_names_visible_to_final_grader: false)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:CURRENT_USER][:can_view_grader_identities]).to be(false)
      end

      it "optionally sets CURRENT_USER.can_view_student_identities to true" do
        @assignment.update(anonymous_grading: false)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:CURRENT_USER][:can_view_student_identities]).to be(true)
      end

      it "optionally sets CURRENT_USER.can_view_student_identities to false" do
        @assignment.update(anonymous_grading: true)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:CURRENT_USER][:can_view_student_identities]).to be(false)
      end

      describe "CURRENT_USER.grader_id" do
        it "is the id of the user when the user can see other grader identities" do
          @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
          get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
          expect(env[:CURRENT_USER][:grader_id]).to eql(@other_teacher.id)
        end

        context "when the user cannot see other grader identities" do
          before :each do
            @assignment.update(grader_names_visible_to_final_grader: false)
          end

          it "is the anonymous_id of the associated moderation grader when the user has graded" do
            @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
            get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
            expect(env[:CURRENT_USER][:grader_id]).to eql("other")
          end

          it "is nil when the user has not graded" do
            get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
            expect(env[:CURRENT_USER][:grader_id]).to be_nil
          end
        end
      end

      it "includes CURRENT_USER.id" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:CURRENT_USER][:id]).to eql(@other_teacher.id)
      end

      describe "FINAL_GRADER.grader_id" do
        it "is the id of the final grader when the current user can see other grader identities" do
          @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
          get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
          expect(env[:FINAL_GRADER][:grader_id]).to eql(@other_teacher.id)
        end

        context "when the current user cannot see other grader identities" do
          before :each do
            @assignment.update(grader_names_visible_to_final_grader: false)
          end

          it "is the anonymous_id of the final grader's moderation grader when the final grader has graded" do
            @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
            get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
            expect(env[:FINAL_GRADER][:grader_id]).to eql("other")
          end

          it "is nil when the final grader has not graded" do
            get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
            expect(env[:FINAL_GRADER][:grader_id]).to be_nil
          end
        end
      end

      it "includes FINAL_GRADER.id when the assignment has a final grader" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:FINAL_GRADER][:id]).to eql(@other_teacher.id)
      end

      it "sets FINAL_GRADER to nil when the assignment does not have a final grader" do
        user_session(account_admin_user)
        @assignment.update(final_grader: nil)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:FINAL_GRADER]).to be(nil)
      end

      it "includes moderation graders in GRADERS" do
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        moderation_grader_ids = @assignment.moderation_graders.map(&:id)
        expect(env[:GRADERS].map {|grader| grader[:id]}).to match_array(moderation_grader_ids)
      end

      it "does not include the final grader in GRADERS" do
        @assignment.moderation_graders.create!(anonymous_id: "other", user: @other_teacher)
        get :show_moderate, params: {course_id: @course.id, assignment_id: @assignment.id}
        expect(env[:GRADERS].map {|grader| grader[:id].to_s}).not_to include(@other_teacher.id.to_s)
      end
    end
  end

  describe "GET 'show'" do
    it "should return 404 on non-existant assignment" do
      #controller.use_rails_error_handling!
      user_session(@student)

      get 'show', params: {:course_id => @course.id, :id => Assignment.maximum(:id) + 100}
      assert_status(404)
    end

    it "doesn't fail on a public course with a nil user" do
      course = course_factory(:active_all => true, :is_public => true)
      assignment = assignment_model(:course => course, :submission_types => "online_url")
      get 'show', params: {:course_id => course.id, :id => assignment.id}
      assert_status(200)
    end

    it "should return unauthorized if not enrolled" do
      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")

      get 'show', params: {:course_id => @course.id, :id => a.id}
      expect(@course.reload.assignment_groups).not_to be_empty
      expect(assigns[:unlocked]).not_to be_nil
    end

    it "does not show direct share options when disabled" do
      user_session(@teacher)
      get 'show', params: {course_id: @course.id, id: @assignment.id}
      expect(assigns[:can_direct_share]).to eq false
    end

    it "shows direct share options when enabled" do
      Account.default.enable_feature!(:direct_share)
      user_session(@teacher)
      get 'show', params: {course_id: @course.id, id: @assignment.id}
      expect(assigns[:can_direct_share]).to eq true
    end

    context 'when the assignment is an external tool' do
      subject { get 'show', params: {course_id: assignment.course.id, id: assignment.id} }

      let(:assignment) { assignment_model }

      before { user_session(assignment.course.teachers.first) }

      context 'and a default line item was never created' do
        let(:launch_url) { 'https://www.my-tool.com/login' }
        let(:content_tag) do
          ContentTag.create!(
            context: assignment,
            content_type: 'ContextExternalTool',
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
          tool = external_tool_model(
            context: assignment.course,
            opts: {
              url: launch_url,
              developer_key: key
            }
          )
          tool.settings[:use_1_3] = true
          tool.save!
          tool
        end

        before do
          # For this context, the assignment and tag must
          # be created before the tool
          assignment.update!(
            external_tool_tag: content_tag,
            submission_types: 'external_tool'
          )
          external_tool
        end

        it { is_expected.to be_success }

        it 'creates the default line item' do
          expect {
            subject
          }.to change {
            Lti::LineItem.where(assignment: assignment).count
          }.from(0).to(1)
        end
      end
    end

    context 'when the assignment uses the plagiarism platform' do
      include_context 'lti2_spec_helper'

      let(:assignment) { @course.assignments.create(:title => "some assignment") }

      before do
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true

        user_session(@student)

        AssignmentConfigurationToolLookup.create!(
          assignment: assignment,
          tool: message_handler,
          tool_type: 'Lti::MessageHandler',
          tool_id: message_handler.id
        )
      end

      it "should assign 'similarity_pledge'" do
        pledge = 'I made this'
        @course.account.update(turnitin_pledge: pledge)
        get 'show', params: {:course_id => @course.id, :id => assignment.id}
        expect(assigns[:similarity_pledge]).to eq pledge
      end
    end

    it 'uses the vericite pledge if vericite is enabled' do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")
      pledge = 'vericite pledge'
      allow_any_instance_of(Assignment).to receive(:vericite_enabled?).and_return(true)
      allow_any_instance_of(Course).to receive(:vericite_pledge).and_return(pledge)
      get 'show', params: {:course_id => @course.id, :id => a.id}
      expect(assigns[:similarity_pledge]).to eq pledge
    end

    it 'uses the closest pledge when vericite is enabled but no pledge is set' do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment", vericite_enabled: true)
      allow(@course).to receive(:vericite_pledge).and_return("")
      get 'show', params: {:course_id => @course.id, :id => a.id}
      expect(assigns[:similarity_pledge]).to eq "This assignment submission is my own, original work"
    end

    it 'uses the turnitin pledge if turnitin is enabled' do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")
      pledge = 'tii pledge'
      allow_any_instance_of(Assignment).to receive(:turnitin_enabled?).and_return(true)
      @course.account.update(turnitin_pledge: pledge)
      get 'show', params: {:course_id => @course.id, :id => a.id}
      expect(assigns[:similarity_pledge]).to eq pledge
    end

    it "should assign submission variable if current user and submitted" do
      user_session(@student)
      @assignment.submit_homework(@student, :submission_type => 'online_url', :url => 'http://www.google.com')
      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      expect(response).to be_successful
      expect(assigns[:current_user_submission]).not_to be_nil
      expect(assigns[:assigned_assessments]).to eq []
    end

    it "should assign (active) peer review requests" do
      @assignment.peer_reviews = true
      @assignment.save!
      @student1 = @student
      @student2 = student_in_course(:active_all => true).user
      @student3 = student_in_course(:enrollment_state => 'inactive').user
      sub1 = @assignment.submit_homework(@student1, :submission_type => 'online_url', :url => 'http://www.example.com/1')
      sub2 = @assignment.submit_homework(@student2, :submission_type => 'online_url', :url => 'http://www.example.com/2')
      sub3 = @assignment.submit_homework(@student3, :submission_type => 'online_url', :url => 'http://www.example.com/3')
      sub2.assign_assessor(sub1)
      sub3.assign_assessor(sub1)
      user_session(@student1)
      get 'show', :params => { :course_id => @course.id, :id => @assignment.id }
      expect(assigns[:current_user_submission]).to eq sub1
      expect(assigns[:assigned_assessments].map(&:submission)).to eq [sub2]
    end

    it "should redirect to wiki page if assignment is linked to wiki page" do
      @course.enable_feature!(:conditional_release)
      user_session(@student)
      @assignment.reload.submission_types = 'wiki_page'
      @assignment.save!

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      expect(response).to be_redirect
    end

    it "should not redirect to wiki page" do
      @course.disable_feature!(:conditional_release)
      user_session(@student)
      @assignment.submission_types = 'wiki_page'
      @assignment.save!

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      expect(response).not_to be_redirect
    end

    it "should redirect to discussion if assignment is linked to discussion" do
      user_session(@student)
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      expect(response).to be_redirect
    end

    it "should not redirect to discussion for observer if assignment is linked to discussion but read_forum is false" do
      course_with_observer(:active_all => true, :course => @course)
      user_session(@observer)
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :role => observer_role, :enabled => false)

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      expect(response).not_to be_redirect
      expect(response).to be_successful
    end

    it "should not show locked external tool assignments" do
      user_session(@student)

      @assignment.lock_at = 1.week.ago
      @assignment.due_at = 10.days.ago
      @assignment.unlock_at = 2.weeks.ago
      @assignment.submission_types = 'external_tool'
      @assignment.save
      # This is usually a ContentExternalTool, but it only needs to
      # be true here because we aren't redirecting to it.
      allow_any_instance_of(Assignment).to receive(:external_tool_tag).and_return(true)

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}

      expect(assigns[:locked]).to be_truthy
      # make sure that the show.html.erb template is rendered, because
      # in normal cases we redirect to the assignment's external_tool_tag.
      expect(response).to render_template('assignments/show')
    end

    it "should require login for external tools in a public course" do
      @course.update_attribute(:is_public, true)
      @course.context_external_tools.create!(
        :shared_secret => 'test_secret',
        :consumer_key => 'test_key',
        :name => 'test tool',
        :domain => 'example.com'
      )
      @assignment.submission_types = 'external_tool'
      @assignment.build_external_tool_tag(:url => "http://example.com/test")
      @assignment.save!

      get 'show', params: {:course_id => @course.id, :id => @assignment.id}
      assert_require_login
    end

    it 'should set user_has_google_drive' do
      user_session(@student)
      a = @course.assignments.create(:title => "some assignment")
      plugin = Canvas::Plugin.find(:google_drive)
      plugin_setting = PluginSetting.find_by_name(plugin.id) || PluginSetting.new(:name => plugin.id, :settings => plugin.default_settings)
      plugin_setting.posted_settings = {}
      plugin_setting.save!
      google_drive_mock = double('google_drive')
      allow(google_drive_mock).to receive(:authorized?).and_return(true)
      allow(controller).to receive(:google_drive_connection).and_return(google_drive_mock)
      get 'show', params: {:course_id => @course.id, :id => a.id}

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to be true
    end

    context "page views enabled" do
      before do
        Setting.set('enable_page_views', 'db')
        @old_thread_context = Thread.current[:context]
        Thread.current[:context] = { request_id: SecureRandom.uuid }
        allow(BasicLTI::Sourcedid).to receive(:encryption_secret) {'encryption-secret-5T14NjaTbcYjc4'}
        allow(BasicLTI::Sourcedid).to receive(:signing_secret) {'signing-secret-vp04BNqApwdwUYPUI'}
      end

      after do
        Thread.current[:context] = @old_thread_context
      end

      it "should log an AUA as an assignment view for an external tool assignment" do
        user_session(@student)
        @course.context_external_tools.create!(
          :shared_secret => 'test_secret',
          :consumer_key => 'test_key',
          :name => 'test tool',
          :domain => 'example.com'
        )
        @assignment.submission_types = 'external_tool'
        @assignment.build_external_tool_tag(:url => "http://example.com/test")
        @assignment.save!

        get 'show', params: {:course_id => @course.id, :id => @assignment.id}
        expect(response).to be_successful
        aua = AssetUserAccess.where(user_id: @student, context_type: 'Course', context_id: @course).first
        expect(aua.asset_category).to eq 'assignments'
        expect(aua.asset_code).to eq @assignment.asset_string
      end
    end

    describe "js_env" do
      before :each do
        user_session @teacher
      end

      describe "filter_speed_grader_by_student_group" do
        it "is included in the SETTINGS hash" do
          get :show, params: {course_id: @course.id, id: @assignment.id}
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
              get :show, params: {course_id: @course.id, id: @assignment.id}
              expect(group_filter_setting).to be true
            end

            it "is set to true for group assignments that grade students individually" do
              @assignment.update!(group_category: category, grade_group_students_individually: true)
              get :show, params: {course_id: @course.id, id: @assignment.id}
              expect(group_filter_setting).to be true
            end

            it "is set to false for non-group assignments that do not grade students individually" do
              @assignment.update!(group_category: category)
              get :show, params: {course_id: @course.id, id: @assignment.id}
              expect(group_filter_setting).to be false
            end

            it "is included when assignment is an external tool type" do
              @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
              get :show, params: {course_id: @course.id, id: @assignment.id}
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
            get :show, params: {course_id: @course.id, id: @assignment.id}
            group_category_ids = assigns[:js_env][:group_categories].map { |category| category["id"] }
            expect(group_category_ids).to eq @course.group_categories.map(&:id)
          end

          it "includes only the relevant group category if the assignment is a group assignment" do
            assignment_category = @course.group_categories.create!(name: "special category")
            @assignment.update!(group_category: assignment_category, grade_group_students_individually: true)

            get :show, params: {course_id: @course.id, id: @assignment.id}
            group_category_ids = assigns[:js_env][:group_categories].map { |category| category["id"] }
            expect(group_category_ids).to contain_exactly(assignment_category.id)
          end

          it "includes the gradebook settings student group id if the group is valid for this assignment" do
            first_group_id = @course.groups.first.id.to_s
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                'filter_rows_by' => {
                  'student_group_id' => first_group_id
                }
              }
            }
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env][:selected_student_group_id]).to eq first_group_id
          end

          it "does not set selected_student_group_id if the selected group is not eligible for this assignment" do
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                'filter_rows_by' => {
                  'student_group_id' => @course.groups.first.id.to_s
                }
              }
            }

            assignment_category = @course.group_categories.create!(name: "special category")
            @assignment.update!(group_category: assignment_category)

            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "does not set selected_student_group_id if no group is selected" do
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "does not set selected_student_group_id if the selected group has been deleted" do
            @teacher.preferences[:gradebook_settings] = {
              @course.id => {
                'filter_rows_by' => {
                  'student_group_id' => @course.groups.second.id.to_s
                }
              }
            }
            @course.groups.second.destroy!

            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).not_to include(:selected_student_group_id)
          end

          it "includes group_categories when assignment is an external tool type" do
            @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).to have_key(:group_categories)
          end

          it "includes selected_student_group_id when assignment is an external tool type" do
            @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
            first_group_id = @course.groups.first.id.to_s
            @teacher.preferences[:gradebook_settings] = {
              @course.global_id => {
                'filter_rows_by' => {
                  'student_group_id' => first_group_id
                }
              }
            }
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).to have_key(:selected_student_group_id)
          end
        end

        context "when filter_speed_grader_by_student_group? is false" do
          it "does not include the course group categories" do
            @course.group_categories.create!(name: "category")
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).not_to have_key :group_categories
          end

          it "does not include the gradebook settings student group id" do
            @teacher.preferences[:gradebook_settings] = {
              @course.id => {
                'filter_rows_by' => {
                  'student_group_id' => '23'
                }
              }
            }
            get :show, params: {course_id: @course.id, id: @assignment.id}
            expect(assigns[:js_env]).not_to have_key :selected_student_group_id
          end
        end
      end

      describe "speed_grader_url" do
        it "is included when user can view SpeedGrader and assignment is published" do
          user_session @teacher
          get :show, params: {course_id: @course.id, id: @assignment.id}
          expect(assigns[:js_env]).to have_key :speed_grader_url
        end

        it "is not included when user cannot view SpeedGrader" do
          user_session @student
          get :show, params: {course_id: @course.id, id: @assignment.id}
          expect(assigns[:js_env]).not_to have_key :speed_grader_url
        end

        it "is not included when assignment is not published" do
          @assignment.unpublish
          user_session @teacher
          get :show, params: {course_id: @course.id, id: @assignment.id}
          expect(assigns[:js_env]).not_to have_key :speed_grader_url
        end

        it "includes speed_grader_url when assignment is an external tool type" do
          @assignment.update!(submission_types: "external_tool", external_tool_tag: ContentTag.new)
          get :show, params: {course_id: @course.id, id: @assignment.id}
          expect(assigns[:js_env]).to have_key(:speed_grader_url)
        end
      end
    end
  end

  describe "GET 'syllabus'" do
    it "should require authorization" do
      #controller.use_rails_error_handling!
      get 'syllabus', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>1,'hidden'=>true}])
      get 'syllabus', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      @course.update_attribute(:syllabus_body, "<p>Here is your syllabus.</p>")
      user_session(@student)
      get 'syllabus', params: {:course_id => @course.id}
      expect(assigns[:syllabus_body]).not_to be_nil
    end
  end

  describe "PUT 'toggle_mute'" do
    it "should require authorization" do
      put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: 'json'
      assert_unauthorized
    end

    context "while logged in" do
      before :each do
        user_session(@teacher)
      end

      context "with moderated grading on" do
        before :each do
          @assignment.update!(moderated_grading: true, grader_count: 1)
        end

        it "should fail if grades are not published, and status is false" do
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: false }, format: 'json'
          assert_unauthorized
        end

        it "should mute if grades are not published, and status is true" do
          @assignment.update!(muted: false)
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: 'json'
          @assignment.reload
          expect(@assignment).to be_muted
        end
      end

      it "should mute if status is true" do
        @assignment.update!(muted: false)
        put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: true }, format: 'json'
        @assignment.reload
        expect(@assignment).to be_muted
      end

      it "should unmute if status is false" do
        @assignment.update_attribute(:muted, true)
        put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: false }, format: 'json'
        @assignment.reload
        expect(@assignment).not_to be_muted
      end

      describe 'anonymize_students' do
        it "is included in the response" do
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: 'json'
          assignment_json = json_parse(response.body)['assignment']
          expect(assignment_json).to have_key('anonymize_students')
        end

        it "is true if the assignment is anonymous and muted" do
          @assignment.update!(anonymous_grading: true)
          @assignment.unmute!
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: 'json'
          assignment_json = json_parse(response.body)['assignment']
          expect(assignment_json.fetch('anonymize_students')).to be true
        end

        it "is false if the assignment is anonymous and unmuted" do
          @assignment.update!(anonymous_grading: true)
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: 'json'
          assignment_json = json_parse(response.body)['assignment']
          expect(assignment_json.fetch('anonymize_students')).to be false
        end

        it "is false if the assignment is not anonymous" do
          put 'toggle_mute', params: { course_id: @course.id, assignment_id: @assignment.id, status: !@assignment.muted }, format: 'json'
          assignment_json = json_parse(response.body)['assignment']
          expect(assignment_json.fetch('anonymize_students')).to be false
        end
      end
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      #controller.use_rails_error_handling!
      get 'new', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should default to unpublished for draft state" do
      @course.require_assignment_group

      get 'new', params: {:course_id => @course.id}

      expect(assigns[:assignment].workflow_state).to eq 'unpublished'
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get 'new', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get 'new', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return('Foo Bar')
      get 'new', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:SIS_NAME]).to eq('Foo Bar')
    end

    context "with ?quiz_lti query param" do
      it "uses quizzes 2 if available" do
        tool = @course.context_external_tools.create!(
          :name => 'Quizzes.Next',
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :tool_id => 'Quizzes 2',
          :url => 'http://example.com/launch'
        )
        user_session(@teacher)
        get 'new', params: {:course_id => @course.id, :quiz_lti => true}
        expect(assigns[:assignment].quiz_lti?).to be true
        expect(assigns[:assignment].external_tool_tag.content).to eq tool
        expect(assigns[:assignment].external_tool_tag.url).to eq tool.url
      end

      it "falls back to normal behaviour if quizzes 2 is not set up" do
        user_session(@teacher)
        get 'new', params: {:course_id => @course.id, :quiz => true}
        expect(assigns[:assignment].quiz_lti?).to be false
      end
    end

    it 'set active_tab to assignments' do
      get 'new', params: { :course_id => @course.id, :quiz_lti => true }
      expect(assigns[:active_tab]).to eq('assignments')
    end

    context "when newquizzes_on_quiz_page FF is set" do
      before do
        @course.context_external_tools.create!(
          :name => 'Quizzes.Next',
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :tool_id => 'Quizzes 2',
          :url => 'http://example.com/launch'
        )
        @course.root_account.settings[:provision] = {'lti' => 'lti url'}
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.root_account.enable_feature! :newquizzes_on_quiz_page
      end

      it 'sets active tab to quizzes for new quizzes' do
        user_session(@teacher)
        get 'new', params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:active_tab]).to eq('quizzes')
      end

      it 'sets crumb to Quizzes for new quizzes' do
        user_session(@teacher)
        get 'new', params: { course_id: @course.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(['Quizzes', "/courses/#{@course.id}/quizzes", {}])
      end

      it 'sets active tab to quizzes for editing quizzes' do
        user_session(@teacher)
        post 'edit', params: { course_id: @course.id, id: @assignment.id, quiz_lti: true }
        expect(assigns[:active_tab]).to eq('quizzes')
      end

      it 'sets crumb to Quizzes for editing quizzes' do
        user_session(@teacher)
        post 'new', params: { course_id: @course.id, id: @assignment.id, quiz_lti: true }
        expect(assigns[:_crumbs]).to include(['Quizzes', "/courses/#{@course.id}/quizzes", {}])
      end
    end
  end

  describe "POST 'create'" do
    it "sets the lti_context_id if provided" do
      user_session(@student)
      lti_context_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_context_id: lti_context_id)
      post 'create', params: {course_id: @course.id, assignment: {title: "some assignment",secure_params: jwt}}
      expect(assigns[:assignment].lti_context_id).to eq lti_context_id
    end

    it "should require authorization" do
      #controller.use_rails_error_handling!
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment"}}
      assert_unauthorized
    end

    it "should create assignment" do
      user_session(@student)
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment"}}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "should create assignment when no groups exist yet" do
      user_session(@student)
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => ''}}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
    end

    it "should set updating_user on created assignment" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment", :submission_types => "discussion_topic"}}
      a = assigns[:assignment]
      expect(a).not_to be_nil
      expect(a.discussion_topic).not_to be_nil
      expect(a.discussion_topic.user_id).to eql(@teacher.id)
    end

    it "should default to unpublished if draft state is enabled" do
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment"}}
      expect(assigns[:assignment]).to be_unpublished
    end

    it "should assign to a group" do
      user_session(@student)
      group2 = @course.assignment_groups.create!(name: 'group2')
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => group2.to_param}}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment].title).to eql("some assignment")
      expect(assigns[:assignment].context_id).to eql(@course.id)
      expect(assigns[:assignment].assignment_group).to eq group2
    end

    it "should not assign to a group from a different course" do
      user_session(@student)
      course2 = Account.default.courses.create!
      group2 = course2.assignment_groups.create!(name: 'group2')
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => group2.to_param}}
      expect(response).to be_not_found
    end

    it 'should use the default post-to-SIS setting' do
      a = @course.account
      a.settings[:sis_default_grade_export] = {locked: false, value: true}
      a.save!
      post 'create', params: {:course_id => @course.id, :assignment => {:title => "some assignment"}}
      expect(assigns[:assignment]).to be_post_to_sis
    end
  end

  describe "GET 'edit'" do
    include_context "grading periods within controller" do
      let(:course) { @course }
      let(:teacher) { @teacher }
      let(:request_params) { [:edit, params: {course_id: course, id: @assignment}] }
    end

    shared_examples 'course feature flags for Anonymous Moderated Marking' do
      before(:each) do
        user_session(@teacher)
      end

      it 'is false when the feature flag is not enabled' do
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][js_env_attribute]).to be false
      end

      it 'is true when the feature flag is enabled' do
        @course.enable_feature!(feature_flag)
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][js_env_attribute]).to be true
      end
    end

    it "js_env CANCEL_TO points to quizzes when quiz_lti? is true" do
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get 'new', params: { :course_id => @course.id, :quiz_lti => true }
      expect(assigns[:js_env][:CANCEL_TO]).to include('quizzes')
    end

    it "js_env CANCEL_TO points to assignments when quiz_lti? is not included" do
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get 'new', params: { :course_id => @course.id, id: @assignment.id }
      expect(assigns[:js_env][:CANCEL_TO]).to include('assignments')
    end

    it "js_env CANCEL_TO points to assignments when newquizzes_on_quiz_page feature flag is off" do
      @course.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @course.root_account.enable_feature! :quizzes_next
      @course.enable_feature! :quizzes_next
      user_session(@teacher)
      get 'new', params: { :course_id => @course.id, :quiz_lti => true }
      expect(assigns[:js_env][:CANCEL_TO]).to include('assignments')
    end

    it "should require authorization" do
      # controller.use_rails_error_handling!
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      assert_unauthorized
    end

    it "should find assignment" do
      user_session(@student)
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:assignment]).to eql(@assignment)
    end

    it "should set 'ROOT_OUTCOME_GROUP' in js_env" do
      user_session @teacher
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}

      expect(assigns[:js_env][:ROOT_OUTCOME_GROUP]).not_to be_nil
    end

    it "bootstraps the correct assignment info to js_env" do
      user_session(@teacher)
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: '12345', shared_secret: 'secret')
      @assignment.tool_settings_tool = tool

      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:ASSIGNMENT]['id']).to eq @assignment.id
      expect(assigns[:js_env][:ASSIGNMENT_OVERRIDES]).to eq []
      expect(assigns[:js_env][:COURSE_ID]).to eq @course.id
      expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_ID]).to eq tool.id
      expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_TYPE]).to eq tool.class.to_s
    end

    it "bootstrap the assignment originality report visibility settings to js_env" do
      user_session(@teacher)
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:REPORT_VISIBILITY_SETTING]).to eq('immediate')
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return('Foo Bar')
      get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:js_env][:SIS_NAME]).to eq('Foo Bar')
    end

    it 'js_env AVAILABLE_MODERATORS includes the name and id for each available moderator' do
      user_session(@teacher)
      @assignment.update!(grader_count: 2, moderated_grading: true)
      get :edit, params: { course_id: @course.id, id: @assignment.id }
      expected_moderators = @course.instructors.map { |user| { name: user.name, id: user.id } }
      expect(assigns[:js_env][:AVAILABLE_MODERATORS]).to match_array expected_moderators
    end

    it 'js_env MODERATED_GRADING_MAX_GRADER_COUNT is the max grader count for the assignment' do
      user_session(@teacher)
      get :edit, params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:MODERATED_GRADING_MAX_GRADER_COUNT]).to eq @assignment.moderated_grading_max_grader_count
    end

    it 'js_env SUBMISSION_TYPE_SELECTION_TOOLS is correctly set for submission type tools' do
      @course.root_account.enable_feature! :submission_type_tool_placement
      tool_settings = {
        base_title: 'my title',
        external_url: 'https://tool.launch.url',
        selection_width: 750,
        selection_height: 480,
        icon_url: nil,
      }
      @tool = factory_with_protected_attributes(@course.context_external_tools,
        :url => "http://www.justanexamplenotarealwebsite.com/tool1",
        :shared_secret => 'test123',
        :consumer_key => 'test123',
        :name => tool_settings[:base_title],
        :settings => {
          :submission_type_selection => tool_settings
        }
      )
      user_session(@teacher)

      get :edit, params: { course_id: @course.id, id: @assignment.id }
      expect(assigns[:js_env][:SUBMISSION_TYPE_SELECTION_TOOLS][0]).to include(
        base_title: tool_settings[:base_title],
        title: tool_settings[:base_title],
        selection_width: tool_settings[:selection_width],
        selection_height: tool_settings[:selection_height]
      )
    end

    context 'when the root account does not have a default tool url set' do
      let(:course) { @course }
      let(:root_account) { course.root_account }

      before do
        user_session(@teacher)
        get :edit, params: { course_id: course.id, id: @assignment.id }
      end

      it 'does not set "DEFAULT_ASSIGNMENT_TOOL_URL"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_URL)).to be_nil
      end

      it 'does not set "DEFAULT_ASSIGNMENT_TOOL_NAME"' do
        expect(assigns.dig(:js_env, :DEFAULT_ASSIGNMENT_TOOL_NAME)).to be_nil
      end
    end

    context 'when the root account has a default tool url and name set' do
      let(:course) { @course }
      let(:root_account) { course.root_account }
      let(:default_url) { 'https://www.my-tool.com/blti' }
      let(:default_name) { 'Default Name' }
      let(:button_text) { 'Click Me' }
      let(:info_message) { 'Some information for you.' }

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

    describe 'js_env ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED' do
      before(:each) do
        user_session(@teacher)
      end

      it 'is true when the course has anonymous_instructor_annotations on' do
        @course.enable_feature!(:anonymous_instructor_annotations)
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be true
      end

      it 'is true when the account has anonymous_instructor_annotations on' do
        @course.account.enable_feature!(:anonymous_instructor_annotations)
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be true
      end

      it 'is false when the course has anonymous_instructor_annotations off' do
        @course.disable_feature!(:anonymous_instructor_annotations)
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be false
      end

      it 'is false when the account has anonymous_instructor_annotations off' do
        @course.account.disable_feature!(:anonymous_instructor_annotations)
        get 'edit', params: { course_id: @course.id, id: @assignment.id }

        expect(assigns[:js_env][:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED]).to be false
      end
    end

    context 'plagiarism detection platform' do
      include_context 'lti2_spec_helper'

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
          tool_type: 'Lti::MessageHandler',
          tool_id: message_handler.id
        )
      end

      it "bootstraps the correct message_handler id for LTI 2 tools to js_env" do
        user_session(@teacher)
        get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
        expect(assigns[:js_env][:SELECTED_CONFIG_TOOL_ID]).to eq message_handler.id
      end

      it "bootstraps the correct EULA link for the associated LTI 2 tool" do
        tool_proxy.raw_data['tool_profile']['service_offered'] = service_offered
        tool_proxy.save!

        user_session(@student)
        get 'show', params: {:course_id => @course.id, :id => @assignment.id}
        expect(assigns[:js_env][:EULA_URL]).to eq service_offered[0]['endpoint']
      end
    end

    context "redirects" do
      before do
        user_session(@teacher)
      end

      it "to quiz" do
        assignment_quiz [], course: @course
        get 'edit', params: {:course_id => @course.id, :id => @quiz.assignment.id}
        expect(response).to redirect_to controller.edit_course_quiz_path(@course, @quiz)
      end

      it "to discussion topic" do
        group_assignment_discussion course: @course
        get 'edit', params: {:course_id => @course.id, :id => @root_topic.assignment.id}
        expect(response).to redirect_to controller.edit_course_discussion_topic_path(@course, @root_topic)
      end

      it "to wiki page" do
        @course.enable_feature!(:conditional_release)
        wiki_page_assignment_model course: @course
        get 'edit', params: {:course_id => @course.id, :id => @page.assignment.id}
        expect(response).to redirect_to controller.edit_course_wiki_page_path(@course, @page)
      end

      it "includes return_to" do
        assignment_quiz [], course: @course
        get 'edit', params: {:course_id => @course.id, :id => @quiz.assignment.id, :return_to => 'flibberty'}
        expect(response.redirect_url).to match(/\?return_to=flibberty/)
      end
    end

    context "conditional release" do
      before do
        allow(ConditionalRelease::Service).to receive(:env_for).and_return({ dummy: 'cr-assignment' })
      end

      it "should define env when enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        user_session(@teacher)
        get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
        expect(assigns[:js_env][:dummy]).to eq 'cr-assignment'
      end

      it "should not define env when not enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
        user_session(@teacher)
        get 'edit', params: {:course_id => @course.id, :id => @assignment.id}
        expect(assigns[:js_env][:dummy]).to be nil
      end
    end

    describe 'js_env ANONYMOUS_GRADING_ENABLED' do
      it_behaves_like 'course feature flags for Anonymous Moderated Marking' do
        let(:js_env_attribute) { :ANONYMOUS_GRADING_ENABLED }
        let(:feature_flag) { :anonymous_marking }
      end
    end

    describe 'js_env MODERATED_GRADING_ENABLED' do
      it_behaves_like 'course feature flags for Anonymous Moderated Marking' do
        let(:js_env_attribute) { :MODERATED_GRADING_ENABLED }
        let(:feature_flag) { :moderated_grading }
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      delete 'destroy', params: {:course_id => @course.id, :id => @assignment.id}
      assert_unauthorized
    end

    it "should delete assignments if authorized" do
      user_session(@teacher)
      delete 'destroy', params: {:course_id => @course.id, :id => @assignment.id}
      expect(assigns[:assignment]).not_to be_nil
      expect(assigns[:assignment]).not_to be_frozen
      expect(assigns[:assignment]).to be_deleted
    end
  end

  describe "POST 'publish'" do
    it "should require authorization" do
      post 'publish_quizzes', params: { course_id: @course.id, quizzes: [@assignment.id] }
      assert_unauthorized
    end

    it "should publish unpublished assignments" do
      user_session(@teacher)
      @assignment = @course.assignments.build(title: 'New quiz!', workflow_state: 'unpublished')
      @assignment.save!

      expect(@assignment).not_to be_published
      post 'publish_quizzes', params: { course_id: @course.id, quizzes: [@assignment.id] }

      expect(@assignment.reload).to be_published
    end
  end

  describe "POST 'unpublish'" do
    it "should require authorization" do
      post 'unpublish_quizzes', params: { course_id: @course.id, quizzes: [@assignment.id] }
      assert_unauthorized
    end

    it "should unpublish published quizzes" do
      user_session(@teacher)
      @assignment = @course.assignments.create(title: 'New quiz!', workflow_state: 'published')

      expect(@assignment).to be_published
      post 'unpublish_quizzes', params: { course_id: @course.id, quizzes: [@assignment.id] }

      expect(@assignment.reload).not_to be_published
    end
  end

  describe "GET list_google_docs" do
    it "passes errors through to Canvas::Errors" do
      user_session(@teacher)
      connection = double()
      allow(connection).to receive(:list_with_extension_filter).and_raise(ArgumentError)
      allow(controller).to receive(:google_drive_connection).and_return(connection)
      allow_any_instance_of(Assignment).to receive(:allow_google_docs_submission?).and_return(true)
      expect(Canvas::Errors).to receive(:capture_exception)
      params = {course_id: @course.id, id: @assignment.id}
      get 'list_google_docs', params: params, format: 'json'
      expect(response.code).to eq("200")
    end
  end

end
