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

describe Quizzes::QuizzesController do
  def course_quiz(active = false, title = nil)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.title = title if title
    @quiz.save!
    @quiz
  end

  def quiz_question
    @quiz.quiz_questions.create
  end

  def quiz_group
    @quiz.quiz_groups.create
  end

  def temporary_user_code(generate = true)
    if generate
      session[:temporary_user_code] ||= "tmp_#{Digest::SHA256.hexdigest("#{Time.now.to_i}_#{rand}")}"
    else
      session[:temporary_user_code]
    end
  end

  def logged_out_survey_with_submission(user, questions)
    user_session(@teacher)

    @assignment = @course.assignments.create(title: "Test Assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_quiz"
    @assignment.save
    @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
    @quiz.anonymous_submissions = false
    @quiz.quiz_type = "survey"

    @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
    @quiz.generate_quiz_data
    @quiz.save!

    @quiz_submission = @quiz.generate_submission(user)
    @quiz_submission.mark_completed
    @quiz_submission.submission_data = yield if block_given?
    Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
    @quiz_submission.save!
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @student2 = @student
    student_in_course(active_all: true)
  end

  describe "GET 'index'" do
    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 4, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns JS variables" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(controller.js_env[:QUIZZES][:assignment]).not_to be_nil
      expect(controller.js_env[:QUIZZES][:open]).not_to be_nil
      expect(controller.js_env[:QUIZZES][:surveys]).not_to be_nil
      expect(controller.js_env[:QUIZZES][:options]).not_to be_nil
    end

    it "filters out unpublished quizzes for student" do
      user_session(@student)
      course_quiz
      course_quiz(true)

      get "index", params: { course_id: @course.id }

      expect(controller.js_env[:QUIZZES][:assignment].length).to be 1
      controller.js_env[:QUIZZES][:assignment].map do |quiz|
        expect(quiz[:published]).to be_truthy
      end
    end

    it "implicitly grades outstanding submissions for user in course" do
      user_session(@student)
      course_quiz(true)

      expect(Quizzes::OutstandingQuizSubmissionManager).to receive(:grade_by_course)

      get "index", params: { course_id: @course.id }
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

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return("Foo Bar")
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("Foo Bar")
    end

    it "js_env quiz_lti_enabled is true when quizzes_next/newquizzes_on_quiz_page is enabled" do
      user_session(@teacher)
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
      expect(assigns[:js_env][:FLAGS][:quiz_lti_enabled]).to be true
    end

    it "js_env quiz_lti_enabled is false when newquizzes_on_quiz_page is disabled" do
      user_session(@teacher)
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
      expect(assigns[:js_env][:FLAGS][:quiz_lti_enabled]).to be false
    end

    it "js_env quiz_lti_enabled is false when quizzes_next is disabled" do
      user_session(@teacher)
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.root_account.enable_feature! :newquizzes_on_quiz_page
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:quiz_lti_enabled]).to be false
    end

    it "js_env quiz_lti_enabled is false when new quizzes is not available" do
      user_session @teacher
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:quiz_lti_enabled]).to be false
    end

    it "js_env migrate_quiz_enabled is false when only quizzes_next is enabled" do
      user_session(@teacher)
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.enable_feature!(:quizzes_next)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:migrate_quiz_enabled]).to be(false)
    end

    it "js_env migrate_quiz_enabled is true when quizzes_next is enabled and quiz LTI apps present" do
      user_session(@teacher)
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.root_account.enable_feature!(:quizzes_next)
      @course.enable_feature!(:quizzes_next)
      @course.context_external_tools.create(name: "a",
                                            domain: "google.com",
                                            consumer_key: "12345",
                                            shared_secret: "secret",
                                            tool_id: "Quizzes 2")
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:FLAGS][:migrate_quiz_enabled]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
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

    context "DIRECT_SHARE_ENABLED" do
      before :once do
        course_quiz
      end

      it "js_env DIRECT_SHARE_ENABLED is true when user can manage" do
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:FLAGS][:DIRECT_SHARE_ENABLED]).to be(true)
      end

      describe "with manage_course_content_add permission disabled" do
        before do
          RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
        end

        it "js_env DIRECT_SHARE_ENABLED is false if the course is active" do
          user_session(@teacher)
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:FLAGS][:DIRECT_SHARE_ENABLED]).to be(false)
        end

        describe "when the course is concluded" do
          before do
            @course.complete!
          end

          it "js_env DIRECT_SHARE_ENABLED is true when user can manage" do
            user_session(@teacher)

            get "index", params: { course_id: @course.id }
            expect(assigns[:js_env][:FLAGS][:DIRECT_SHARE_ENABLED]).to be(true)
          end

          it "js_env DIRECT_SHARE_ENABLED is false when user can't manage" do
            user_session(@student)

            get "index", params: { course_id: @course.id }
            expect(assigns[:js_env][:FLAGS][:DIRECT_SHARE_ENABLED]).to be(false)
          end
        end
      end
    end

    context "when newquizzes_on_quiz_page FF is enabled" do
      let_once(:due_at) { 1.week.from_now }
      let_once(:course_assignments) do
        group = @course.assignment_groups.create(name: "some group")
        (0..3).map do |i|
          @course.assignments.create(
            title: "some assignment #{i}",
            assignment_group: group,
            due_at:,
            external_tool_tag_attributes: { content: tool },
            workflow_state: workflow_states[i]
          )
        end
      end

      let_once(:course_quizzes) do
        [course_quiz(false, "quiz 1"), course_quiz(true, "quiz 2")]
      end

      let_once(:workflow_states) do
        %i[unpublished published unpublished published]
      end

      let_once(:tool) do
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
      end

      before :once do
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.enable_feature! :quizzes_next
        @course.root_account.enable_feature! :newquizzes_on_quiz_page
        # make the last two of course_assignments to be quiz_lti assignment
        (2..3).each { |i| course_assignments[i].quiz_lti! && course_assignments[i].save! }
        course_quizzes
      end

      context "teacher interface" do
        it "includes all old quizzes and new quizzes, sorted by [due_date, title]" do
          user_session(@teacher)
          get "index", params: { course_id: @course.id }
          expect(controller.js_env[:QUIZZES][:assignment]).not_to be_nil
          expect(controller.js_env[:QUIZZES][:assignment].count).to eq(4)

          expect(
            controller.js_env[:QUIZZES][:assignment].map { |x| [x[:id], x[:due_at], x[:title]] }
          ).to eq([
                    [course_assignments[2].id, due_at, "some assignment 2"],
                    [course_assignments[3].id, due_at, "some assignment 3"],
                    [course_quizzes[0].id, nil, "quiz 1"],
                    [course_quizzes[1].id, nil, "quiz 2"]
                  ])
        end

        describe "quiz options" do
          it "includes 'can_unpublish' true when the assignment can be unpublished" do
            allow_any_instance_of(Assignment).to receive(:can_unpublish?).and_return(true)
            allow_any_instance_of(Quizzes::Quiz).to receive(:can_unpublish?).and_return(true)

            user_session(@teacher)
            get "index", params: { course_id: @course.id }

            expect(controller.js_env[:QUIZZES][:options]).not_to be_nil
            expect(controller.js_env[:QUIZZES][:options].count).to eq(4)

            controller.js_env[:QUIZZES][:options].each_value do |assignment_options|
              expect(assignment_options[:can_unpublish]).to be true
            end
          end

          it "includes `can_unpublish` false when the assignment cannot be unpublished" do
            allow_any_instance_of(Assignment).to receive(:can_unpublish?).and_return(false)
            allow_any_instance_of(Quizzes::Quiz).to receive(:can_unpublish?).and_return(false)

            user_session(@teacher)
            get "index", params: { course_id: @course.id }

            expect(controller.js_env[:QUIZZES][:options]).not_to be_nil
            expect(controller.js_env[:QUIZZES][:options].count).to eq(4)

            controller.js_env[:QUIZZES][:options].each_value do |assignment_options|
              expect(assignment_options[:can_unpublish]).to be false
            end
          end

          it "includes blueprint restriction_data" do
            @course.master_course_templates.for_full_course.first_or_create
            account_admin_user(account: @course.root_account)
            user_session(@admin)
            get "index", params: { course_id: @course.id }

            controller.js_env[:QUIZZES][:assignment].select { |a| a[:quiz_type] == "quizzes.next" }
                      .each do |assignment|
                        expect(assignment["is_master_course_master_content"]).to be true
                      end
          end
        end
      end

      context "student interface" do
        it "includes published quizzes" do
          user_session(@student)
          get "index", params: { course_id: @course.id }
          expect(controller.js_env[:QUIZZES][:assignment]).not_to be_nil
          expect(controller.js_env[:QUIZZES][:assignment].count).to eq(2)
          expect(
            controller.js_env[:QUIZZES][:assignment].pluck(:id)
          ).to contain_exactly(course_quizzes[1].id, course_assignments[3].id)
        end
      end
    end
  end

  describe "POST 'new'" do
    context "when unauthorized" do
      it "requires authorization" do
        post "new", params: { course_id: @course.id }
        assert_unauthorized
      end
    end

    context "when authorized" do
      before { user_session(@teacher) }

      it "creates a quiz" do
        expect { post "new", params: { course_id: @course.id } }
          .to change { Quizzes::Quiz.count }
          .from(0).to(1)
      end

      it "redirects to the new quiz" do
        post "new", params: { course_id: @course.id }
        expect(response).to have_http_status :redirect
        expect(response.headers["Location"]).to match(%r{/courses/\w+/quizzes/\w+/edit$})
      end

      context "if xhr request" do
        it "returns the new quiz's edit url" do
          post "new", params: { course_id: @course.id }, xhr: true
          expect(response).to be_successful
          expect(response.parsed_body["url"]).to match(%r{/courses/\w+/quizzes/\w+/edit$})
        end
      end
    end
  end

  describe "GET 'edit'" do
    before(:once) { course_quiz }

    include_context "grading periods within controller" do
      let(:course) { @course }
      let(:teacher) { @teacher }
      let(:request_params) { [:edit, params: { course_id: course, id: @quiz }] }
    end

    it "requires authorization" do
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      assert_unauthorized
      expect(assigns[:quiz]).not_to be_nil
    end

    it "assigns variables" do
      user_session(@teacher)
      regrade = @quiz.quiz_regrades.create!(user_id: @teacher.id, quiz_version: @quiz.version_number)
      q = @quiz.quiz_questions.create!
      regrade.quiz_question_regrades.create!(quiz_question_id: q.id, regrade_option: "no_regrade")
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:js_env][:REGRADE_OPTIONS]).to eq({ q.id => "no_regrade" })
      expect(response).to render_template("new")
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(true)
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(false)
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      user_session(@teacher)
      allow(AssignmentUtil).to receive(:assignment_max_name_length).and_return(15)
      get "edit", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    context "conditional release" do
      before do
        allow(ConditionalRelease::Service).to receive(:env_for).and_return({ dummy: "charliemccarthy" })
      end

      it "defines env when enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        user_session(@teacher)
        get "edit", params: { course_id: @course.id, id: @quiz.id }
        expect(assigns[:js_env][:dummy]).to eq "charliemccarthy"
      end

      it "does not define env when not enabled" do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
        user_session(@teacher)
        get "edit", params: { course_id: @course.id, id: @quiz.id }
        expect(assigns[:js_env][:dummy]).to be_nil
      end
    end
  end

  describe "GET 'show'" do
    it "requires authorization" do
      course_quiz
      get "show", params: { course_id: @course.id, id: @quiz.id }
      assert_unauthorized
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
    end

    it "assigns variables" do
      user_session(@teacher)
      course_quiz
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:question_count]).to eql(@quiz.question_count)
      expect(assigns[:just_graded]).to be(false)
      expect(assigns[:stored_params]).not_to be_nil
    end

    it "sets the submission count variables" do
      @section = @course.course_sections.create!(name: "section 2")
      @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
      @section.enroll_user(@user2, "StudentEnrollment", "active")
      @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(active_all: true, name: "TA1", username: "ta1@instructure.com")
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
      course_quiz
      @sub1 = @quiz.generate_submission(@user1)
      @sub2 = @quiz.generate_submission(@user2)
      @sub2.start_grading
      @sub2.update_attribute(:workflow_state, "pending_review")

      user_session @teacher
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:submitted_student_count]).to eq 2
      expect(assigns[:any_submissions_pending_review]).to be true

      controller.js_env.clear

      user_session @ta1
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:submitted_student_count]).to eq 1
      expect(assigns[:any_submissions_pending_review]).to be false
    end

    it "allows forcing authentication on public quiz pages" do
      @course.update_attribute :is_public, true
      course_quiz(true)
      get "show", params: { course_id: @course.id, id: @quiz.id, force_user: 1 }
      expect(response).to be_redirect
      expect(response.location).to match(/login/)
    end

    it "renders the show page for public courses" do
      @course.update_attribute :is_public, true
      course_quiz(true)
      get "show", params: { course_id: @course.id, id: @quiz.id, take: "1" }
      expect(response).to be_successful
    end

    it "sets session[headless_quiz] if persist_headless param is sent" do
      user_session(@student)
      course_quiz(true)
      get "show", params: { course_id: @course.id, id: @quiz.id, persist_headless: 1 }
      expect(controller.session[:headless_quiz]).to be_truthy
      expect(assigns[:headers]).to be_falsey
    end

    it "does not render headers if session[:headless_quiz] is set" do
      user_session(@student)
      course_quiz(true)
      controller.session[:headless_quiz] = true
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:headers]).to be_falsey
    end

    it "assigns js_env for attachments if submission is present" do
      user_session(@student)
      course_quiz(true)
      submission = @quiz.generate_submission @student
      create_attachment_for_file_upload_submission!(submission)
      get "show", params: { course_id: @course.id, id: @quiz.id }
      attachment = submission.attachments.first

      attach = assigns[:js_env][:ATTACHMENTS][attachment.id]
      expect(attach[:id]).to eq attachment.id
      expect(attach[:display_name]).to eq attachment.display_name
    end

    describe "js_env SUBMISSION_VERSIONS_URL" do
      before do
        user_session(@student)
        course_quiz(true)
      end

      let(:submission) { @quiz.generate_submission(@student) }

      it "is assigned if a quiz submission is present and posted to the student" do
        Quizzes::SubmissionGrader.new(submission).grade_submission
        create_attachment_for_file_upload_submission!(submission)
        get "show", params: { course_id: @course.id, id: @quiz.id }
        path = "courses/#{@course.id}/quizzes/#{@quiz.id}/submission_versions"
        expect(assigns[:js_env][:SUBMISSION_VERSIONS_URL]).to include(path)
      end

      it "is not assigned if a quiz submission is present but hidden for the student" do
        @quiz.assignment.post_policy.update!(post_manually: true)
        Quizzes::SubmissionGrader.new(submission).grade_submission
        create_attachment_for_file_upload_submission!(submission)
        get "show", params: { course_id: @course.id, id: @quiz.id }
        expect(assigns[:js_env]).not_to include(:SUBMISSION_VERSIONS_URL)
      end
    end

    it "assigns js_env for quiz details url" do
      user_session(@teacher)
      course_quiz
      get "show", params: { course_id: @course.id, id: @quiz.id }
      path = "courses/#{@course.id}/quizzes/#{@quiz.id}/managed_quiz_data"
      expect(assigns[:js_env][:QUIZ_DETAILS_URL]).to include(path)
    end

    it "doesn't show unpublished quizzes to students with draft state" do
      user_session(@student)
      course_quiz(true)
      @quiz.unpublish!
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(response).not_to be_successful
    end

    it 'logs a single asset access entry with an action level of "view"' do
      Thread.current[:context] = { request_id: "middleware doesn't run in controller specs so let's make one up" }
      Setting.set("enable_page_views", "db")

      user_session(@teacher)
      course_quiz
      get "show", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:access]).not_to be_nil
      expect(assigns[:accessed_asset]).not_to be_nil
      expect(assigns[:accessed_asset][:level]).to eq "view"
      expect(assigns[:access].view_score).to eq 1
      Thread.current[:context] = nil
    end

    it "locks results if there is a submission and one_time_results is on" do
      user_session(@student)

      course_quiz(true)
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      submission = @quiz.generate_submission @student
      submission.mark_completed
      submission.save

      get "show", params: { course_id: @course.id, id: @quiz.id }

      expect(response).to be_successful
      expect(submission.reload.has_seen_results).to be true
    end

    it "does not attempt to lock results if there is a settings only submission" do
      user_session(@student)

      course_quiz(true)
      @quiz.lock_at = 2.days.ago
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      sub_manager = Quizzes::SubmissionManager.new(@quiz)
      submission = sub_manager.find_or_create_submission(@student, nil, "settings_only")
      submission.manually_unlocked = true
      submission.save!

      get "show", params: { course_id: @course.id, id: @quiz.id }

      expect(response).to be_successful
      expect(submission.reload.has_seen_results).to be_nil
    end

    context "with non-utf8 multiple dropdown question" do
      render_views

      let(:answer) do
        {
          "id" => rand(1..999),
          "text" => "\b你好", # the \b causes psych to store this as a binary string
          "blank_id" => "blank"
        }
      end

      before do
        course_quiz(true)

        @quiz.quiz_questions.create!(question_data: {
                                       "question_type" => "multiple_dropdowns_question",
                                       "question_text" => "<p>Hello in Chinese is [blank]</p>",
                                       "answers" => [answer]
                                     })
        @quiz.generate_quiz_data
        @quiz.save!
      end

      it "renders preview without error" do
        quiz_submission = @quiz.generate_submission(@student)
        quiz_submission.mark_completed
        quiz_submission.quiz_data = [{ "answers" => [answer] }]
        quiz_submission.temporary_user_code = temporary_user_code
        quiz_submission.save!

        user_session(@teacher)
        get "show", params: { course_id: @course.id, id: @quiz.id, take: "1", preview: "1" }
        expect(response).to be_successful
      end
    end
  end

  describe "GET 'managed_quiz_data'" do
    it "respects section privilege limitations" do
      @course.student_enrollments.destroy_all
      @section = @course.course_sections.create!(name: "section 2")
      @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
      @section.enroll_user(@user2, "StudentEnrollment", "active")
      @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(active_all: true, name: "TA1", username: "ta1@instructure.com")
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
      course_quiz
      @sub1 = @quiz.generate_submission(@user1)
      @sub2 = @quiz.generate_submission(@user2)
      user_session @teacher
      get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:submissions_from_users][@sub1.user_id]).to eq @sub1
      expect(assigns[:submissions_from_users][@sub2.user_id]).to eq @sub2
      expect(assigns[:submitted_students].sort_by(&:id)).to eq [@user1, @user2].sort_by(&:id)

      user_session @ta1
      get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:submissions_from_users][@sub1.user_id]).to eq @sub1
      expect(assigns[:submitted_students]).to eq [@user1]
    end

    it "includes survey results from logged out users in a public course" do
      # logged out user
      user = temporary_user_code

      # make questions
      questions = [{ question_data: { name: "test 1" } },
                   { question_data: { name: "test 2" } },
                   { question_data: { name: "test 3" } },
                   { question_data: { name: "test 4" } }]

      logged_out_survey_with_submission user, questions

      get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }

      expect(assigns[:submissions_from_logged_out]).to eq [@quiz_submission]
      expect(assigns[:submissions_from_users]).to eq({})
    end

    it "includes survey results from a logged-in user in a public course" do
      user_session(@teacher)

      @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
      @course.enroll_student(@user1)

      questions = [{ question_data: { name: "test 1" } },
                   { question_data: { name: "test 2" } },
                   { question_data: { name: "test 3" } },
                   { question_data: { name: "test 4" } }]

      @assignment = @course.assignments.create(title: "Test Assignment")
      @assignment.workflow_state = "available"
      @assignment.submission_types = "online_quiz"
      @assignment.save
      @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
      @quiz.anonymous_submissions = true
      @quiz.quiz_type = "survey"

      @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
      @quiz.generate_quiz_data
      @quiz.save!

      @quiz_submission = @quiz.generate_submission(@user1)
      @quiz_submission.mark_completed

      get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }

      expect(assigns[:submissions_from_users][@quiz_submission.user_id]).to eq @quiz_submission
      expect(assigns[:submitted_students]).to eq [@user1]
    end

    it "does not include teacher previews" do
      user_session(@teacher)

      quiz = quiz_model(course: @course)
      quiz.publish!

      quiz_submission = quiz.generate_submission(@teacher, true)
      quiz_submission.complete!

      get "managed_quiz_data", params: { course_id: @course.id, quiz_id: quiz.id }

      expect(assigns[:submissions_from_users]).to be_empty
      expect(assigns[:submissions_from_logged_out]).to be_empty
      expect(assigns[:submitted_students]).to be_empty
    end

    context "differentiated_assignments" do
      it "only returns submissions and users when there is visibility" do
        user_session(@teacher)

        @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @course.enroll_student(@user1)

        questions = [{ question_data: { name: "test 1" } }]

        @assignment = @course.assignments.create(title: "Test Assignment")
        @assignment.workflow_state = "available"
        @assignment.submission_types = "online_quiz"
        @assignment.save
        @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
        @quiz.anonymous_submissions = true
        @quiz.quiz_type = "survey"

        @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
        @quiz.generate_quiz_data
        @quiz.only_visible_to_overrides = true
        @quiz.save!

        @quiz_submission = @quiz.generate_submission(@user1)
        @quiz_submission.mark_completed

        get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }

        expect(assigns[:submissions_from_users][@quiz_submission.user_id]).to be_nil
        expect(assigns[:submitted_students]).to eq []

        create_section_override_for_quiz(@quiz, { course_section: @user1.enrollments.first.course_section })

        get "managed_quiz_data", params: { course_id: @course.id, quiz_id: @quiz.id }

        expect(assigns[:submissions_from_users][@quiz_submission.user_id]).to eq @quiz_submission
        expect(assigns[:submitted_students]).to eq [@user1]
      end
    end
  end

  describe "GET 'moderate'" do
    before(:once) { course_quiz }

    it "requires authorization" do
      get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }
      assert_unauthorized
    end

    context "student_filters" do
      before do
        user_session(@teacher)
        5.times do |i|
          name = "#{(i + "a".ord).chr}_student"
          course_with_student(name:, course: @course)
        end
      end

      it "sorts students" do
        get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }
        expect(assigns[:students] - assigns[:students].sort_by(&:sortable_name)).to eq []
      end

      it "filters students" do
        get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id, search_term: "a" }

        expect(assigns[:students].count).to eq 1
        expect(assigns[:students].first.sortable_name).to eq "a_student"
      end
    end

    it "assigns variables" do
      user_session(@teacher)
      sub = @quiz.generate_submission(@student)
      get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:quiz]).to eq @quiz
      expect(assigns[:students]).to include @student
      expect(assigns[:submissions]).to eq [sub]
    end

    it "respects section privilege limitations" do
      section = @course.course_sections.create!(name: "section 2")
      @student2.enrollments.update_all(course_section_id: section.id)

      ta1 = user_with_pseudonym(active_all: true, name: "TA1", username: "ta1@instructure.com")
      @course.enroll_ta(ta1).update_attribute(:limit_privileges_to_course_section, true)
      sub1 = @quiz.generate_submission(@student)
      sub2 = @quiz.generate_submission(@student2)

      user_session @teacher
      get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:students].sort_by(&:id)).to eq [@student, @student2].sort_by(&:id)
      expect(assigns[:submissions].sort_by(&:id)).to eq [sub1, sub2].sort_by(&:id)

      user_session ta1
      get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:students]).to eq [@student]
      expect(assigns[:submissions]).to eq [sub1]
    end

    it "does not show duplicate students if they are enrolled in multiple sections" do
      section = @course.course_sections.create!(name: "section 2")
      @course.enroll_user(@student, "StudentEnrollment", {
                            enrollment_state: "active",
                            section:,
                            allow_multiple_enrollments: true
                          })

      expect(@student.reload.enrollments.count).to eq 2

      user_session @teacher
      get "moderate", params: { course_id: @course.id, quiz_id: @quiz.id }

      expect(assigns[:students].sort_by(&:id)).to eq [@student, @student2].sort_by(&:id)
    end

    context "for a differentiated quiz" do
      let(:students) do
        (1..3).map do |i|
          user_with_pseudonym(active_all: true, name: "Student#{i}", username: "student#{i}@instructure.com")
        end
      end

      let(:assignments) do
        (1..3).map do |i|
          @course.assignments.create(
            title: "Test Assignment#{i}",
            workflow_state: "available",
            submission_types: "online_quiz"
          )
        end
      end

      let(:quizzes) do
        (1..3).map do |i|
          questions = [{ question_data: { name: "test #{i}" } }]

          quiz = Quizzes::Quiz.where(assignment_id: assignments[i - 1].id).first

          quiz.quiz_type = "assignment"
          quiz.only_visible_to_overrides = true

          questions.each { |q| quiz.quiz_questions.create!(q) }
          quiz.generate_quiz_data
          quiz.save!
          quiz
        end
      end

      let(:sections) do
        (0..1).map do
          @course.course_sections.create!
        end
      end

      before do
        3.times do |i|
          @course.enroll_student(students[i])
        end

        2.times do |i|
          quizzes[i].assignment_overrides.create!(
            set: sections[i]
          )
        end

        # make quizzes[2] available to everyone
        quizzes[2].only_visible_to_overrides = false
        quizzes[2].save!

        students[0].enrollments.update_all(course_section_id: sections[0].id)
        students[1].enrollments.update_all(course_section_id: sections[1].id)
        # make an inactive enrollment
        students[2].enrollments.update_all(course_section_id: sections[1].id, workflow_state: "inactive")
      end

      it "only returns students in the assigned course sections" do
        user_session(@teacher)

        get "moderate", params: { course_id: @course.id, quiz_id: quizzes[0].id }

        expect(assigns[:students].count).to eq 1
        expect(assigns[:students].first).to eq students[0]
      end

      it "does not includes inactive enrollments" do
        user_session(@teacher)

        get "moderate", params: { course_id: @course.id, quiz_id: quizzes[1].id }

        expect(assigns[:students].count).to eq 1
        expect(assigns[:students]).to contain_exactly(students[1])
      end

      it "return every active enrollments in the course for a non-differentiated quiz" do
        user_session(@teacher)

        get "moderate", params: { course_id: @course.id, quiz_id: quizzes[2].id }

        expect(assigns[:students].count).to eq @course.student_enrollments.count
      end
    end
  end

  describe "POST 'take'" do
    it "requires authorization" do
      course_quiz(true)
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      assert_unauthorized
    end

    it "allows taking the quiz" do
      user_session(@student)
      course_quiz(true)
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    context "asset access logging" do
      before :once do
        Setting.set("enable_page_views", "db")

        course_quiz
      end

      before do
        allow(RequestContext::Generator).to receive(:request_id).and_return(SecureRandom.uuid)
        user_session(@teacher)
      end

      it 'logs a single entry with an action level of "participate"' do
        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
        expect(assigns[:access]).not_to be_nil
        expect(assigns[:accessed_asset]).not_to be_nil
        expect(assigns[:accessed_asset][:level]).to eq "participate"
        expect(assigns[:access].participate_score).to eq 1
      end

      it "does not log entries when resuming the quiz" do
        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
        expect(assigns[:access]).not_to be_nil
        expect(assigns[:accessed_asset]).not_to be_nil
        expect(assigns[:accessed_asset][:level]).to eq "participate"
        expect(assigns[:access].participate_score).to eq 1
        aua = assigns[:access]

        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
        expect(aua.reload.participate_score).to eq 1
      end
    end

    context "verification" do
      before :once do
        course_quiz(true)
        @quiz.access_code = "bacon"
        @quiz.save!
      end

      before do
        user_session(@student)
      end

      it "renders verification page if password required" do
        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
        expect(response).to render_template("access_code")
      end

      it "does not let you in on a bad access code" do
        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1", access_code: "wrongpass" }
        expect(response).not_to be_redirect
        expect(response).to render_template("access_code")
      end

      it "sends you to take with the right access code" do
        post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1", access_code: "bacon" }
        expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      end

      it "does not ask for the access code again if you reload the quiz" do
        get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1", access_code: "bacon" }
        expect(response).not_to be_redirect
        expect(response).not_to render_template("access_code")

        controller.js_env.clear

        get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
        expect(response).not_to render_template("access_code")
      end
    end

    it "does not let them take the quiz if it's locked" do
      user_session(@student)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to render_template("show")
      expect(assigns[:locked]).not_to be_nil
    end

    it "lets them take the quiz if it's locked but unlocked by an override" do
      user_session(@student)
      course_quiz(true)
      @quiz.lock_at = Time.now
      @quiz.save!
      override = AssignmentOverride.new
      override.title = "ADHOC quiz override"
      override.quiz = @quiz
      override.lock_at = Time.now + 1.day
      override.lock_at_overridden = true
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = @user
      override_student.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "lets them take the quiz if it's locked but they've been explicitly unlocked" do
      user_session(@student)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      @sub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, nil, "settings_only")
      @sub.manually_unlocked = true
      @sub.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "uses default duration if no extensions specified" do
      user_session(@student)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user).to eql(@student)
      expect((assigns[:submission].end_at - assigns[:submission].started_at).to_i).to eql(60.minutes.to_i)
    end

    it "gives user more time if specified" do
      user_session(@student)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      @sub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, nil, "settings_only")
      @sub.extra_time = 30
      @sub.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user).to eql(@student)
      expect((assigns[:submission].end_at - assigns[:submission].started_at).to_i).to eql(90.minutes.to_i)
    end

    it "renders ip_filter page if ip_filter doesn't match" do
      user_session(@student)
      course_quiz(true)
      @quiz.ip_filter = "123.123.123.123"
      @quiz.save!
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to render_template("invalid_ip")
    end

    it "lets the user take the quiz if the ip_filter matches" do
      user_session(@student)
      course_quiz(true)
      @quiz.ip_filter = "123.123.123.123"
      @quiz.save!
      request.env["REMOTE_ADDR"] = "123.123.123.123"
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "works without a user for non-graded quizzes in public courses" do
      @course.update_attribute :is_public, true
      course_quiz :active
      @quiz.update_attribute :quiz_type, "practice_quiz"
      post "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end
  end

  describe "GET 'take'" do
    before :once do
      course_quiz(true)
    end

    it "requires authorization" do
      get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      assert_unauthorized
    end

    it "renders the quiz page if the user hasn't started the quiz" do
      user_session(@student)
      get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to render_template("show")
    end

    it "renders ip_filter page if the ip_filter stops matching" do
      user_session(@student)
      @quiz.ip_filter = "123.123.123.123"
      @quiz.save!
      @quiz.generate_submission(@student)

      get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to render_template("invalid_ip")
    end

    it "checks for the right access code" do
      user_session(@student)
      @quiz.access_code = "trust me. *winks*"
      @quiz.save!
      @quiz.generate_submission(@student)
      get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1", access_code: "NOT THE CODE" }
      expect(response).to render_template("access_code")
    end

    it "allows taking the quiz" do
      user_session(@student)
      @quiz.generate_submission(@student)

      get "show", params: { course_id: @course, quiz_id: @quiz.id, take: "1" }
      expect(response).to render_template("take_quiz")
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].user).to eql(@student)
    end

    context "when the ID of a question is passed in" do
      before :once do
        @quiz.generate_submission(@student)
      end

      before do
        user_session(@student)
      end

      context "a valid question" do
        it "renders take_quiz" do
          allow_any_instance_of(Quizzes::QuizzesController).to receive(:valid_question?).and_return(true)
          get "show", params: { course_id: @course, quiz_id: @quiz.id, question_id: "1", take: "1" }
          expect(response).to render_template("take_quiz")
        end
      end

      context "a question not in this quiz" do
        it "redirects to the main quiz page" do
          allow_any_instance_of(Quizzes::QuizzesController).to receive(:valid_question?).and_return(false)
          get "show", params: { course_id: @course, quiz_id: @quiz.id, question_id: "1", take: "1" }
          expect(response).to redirect_to course_quiz_url(@course, @quiz)
        end
      end
    end

    describe "valid_question?" do
      let(:submission) { double }

      context "when the passed in question ID is in the submission" do
        it "returns true" do
          allow(submission).to receive(:has_question?).with(1).and_return(true)
          expect(controller.send(:valid_question?, submission, 1)).to be_truthy
        end
      end

      context "when the question ID isn't part of the submission" do
        it "returns false" do
          allow(submission).to receive(:has_question?).with(1).and_return(false)
          expect(controller.send(:valid_question?, submission, 1)).to be_falsey
        end
      end
    end
  end

  describe "GET 'history'" do
    before :once do
      course_quiz
      @quiz.assignment.unmute!
    end

    it "requires authorization" do
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id }
      assert_unauthorized
    end

    it "requires view grade permissions to view a quiz submission" do
      role = Role.find_by(name: "TeacherEnrollment")
      ["view_all_grades", "manage_grades"].each do |permission|
        RoleOverride.create!(permission:, enabled: false, context: @course.account, role:)
      end

      user_session(@teacher)
      quiz_submission = @quiz.generate_submission(@student)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, quiz_submission_id: quiz_submission.id }
      assert_unauthorized
    end

    it "redirects if there are no submissions for the user" do
      user_session(@student)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_redirect
      expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
    end

    it "assigns variables" do
      user_session(@student)
      @submission = @quiz.generate_submission(@student)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id }

      expect(response).to be_successful
      expect(assigns[:user]).not_to be_nil
      expect(assigns[:user]).to eql(@student)
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission]).to eql(@submission)
    end

    it "mark read if the student is viewing his own quiz history" do
      user_session(@student)
      @submission = @quiz.generate_submission(@student)
      @submission.submission.mark_unread(@student)
      @submission.save!
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      submission = Quizzes::QuizSubmission.find(@submission.id)
      expect(submission.submission.read?(@student)).to be_truthy
    end

    it "don't mark read if viewing *someone else's* history" do
      user_session(@teacher)
      @submission = @quiz.generate_submission(@student)
      @submission.submission.mark_unread(@teacher)
      @submission.submission.mark_unread(@student)
      @submission.save!
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }
      expect(response).to be_successful
      submission = Quizzes::QuizSubmission.find(@submission.id)
      expect(submission.submission.read?(@teacher)).to be_falsey
      expect(submission.submission.read?(@student)).to be_falsey
    end

    it "finds the observed submissions" do
      @submission = @quiz.generate_submission(@student)
      @observer = user_factory
      @enrollment = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active")
      @enrollment.update_attribute(:associated_user, @student)
      user_session(@observer)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

      expect(response).to be_successful
      expect(assigns[:user]).not_to be_nil
      expect(assigns[:user]).to eql(@student)
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission]).to eql(@submission)
    end

    it "does not allow viewing other submissions if not a teacher" do
      user_session(@student)
      @quiz.generate_submission(@student2)
      @submission = @quiz.generate_submission(@student)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student2.id }
      expect(response).not_to be_successful
    end

    it "allows viewing other submissions if a teacher" do
      user_session(@teacher)
      s = @quiz.generate_submission(@student)
      @submission = @quiz.generate_submission(@teacher)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

      expect(response).to be_successful
      expect(assigns[:user]).not_to be_nil
      expect(assigns[:user]).to eql(@student)
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission]).to eql(s)
    end

    context "when assignment is muted" do
      before do
        @quiz.generate_quiz_data
        @quiz.workflow_state = "available"
        @quiz.published_at = Time.zone.now
        @quiz.save!
        @quiz.assignment.mute!
      end

      it "does not allow student viewing" do
        user_session(@student)

        @quiz.generate_submission(@student2)
        @submission = @quiz.generate_submission(@student)
        get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student2.id }

        expect(response).to be_redirect
        expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
        expect(flash[:notice]).to match(/You cannot view the quiz history while the quiz is muted/)
      end

      it "allows teacher viewing" do
        user_session(@teacher)

        @quiz.generate_submission(@student)
        @submission = @quiz.generate_submission(@teacher)
        get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

        expect(response).to be_successful
      end

      it "allows teacher viewing if the term has ended" do
        @course.enrollment_term.update!(end_at: 1.day.ago)
        user_session(@teacher)

        @quiz.generate_submission(@student)
        get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

        expect(response).to be_successful
      end

      it "allows teacher viewing if the enrollment is concluded" do
        @teacher.enrollments.find_by!(course: @course).conclude
        user_session(@teacher)

        @quiz.generate_submission(@student)
        get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

        expect(response).to be_successful
      end
    end

    it "allows a student to view their own history if the submission is posted" do
      user_session(@student)
      quiz_submission = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(quiz_submission).grade_submission
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }
      expect(response).to be_successful
    end

    it "does not allow a student to view their own history if the submission is not posted" do
      user_session(@student)
      quiz_submission = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(quiz_submission).grade_submission
      quiz_submission.submission.update!(posted_at: nil)
      get "history", params: { course_id: @course.id, quiz_id: @quiz.id, user_id: @student.id }

      aggregate_failures do
        expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
        expect(flash[:notice]).to match(/You cannot view the quiz history while the quiz is muted/)
      end
    end

    context "with non-utf8 submission data" do
      render_views

      before do
        course_quiz(true)

        @question = @quiz.quiz_questions.create!(question_data: {
                                                   "question_text" => "<p>[color]是我最喜欢的颜色</p>",
                                                   "question_type" => "fill_in_multiple_blanks_question",
                                                   "answers" => [{
                                                     "id" => rand(1..999).to_s,
                                                     "text" => "红色",
                                                     "blank_id" => "color"
                                                   }]
                                                 })
        @quiz.generate_quiz_data
        @quiz.save!
      end

      it "renders without error" do
        quiz_submission = @quiz.generate_submission(@student)
        quiz_submission.mark_completed
        quiz_submission.submission_data = [{
          correct: false,
          question_id: @question.id,
          answer_for_color: "\b红色" # the \b causes psych to store this as a binary string
        }]
        quiz_submission.save!

        user_session(@teacher)
        get "history", params: { course_id: @course.id, quiz_id: @quiz.id, quiz_submission_id: quiz_submission.id }
        expect(response).to be_successful
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "does not allow students to create quizzes" do
      user_session(@student)
      post "create", params: { course_id: @course.id, quiz: { title: "some quiz" } }
      assert_unauthorized
    end

    it "creates quiz" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, quiz: { title: "some quiz" } }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz].title).to eql("some quiz")
      expect(response).to be_successful
    end

    it "creates quizzes with overrides" do
      user_session(@teacher)
      section = @course.course_sections.create!
      course_due_date = 3.days.from_now.iso8601
      section_due_date = 5.days.from_now.iso8601
      expect_any_instance_of(Quizzes::Quiz).to receive(:relock_modules!).once

      post "create", params: { course_id: @course.id,
                               quiz: {
                                 title: "overridden quiz",
                                 due_at: course_due_date,
                                 assignment_overrides: [{
                                   course_section_id: section.id,
                                   due_at: section_due_date,
                                 }]
                               } }

      expect(response).to be_successful
      quiz = assigns[:quiz].overridden_for(@teacher)
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz, @teacher)
      expect(overrides.length).to eq 1
      expect(overrides.first[:due_at].iso8601).to eq section_due_date
    end

    it "does not dispatch assignment-created notifications for unpublished quizzes" do
      notification = Notification.create(name: "Assignment Created")
      student_in_course active_all: true
      user_session @teacher
      ag = @course.assignment_groups.create! name: "teh group"
      post "create", params: { course_id: @course.id,
                               quiz: {
                                 title: "some quiz",
                                 quiz_type: "assignment",
                                 assignment_group_id: ag.id
                               } }
      json = response.parsed_body
      quiz = Quizzes::Quiz.find(json["quiz"]["id"])
      expect(quiz).to be_unpublished
      expect(quiz.assignment).to be_unpublished
      expect(@student.recent_stream_items.map { |item| item.data["notification_id"] }).not_to include notification.id
    end

    context "with grading periods" do
      def call_create(params)
        post("create", params: { course_id: @course.id,
                                 quiz: {
                                   title: "Example Quiz", quiz_type: "assignment"
                                 }.merge(params) })
      end

      let(:section_id) { @course.course_sections.first.id }

      before :once do
        teacher_in_course(active_all: true)
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        @course.assignment_groups.create!(name: "Example Assignment Group")
        account_admin_user(account: @course.root_account)
      end

      context "when the user is a teacher" do
        before do
          user_session(@teacher)
        end

        it "allows setting the due date in an open grading period" do
          due_date = 3.days.from_now.iso8601
          call_create(due_at: due_date)
          quiz = @course.quizzes.last
          expect(quiz).to be_present
          expect(quiz.due_at).to eq due_date
        end

        it "does not allow setting the due date in a closed grading period" do
          call_create(due_at: 3.days.ago.iso8601)
          assert_forbidden
          expect(@course.quizzes.count).to be 0
          json = response.parsed_body
          expect(json["errors"].keys).to include "due_at"
        end

        it "allows setting the due date in a closed grading period when only visible to overrides" do
          due_date = 3.days.ago.iso8601
          call_create(due_at: due_date, only_visible_to_overrides: true)
          quiz = @course.quizzes.last
          expect(quiz).to be_present
          expect(quiz.due_at).to eq due_date
        end

        it "does not allow a nil due date when the last grading period is closed" do
          call_create(due_at: nil)
          assert_forbidden
          expect(@course.quizzes.count).to be 0
          json = response.parsed_body
          expect(json["errors"].keys).to include "due_at"
        end

        it "allows a due date in a closed grading period when the quiz is not graded" do
          due_date = 3.days.ago.iso8601
          call_create(due_at: due_date, quiz_type: "survey")
          quiz = @course.quizzes.last
          expect(quiz).to be_present
          expect(quiz.due_at).to eq due_date
        end

        it "allows a nil due date when not graded and the last grading period is closed" do
          call_create(due_at: nil, quiz_type: "survey")
          quiz = @course.quizzes.last
          expect(quiz).to be_present
          expect(quiz.due_at).to be_nil
        end

        it "does not allow setting an override due date in a closed grading period" do
          override_params = [{ due_at: 3.days.ago.iso8601, course_section_id: section_id }]
          call_create(due_at: 7.days.from_now.iso8601, assignment_overrides: override_params)
          assert_forbidden
          expect(@course.quizzes.count).to be 0
          json = response.parsed_body
          expect(json["errors"].keys).to include "due_at"
        end

        it "does not allow a nil override due date when the last grading period is closed" do
          override_params = [{ due_at: nil, course_section_id: section_id }]
          request.content_type = "application/json"
          call_create(due_at: 7.days.from_now.iso8601, assignment_overrides: override_params)
          assert_forbidden
          expect(@course.quizzes.count).to be 0
          json = response.parsed_body
          expect(json["errors"].keys).to include "due_at"
        end
      end

      context "when the user is an admin" do
        before do
          user_session(@admin)
        end

        it "allows setting the due date in a closed grading period" do
          due_date = 3.days.ago.iso8601
          call_create(due_at: due_date)
          expect(@course.quizzes.last.due_at).to eq due_date
        end

        it "allows setting an override due date in a closed grading period" do
          due_date = 3.days.ago.iso8601
          override_params = [{ due_at: due_date, course_section_id: section_id }]
          call_create(due_at: 7.days.from_now.iso8601, assignment_overrides: override_params)
          expect(@course.quizzes.last.assignment_overrides.first.due_at).to eq due_date
        end

        it "allows a nil due date when the last grading period is closed" do
          call_create(due_at: nil)
          expect(@course.quizzes.last.due_at).to be_nil
        end

        it "allows a nil override due date when the last grading period is closed" do
          override_params = [{ due_at: nil, course_section_id: section_id }]
          call_create(due_at: 7.days.from_now.iso8601, assignment_overrides: override_params)
          expect(@course.quizzes.last.assignment_overrides.first.due_at).to be_nil
        end
      end
    end

    it "creates assignment with important dates" do
      user_session(@teacher)
      ag = @course.assignment_groups.create! name: "teh group"
      post "create", params: {
        course_id: @course.id,
        quiz: {
          title: "important dates quiz",
          quiz_type: "assignment",
          assignment_group_id: ag.id
        },
        important_dates: true
      }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz].assignment.important_dates).to be true
      expect(response).to be_successful
    end

    it "sets points_possible to nil for ungraded_surveys" do
      user_session(@teacher)
      post "create", params: {
        course_id: @course.id,
        quiz: {
          title: "ungraded survey",
          quiz_type: "survey"
        }
      }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz].points_possible).to be_nil
      expect(response).to be_successful
    end
  end

  describe "PUT 'update'" do
    it "requires authorization" do
      course_quiz
      put "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "test" } }
      assert_unauthorized
    end

    it "does not allow students to update quizzes" do
      user_session(@student)
      course_quiz
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "some quiz" } }
      assert_unauthorized
    end

    it "updates quizzes" do
      user_session(@teacher)
      course_quiz
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "some quiz" } }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:quiz].title).to eql("some quiz")
    end

    it "locks if asked to" do
      user_session(@teacher)
      course_quiz
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { locked: "true" } }
      expect(@quiz.reload.locked?).to be(true)
    end

    it "publishes if asked to" do
      user_session(@teacher)
      course_quiz
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "some quiz" }, publish: "true" }
      expect(@quiz.reload.published).to be(true)
    end

    it "does not publish if not asked to" do
      user_session(@teacher)
      course_quiz
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "some quiz" } }
      expect(@quiz.reload.published).to be(false)
    end

    context "post_to_sis" do
      before { @course.enable_feature!(:post_grades) }

      it "sets post_to_sis quizzes" do
        user_session(@teacher)
        course_quiz
        post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "some quiz" }, post_to_sis: "1" }
        expect(assigns[:quiz].assignment.post_to_sis).to be true
      end

      it "doesn't blow up for surveys" do
        user_session(@teacher)
        survey = @course.quizzes.create! quiz_type: "survey", title: "survey"
        post "update", params: { course_id: @course.id, id: survey.id, quiz: { title: "changed" }, post_to_sis: "1" }
        expect(assigns[:quiz].title).to eq "changed"
      end

      context "with required due dates" do
        before do
          @course.account.enable_feature!(:new_sis_integrations)
          @course.account.settings = { sis_syncing: { value: true }, sis_require_assignment_due_date: { value: true } }
          @course.account.save!

          user_session(@teacher)
          course_quiz
        end

        it "saves with a due date" do
          post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "updated", due_at: 2.days.from_now.iso8601 }, post_to_sis: "1" }
          expect(response).to be_redirect
          expect(flash[:error]).to be_nil
          expect(@quiz.reload.title).to eq "updated"
        end

        it "fails to save without a due date" do
          post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { title: "updated" }, post_to_sis: "1" }
          expect(response).to be_redirect
          expect(flash[:error]).to match(/failed to update/)
          expect(@quiz.reload.title).not_to eq "updated"
        end

        context "with overrides" do
          before do
            @section = @course.course_sections.create
          end

          it "saves with a due date" do
            post "update", params: {
              course_id: @course.id,
              id: @quiz.id,
              quiz: {
                title: "overrides",
                assignment_overrides: [{
                  course_section_id: @section.id,
                  due_at: 2.days.from_now.iso8601
                }]
              },
              post_to_sis: "1"
            }
            expect(response).to be_redirect
            expect(flash[:error]).to be_nil
            expect(@quiz.reload.title).to eq "overrides"
          end

          it "fails to save without a due date" do
            post "update", params: {
              course_id: @course.id,
              id: @quiz.id,
              quiz: {
                title: "overrides",
                assignment_overrides: [{
                  course_section_id: @section.id,
                  due_at: nil
                }]
              },
              post_to_sis: "1"
            }
            expect(response).to be_redirect
            expect(flash[:error]).to match(/failed to update/)
            expect(@quiz.reload.title).not_to eq "overrides"
          end

          it "saves important dates" do
            post "update", params: {
              course_id: @course.id,
              id: @quiz.id,
              important_dates: true
            }
            expect(response).to be_redirect
            expect(flash[:error]).to be_nil
            expect(@quiz.reload.assignment.important_dates).to be true
          end
        end
      end
    end

    it "is able to change ungraded survey to quiz without error" do
      # aka should handle the case where the quiz's assignment is nil/not present.
      user_session(@teacher)
      course_quiz
      @quiz.update(quiz_type: "survey")
      # make sure the assignment doesn't exist
      @quiz.assignment = nil
      expect(@quiz.assignment).not_to be_present
      @quiz.publish!

      post "update", params: { course_id: @course.id,
                               id: @quiz.id,
                               activate: true,
                               quiz: { quiz_type: "assignment" } }
      expect(response).to be_redirect

      expect(@quiz.reload.quiz_type).to eq "assignment"
      expect(@quiz).to be_available
      expect(@quiz.assignment).to be_present
    end

    it "locks and unlock without removing assignment" do
      user_session(@teacher)
      a = @course.assignments.create!(title: "some assignment", points_possible: 5)
      expect(a.points_possible).to be(5.0)
      expect(a.submission_types).not_to eql("online_quiz")
      @quiz = @course.quizzes.build(assignment_id: a.id, title: "some quiz", points_possible: 10)
      @quiz.workflow_state = "available"
      @quiz.save
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { "locked" => "true" } }
      @quiz.reload
      expect(@quiz.assignment).not_to be_nil
      post "update", params: { course_id: @course.id, id: @quiz.id, quiz: { "locked" => "false" } }
      @quiz.reload
      expect(@quiz.assignment).not_to be_nil
    end

    it "updates overrides for a quiz" do
      user_session(@teacher)
      quiz = @course.quizzes.build(title: "Update Overrides Quiz")
      quiz.save!
      section = @course.course_sections.build
      section.save!
      course_due_date = 3.days.from_now.iso8601
      section_due_date = 5.days.from_now.iso8601
      quiz.save!
      post "update", params: { course_id: @course.id,
                               id: quiz.id,
                               quiz: {
                                 title: "overridden quiz",
                                 due_at: course_due_date,
                                 assignment_overrides: [{
                                   course_section_id: section.id,
                                   due_at: section_due_date,
                                   due_at_overridden: true
                                 }]
                               } }
      quiz = quiz.reload.overridden_for(@teacher)
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz, @teacher)
      expect(overrides.length).to eq 1
    end

    it "can change a graded quiz with overrides into an ungraded quiz" do
      user_session(@teacher)
      quiz = @course.quizzes.create!(title: "blah", quiz_type: "assignment")
      override = create_adhoc_override_for_assignment(quiz, @student)
      post "update", params: {
        course_id: @course.id,
        id: quiz.id,
        quiz: {
          quiz_type: "survey",
          assignment_overrides: [{
            id: override.id,
            assignment_id: quiz.assignment.id,
            title: "1 student",
            student_ids: [@student.id]
          }]
        }
      }
      expect(quiz.reload.assignment_id).to be_nil
      expect(override.reload.assignment_id).to be_nil
      expect(override.quiz_id).to eq quiz.id
    end

    it "removes points_possible when changing from a graded quiz to ungraded" do
      user_session(@teacher)
      quiz_with_submission(false, true)
      expect(@quiz.current_points_possible).to be > 0
      post "update", params: {
        course_id: @course.id,
        id: @quiz.id,
        quiz: {
          quiz_type: "survey"
        }
      }
      expect(@quiz.reload.points_possible).to be_nil
    end

    it "does not remove attributes when called with no description param" do
      user_session(@teacher)
      quiz = @course.quizzes.create!(title: "blah", quiz_type: "assignment", description: "foobar")
      post "update", params: {
        course_id: @course.id,
        id: quiz.id,
      }
      expect(quiz.reload.title).to eq "blah"
      expect(quiz.reload.description).to eq "foobar"
    end

    describe "SubmissionLifecycleManager" do
      before do
        user_session(@teacher)
        @quiz = @course.quizzes.build(title: "Update Overrides Quiz", workflow_state: "edited")
        @quiz.save!
        section = @course.course_sections.build
        section.save!
        course_due_date = 3.days.from_now.iso8601
        section_due_date = 5.days.from_now.iso8601
        @quiz.save!

        @quiz_only = {
          course_id: @course.id,
          id: @quiz.id,
          quiz: {
            title: "overridden quiz",
            due_at: course_due_date,
            assignment_overrides: [
              {
                course_section_id: section.id,
                due_at: section_due_date,
                due_at_overridden: true
              }
            ]
          }
        }

        @overrides_only = {
          course_id: @course.id,
          id: @quiz.id,
          quiz: {
            assignment_overrides: [
              {
                course_section_id: section.id,
                due_at: section_due_date,
                due_at_overridden: true
              }
            ]
          }
        }

        @quiz_and_overrides = {
          course_id: @course.id,
          id: @quiz.id,
          quiz: {
            assignment_overrides: [
              {
                course_section_id: section.id,
                due_at: section_due_date,
                due_at_overridden: true
              }
            ]
          }
        }

        @no_changes = {
          course_id: @course.id,
          id: @quiz.id,
          quiz: {
            assignment_overrides: []
          }
        }
      end

      it "runs SubmissionLifecycleManager only once when overrides are updated" do
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).to receive(:recompute).once

        post "update", params: @overrides_only
      end

      it "runs SubmissionLifecycleManager only once when quiz due date is updated" do
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).to receive(:recompute).once

        post "update", params: @quiz_only
      end

      it "runs SubmissionLifecycleManager only once when quiz due date and overrides are updated" do
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).to receive(:recompute).once

        post "update", params: @quiz_and_overrides
      end

      it "runs SubmissionLifecycleManager when transitioning a 'created' quiz to 'edited'" do
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).to receive(:recompute).once

        @quiz.update_attribute(:workflow_state, "created")
        post "update", params: @no_changes
        expect(@quiz.reload).to be_edited
      end

      it "runs SubmissionLifecycleManager when transitioning from ungraded quiz to graded" do
        @quiz.update!(quiz_type: "practice_quiz")
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).to receive(:recompute).once

        post "update", params: {
          course_id: @course.id,
          id: @quiz.id,
          quiz: {
            quiz_type: "assignment"
          }
        }
      end

      it "does not runs SubmissionLifecycleManager when nothing is updated" do
        submission_lifecycle_manager = instance_double(SubmissionLifecycleManager)
        allow(SubmissionLifecycleManager).to receive(:new).and_return(submission_lifecycle_manager)

        expect(submission_lifecycle_manager).not_to receive(:recompute)

        post "update", params: @no_changes
      end
    end

    it "deletes overrides for a quiz if assignment_overrides params is 'false'" do
      user_session(@teacher)
      quiz = @course.quizzes.build(title: "Delete overrides!")
      quiz.save!
      section = @course.course_sections.create!(name: "VDD Course Section")
      override = AssignmentOverride.new
      override.set_type = "CourseSection"
      override.set = section
      override.due_at = Time.zone.now
      override.quiz = quiz
      override.save!
      course_due_date = 3.days.from_now.iso8601
      post "update", params: { course_id: @course.id,
                               id: quiz.id,
                               quiz: {
                                 title: "overridden quiz",
                                 due_at: course_due_date,
                                 assignment_overrides: "false"
                               } }
      expect(quiz.reload.assignment_overrides.active).to be_empty
    end

    it "updates the quiz with the correct times for fancy midnight" do
      time = Time.local(2013, 3, 13, 0, 0).in_time_zone
      user_session(@teacher)
      quiz = @course.quizzes.build(title: "Test that fancy midnight, baby!")
      quiz.save!
      post :update, params: { course_id: @course.id,
                              id: quiz.id,
                              quiz: {
                                due_at: time,
                                lock_at: time,
                                unlock_at: time
                              } }
      quiz.reload
      expect(quiz.due_at.to_i).to eq CanvasTime.fancy_midnight(time).to_i
      expect(quiz.lock_at.to_i).to eq CanvasTime.fancy_midnight(time).to_i
      expect(quiz.unlock_at.to_i).to eq time.to_i
    end

    it "accepts a hash value for 'hide_results'" do
      user_session(@teacher)
      quiz = @course.quizzes.create!(title: "jamesw is the worst q_q")
      post :update, params: { course_id: @course.id,
                              id: quiz.id,
                              quiz: {
                                hide_results: { never: "0" }
                              } }
      quiz.reload
      expect(quiz.hide_results).to eq "always"
    end

    context "notifications" do
      before :once do
        @notification = Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")

        @section = @course.course_sections.create!

        communication_channel(@student, { username: "student@instructure.com", active_cc: true })

        course_quiz
        @quiz.generate_quiz_data
        @quiz.workflow_state = "available"
        @quiz.published_at = Time.now
        @quiz.save!

        @quiz.update_attribute(:created_at, 1.day.ago)
        @quiz.assignment.update_attribute(:created_at, 1.day.ago)
      end

      before do
        user_session(@teacher)
      end

      it "sends due date changed if notify_of_update is set" do
        course_due_date = 2.days.from_now
        section_due_date = 3.days.from_now
        post "update", params: { course_id: @course.id,
                                 id: @quiz.id,
                                 quiz: {
                                   title: "overridden quiz",
                                   due_at: course_due_date.iso8601,
                                   assignment_overrides: [{
                                     course_section_id: @section.id,
                                     due_at: section_due_date.iso8601,
                                     due_at_overridden: true
                                   }],
                                   notify_of_update: true
                                 } }
        expect(@student.messages.detect { |m| m.notification_id == @notification.id }).not_to be_nil
      end

      it "sends due date changed if notify_of_update is not set" do
        course_due_date = 2.days.from_now
        section_due_date = 3.days.from_now
        post "update", params: { course_id: @course.id,
                                 id: @quiz.id,
                                 quiz: {
                                   title: "overridden quiz",
                                   due_at: course_due_date.iso8601,
                                   assignment_overrides: [{
                                     course_section_id: @section.id,
                                     due_at: section_due_date.iso8601,
                                     due_at_overridden: true
                                   }]
                                 } }

        expect(@student.messages.detect { |m| m.notification_id == @notification.id }).not_to be_nil
      end
    end

    context "with grading periods" do
      def create_quiz(attr)
        @course.quizzes.create!({ title: "Example Quiz", quiz_type: "assignment" }.merge(attr))
      end

      def override_for_date(date)
        override = @quiz.assignment_overrides.build
        override.set_type = "CourseSection"
        override.due_at = date
        override.due_at_overridden = true
        override.set_id = @course.course_sections.first
        override.save!
        override
      end

      def call_update(params)
        post("update", params: { course_id: @course.id, id: @quiz.id, quiz: params })
      end

      let(:section_id) { @course.course_sections.first.id }

      before :once do
        teacher_in_course(active_all: true)
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(grading_period_group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        account_admin_user(account: @course.root_account)
      end

      context "when the user is a teacher" do
        before do
          user_session(@teacher)
        end

        it "allows changing the due date to another date in an open grading period" do
          due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows changing the due date when the quiz is only visible to overrides" do
          due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows disabling only_visible_to_overrides when due in an open grading period" do
          @quiz = create_quiz(due_at: 3.days.from_now, only_visible_to_overrides: true)
          call_update(only_visible_to_overrides: false)
          expect(@quiz.reload.only_visible_to_overrides).to be false
        end

        it "allows enabling only_visible_to_overrides when due in an open grading period" do
          @quiz = create_quiz(due_at: 3.days.from_now, only_visible_to_overrides: false)
          call_update(only_visible_to_overrides: true)
          expect(@quiz.reload.only_visible_to_overrides).to be true
        end

        it "does not allow disabling only_visible_to_overrides when due in a closed grading period" do
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update(only_visible_to_overrides: false)
          expect(@quiz.reload.only_visible_to_overrides).to be true
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow enabling only_visible_to_overrides when due in a closed grading period" do
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: false)
          call_update(only_visible_to_overrides: true)
          expect(@quiz.reload.only_visible_to_overrides).to be false
          expect(response).to be_redirect
          expect(flash[:error]).to match(/only visible to overrides/)
        end

        it "allows disabling only_visible_to_overrides when changing due date to an open grading period" do
          due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update(due_at: due_date, only_visible_to_overrides: false)
          expect(@quiz.reload.only_visible_to_overrides).to be false
          expect(@quiz.due_at).to eq due_date
        end

        it "does not allow changing the due date on a quiz due in a closed grading period" do
          due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: due_date)
          call_update(due_at: 3.days.from_now)
          expect(@quiz.reload.due_at).to eq due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow changing the due date to a date within a closed grading period" do
          due_date = 3.days.from_now
          @quiz = create_quiz(due_at: due_date)
          call_update(due_at: 3.days.ago.iso8601)
          expect(@quiz.reload.due_at).to eq due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow unsetting the due date when the last grading period is closed" do
          due_date = 3.days.from_now
          @quiz = create_quiz(due_at: due_date)
          call_update(due_at: nil)
          expect(@quiz.reload.due_at).to eq due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "succeeds when the due date is set to the same value" do
          due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: due_date)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "succeeds when the due date is not changed" do
          due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: due_date)
          call_update(title: "Updated Quiz")
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows changing the due date when the quiz is not graded" do
          due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now, quiz_type: "survey")
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows unsetting the due date when not graded and the last grading period is closed" do
          @quiz = create_quiz(due_at: 3.days.from_now, quiz_type: "survey")
          call_update(due_at: nil)
          expect(@quiz.reload.due_at).to be_nil
        end

        it "allows changing the due date on a quiz with an override due in a closed grading period" do
          due_date = 7.days.from_now.iso8601
          @quiz = create_quiz(due_at: 3.days.from_now)
          override_for_date(3.days.ago)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows adding an override with a due date in an open grading period" do
          # Known Issue: This should not be permitted when creating an override
          # would cause a student to assume a due date in an open grading period
          # when previous in a closed grading period.
          override_due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 3.days.from_now, only_visible_to_overrides: true)
          override_params = [{ student_ids: [@student.id], due_at: override_due_date }]
          call_update(assignment_overrides: override_params)
          overrides = @quiz.reload.assignment_overrides
          expect(overrides.count).to eq 1
          expect(overrides.first.due_at).to eq override_due_date
        end

        it "does not allow adding an override with a due date in a closed grading period" do
          @quiz = create_quiz(due_at: 7.days.from_now)
          override_params = [{ due_at: 3.days.ago.iso8601 }]
          call_update(assignment_overrides: override_params)
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow changing the due date of an override due in a closed grading period" do
          override_due_date = 3.days.ago
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: 3.days.from_now.iso8601 }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "succeeds when the override due date is set to the same value" do
          override_due_date = 3.days.ago
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: override_due_date.iso8601 }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date.iso8601
        end

        it "does not allow changing the due date of an override to a date within a closed grading period" do
          override_due_date = 3.days.from_now
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: 3.days.ago.iso8601 }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow unsetting the due date of an override when the last grading period is closed" do
          override_due_date = 3.days.from_now
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(override_due_date)
          override_params = [{ id: override.id, due_at: nil }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end

        it "does not allow deleting by omission an override due in a closed grading period" do
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ due_at: 3.days.from_now.iso8601, course_section_id: section_id }]
          call_update(assignment_overrides: override_params)
          expect(override.reload).not_to be_deleted
          expect(response).to be_redirect
          expect(flash[:error]).to match(/due date/)
        end
      end

      context "when the user is an admin" do
        before do
          user_session(@admin)
        end

        it "does not allow disabling only_visible_to_overrides when due in a closed grading period" do
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: true)
          call_update(only_visible_to_overrides: false)
          expect(@quiz.reload.only_visible_to_overrides).to be false
        end

        it "does not allow enabling only_visible_to_overrides when due in a closed grading period" do
          @quiz = create_quiz(due_at: 3.days.ago, only_visible_to_overrides: false)
          call_update(only_visible_to_overrides: true)
          expect(@quiz.reload.only_visible_to_overrides).to be true
        end

        it "allows changing the due date on a quiz due in a closed grading period" do
          due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 3.days.ago)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows changing the due date to a date within a closed grading period" do
          due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: 3.days.from_now)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows unsetting the due date when the last grading period is closed" do
          @quiz = create_quiz(due_at: 3.days.from_now)
          call_update(due_at: nil)
          expect(@quiz.reload.due_at).to be_nil
        end

        it "allows changing the due date on a quiz with an override due in a closed grading period" do
          due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now)
          override_for_date(3.days.ago)
          call_update(due_at: due_date)
          expect(@quiz.reload.due_at).to eq due_date
        end

        it "allows adding an override with a due date in a closed grading period" do
          override_due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now, only_visible_to_overrides: true)
          override_params = [{ student_ids: [@student.id], due_at: override_due_date }]
          call_update(assignment_overrides: override_params)
          overrides = @quiz.reload.assignment_overrides
          expect(overrides.count).to eq 1
          expect(overrides.first.due_at).to eq override_due_date
        end

        it "allows changing the due date of an override due in a closed grading period" do
          override_due_date = 3.days.from_now.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ id: override.id, due_at: override_due_date }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date
        end

        it "allows changing the due date of an override to a date within a closed grading period" do
          override_due_date = 3.days.ago.iso8601
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(3.days.from_now)
          override_params = [{ id: override.id, due_at: override_due_date }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to eq override_due_date
        end

        it "allows unsetting the due date of an override when the last grading period is closed" do
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(3.days.from_now)
          override_params = [{ id: override.id, due_at: nil }]
          call_update(assignment_overrides: override_params)
          expect(override.reload.due_at).to be_nil
        end

        it "allows deleting by omission an override due in a closed grading period" do
          @quiz = create_quiz(due_at: 7.days.from_now)
          override = override_for_date(3.days.ago)
          override_params = [{ due_at: 3.days.from_now.iso8601, course_section_id: section_id }]
          call_update(assignment_overrides: override_params)
          expect(override.reload).to be_deleted
        end
      end
    end
  end

  describe "GET 'statistics'" do
    it "allows concluded teachers to see a quiz's statistics" do
      user_session(@teacher)
      course_quiz
      @enrollment.conclude
      get "statistics", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response).to render_template("statistics_cqs")
    end

    context "logged out submissions" do
      render_views

      it "includes logged_out users' submissions in a public course" do
        # logged_out user
        user = temporary_user_code

        # make questions
        questions = [{ question_data: { name: "test 1" } },
                     { question_data: { name: "test 2" } },
                     { question_data: { name: "test 3" } },
                     { question_data: { name: "test 4" } }]

        logged_out_survey_with_submission user, questions

        # non logged_out submissions
        @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @quiz_submission1 = @quiz.generate_submission(@user1)
        Quizzes::SubmissionGrader.new(@quiz_submission1).grade_submission

        @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
        @quiz_submission2 = @quiz.generate_submission(@user2)
        Quizzes::SubmissionGrader.new(@quiz_submission2).grade_submission

        @course.large_roster = false
        @course.save!

        get "statistics", params: { course_id: @course.id, quiz_id: @quiz.id, all_versions: "1" }
        expect(response).to be_successful
        expect(response).to render_template("statistics_cqs")
      end
    end

    it "shows the statistics page if the course is a MOOC" do
      user_session(@teacher)
      @course.large_roster = true
      @course.save!
      course_quiz
      get "statistics", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response).to render_template("statistics_cqs")
    end
  end

  describe "GET 'read_only'" do
    before(:once) { course_quiz }

    it "allows concluded teachers to see a read-only view of a quiz" do
      user_session(@teacher)
      get "read_only", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response).to render_template("read_only")

      @enrollment.conclude
      controller.js_env.clear
      get "read_only", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response).to render_template("read_only")
    end

    it "does not allow students to see a read-only view of a quiz" do
      user_session(@student)
      get "read_only", params: { course_id: @course.id, quiz_id: @quiz.id }
      assert_unauthorized

      @enrollment.conclude
      get "read_only", params: { course_id: @course.id, quiz_id: @quiz.id }
      assert_unauthorized
    end

    it "includes banks hash" do
      user_session(@teacher)
      get "read_only", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(assigns[:banks_hash]).not_to be_nil
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { course_quiz }

    it "requires authorization" do
      delete "destroy", params: { course_id: @course.id, id: @quiz.id }
      assert_unauthorized
    end

    it "does not allow students to delete quizzes" do
      user_session(@student)
      delete "destroy", params: { course_id: @course.id, id: @quiz.id }
      assert_unauthorized
    end

    it "deletes quizzes" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: @quiz.id }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:quiz]).to be_deleted
    end
  end

  describe "POST 'publish'" do
    it "requires authorization" do
      course_quiz
      post "publish", params: { course_id: @course.id, quizzes: [@quiz.id] }
      assert_unauthorized
    end

    it "publishes unpublished quizzes" do
      user_session(@teacher)
      @quiz = @course.quizzes.build(title: "New quiz!")
      @quiz.save!

      expect(@quiz.published?).to be_falsey
      post "publish", params: { course_id: @course.id, quizzes: [@quiz.id] }

      expect(@quiz.reload.published?).to be_truthy
    end
  end

  describe "GET 'submission_html'" do
    before(:once) { course_quiz(true) }

    before { user_session(@teacher) }

    it "renders nothing if there's no submission for current user" do
      get "submission_html", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response.body.strip).to be_empty
    end

    it "renders submission html if there is a submission" do
      sub = @quiz.generate_submission(@teacher)
      sub.mark_completed
      sub.save!
      get "submission_html", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response).to render_template("quizzes/submission_html")
    end
  end

  describe "GET 'submission_html' (as a student)" do
    before do
      user_session(@student)
      course_quiz(true)
    end

    it "locks results if there is a submission and one_time_results is on" do
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      submission = @quiz.generate_submission(@student)
      submission.mark_completed
      submission.save!

      get "submission_html", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful

      expect(response).to render_template("quizzes/submission_html")
      expect(submission.reload.has_seen_results).to be true
    end
  end

  describe "POST 'unpublish'" do
    it "requires authorization" do
      course_quiz
      post "unpublish", params: { course_id: @course.id, quizzes: [@quiz.id] }
      assert_unauthorized
    end

    it "unpublishes published quizzes" do
      user_session(@teacher)
      @quiz = @course.quizzes.build(title: "New quiz!")
      @quiz.publish!

      expect(@quiz.published?).to be_truthy
      post "unpublish", params: { course_id: @course.id, quizzes: [@quiz.id] }

      expect(@quiz.reload.published?).to be_falsey
    end
  end

  describe "GET submission_versions" do
    before(:once) { course_quiz }

    it "requires authorization" do
      get "submission_versions", params: { course_id: @course.id, quiz_id: @quiz.id }
      assert_unauthorized
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
    end

    it "assigns variables" do
      user_session(@teacher)
      submission = @quiz.generate_submission @teacher
      create_attachment_for_file_upload_submission!(submission)
      get "submission_versions", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(assigns[:quiz]).not_to be_nil
      expect(assigns[:quiz]).to eql(@quiz)
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:versions]).not_to be_nil
    end

    it "renders nothing if quiz is muted" do
      user_session(@teacher)

      @quiz.generate_submission @teacher

      assignment = @course.assignments.create(title: "Test Assignment")
      assignment.workflow_state = "available"
      assignment.submission_types = "online_quiz"
      assignment.muted = true
      assignment.save!
      @quiz.assignment = assignment

      get "submission_versions", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response).to be_successful
      expect(response.body).to match(/^\s?$/)
    end

    it "renders nothing when the submission is not posted" do
      assignment = @course.assignments.create!(
        title: "my humdrum quiz",
        workflow_state: "available",
        submission_types: "online_quiz"
      )

      @quiz.assignment = assignment
      user_session(@teacher)

      assignment.post_policy.update!(post_manually: true)
      @quiz.generate_submission(@teacher)

      get "submission_versions", params: { course_id: @course.id, quiz_id: @quiz.id }
      expect(response.body).to match(/^\s?$/)
    end
  end

  describe "differentiated assignments" do
    before do
      course_with_teacher(active_all: true)
      @student1, @student2 = n_students_in_course(2, active_all: true, course: @course)
      @course_section = @course.course_sections.create!
      course_quiz(true)
      @quiz.only_visible_to_overrides = true
      @quiz.save!
      student_in_section(@course_section, user: @student1)
      create_section_override_for_quiz(@quiz, course_section: @course_section)
    end

    context "index" do
      it "shows the quiz to students with visibility" do
        user_session(@student1)
        get "index", params: { course_id: @course.id }
        expect(controller.js_env[:QUIZZES][:assignment].count).to eq 1
      end

      it "hides the quiz to students with visibility" do
        user_session(@student2)
        get "index", params: { course_id: @course.id }
        expect(controller.js_env[:QUIZZES][:assignment]).to eq []
      end
    end

    context "show" do
      it "shows the page to students with visibility" do
        user_session(@student1)
        get "show", params: { course_id: @course.id, id: @quiz.id }
        expect(response).not_to be_redirect
      end

      it "redirect for students without visibility or a submission" do
        user_session(@student2)
        get "show", params: { course_id: @course.id, id: @quiz.id }
        expect(response).to be_redirect
        expect(flash[:error]).to match(/You do not have access to the requested quiz/)
      end

      it "shows a message to students without visibility with a submission" do
        Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student2)
        user_session(@student2)
        get "show", params: { course_id: @course.id, id: @quiz.id }
        expect(response).not_to be_redirect
        expect(flash[:notice]).to match(/This quiz will no longer count towards your grade/)
      end
    end
  end

  describe "#can_take_quiz?" do
    # These specs are test-after, and highly coupled to the existing
    # implementation of the #can_take_quiz method, which is deeply entangled.
    # When possible I recommend extracting this into a PORO or Quizzes::Quiz.

    before do
      course_with_teacher
      course_quiz(true)
      @quiz.save!
      allow(@quiz).to receive(:grants_right?) do |_user, sess, rights|
        if rights.nil?
          rights = sess
        end
        next true if rights == :submit

        false
      end
      subject.instance_variable_set(:@quiz, @quiz)
      allow(@quiz).to receive_messages(require_lockdown_browser?: false, ip_filter: false)
      subject.instance_variable_set(:@course, @course)
      subject.instance_variable_set(:@current_user, @student)
    end

    let(:return_value) { subject.send :can_take_quiz? }

    it "returns false when locked" do
      allow(@quiz).to receive(:locked_for?).and_return(true)
      expect(return_value).to be false
    end

    it "returns false when unauthorized" do
      allow(@quiz).to receive(:grants_right?).and_return(false)
      expect(return_value).to be false
    end

    it "is false with wrong access code" do
      allow(@quiz).to receive(:access_code).and_return("trust me. *winks*")
      allow(subject).to receive(:params).and_return({
                                                      access_code: "Don't trust me. *tips hat*",
                                                      take: 1
                                                    })
      expect(return_value).to be false
    end

    it "false with wrong IP address" do
      allow(@quiz).to receive_messages(ip_filter: true, valid_ip?: false)
      allow(subject).to receive(:params).and_return({ take: 1 })
      expect(return_value).to be false
    end
  end
end
