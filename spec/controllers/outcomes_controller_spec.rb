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

describe OutcomesController do
  def context_outcome(context)
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(title: "outcome")
    @outcome_group.add_outcome(@outcome)
  end

  def course_outcome
    context_outcome(@course)
  end

  def account_outcome
    context_outcome(@account)
  end

  def create_learning_outcome_result(user, score, assignment, alignment, rubric_association, submitted_at)
    title = "#{user.name}, #{assignment.name}"
    possible = @outcome.points_possible
    mastery = (score || 0) >= @outcome.mastery_points

    LearningOutcomeResult.create!(
      learning_outcome: @outcome,
      user:,
      context: @course,
      alignment:,
      associated_asset: assignment,
      association_type: "RubricAssociation",
      association_id: rubric_association.id,
      title:,
      score:,
      possible:,
      mastery:,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at:,
      assessed_at: submitted_at
    )
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @account = Account.default
    account_admin_user
  end

  describe "GET 'index'" do
    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 15, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "works in accounts" do
      user_session(@admin)
      account_outcome
      get "index", params: { account_id: @account.id }
    end

    it "does not find a common core group from settings" do
      user_session(@admin)
      account_outcome
      allow(Shard.current).to receive(:settings).and_return({ common_core_outcome_group_id: @outcome_group.id })
      get "index", params: { account_id: @account.id }
      expect(assigns[:js_env]).not_to have_key(:COMMON_CORE_GROUP_ID)
    end

    it "passes along permissions" do
      user_session(@admin)
      get "index", params: { account_id: @account.id }
      permissions = assigns[:js_env][:PERMISSIONS]
      %i[
        manage_outcomes
        manage_rubrics
        can_manage_courses
        import_outcomes
        manage_proficiency_scales
        manage_proficiency_calculations
      ].each do |permission|
        expect(permissions).to have_key(permission)
      end
    end

    context "account_level_mastery_scales feature flag enabled" do
      before(:once) do
        @account.root_account.enable_feature! :account_level_mastery_scales
      end

      it "includes proficiency roles" do
        user_session(@admin)
        get "index", params: { account_id: @account.id }

        %i[PROFICIENCY_CALCULATION_METHOD_ENABLED_ROLES PROFICIENCY_SCALES_ENABLED_ROLES].each do |key|
          roles = controller.js_env[key]
          expect(roles.length).to eq 1
          expect(roles.dig(0, :role)).to eq "AccountAdmin"
        end
      end
    end

    context "global_root_outcome_id" do
      it "returns the global root group id for an account" do
        global_id = LearningOutcomeGroup.global_root_outcome_group.id
        user_session(@admin)
        get "index", params: { account_id: @account.id }
        expect(assigns[:js_env][:GLOBAL_ROOT_OUTCOME_GROUP_ID]).to eq global_id
      end

      it "does not return the global root id for a course" do
        user_session(@admin)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:GLOBAL_ROOT_OUTCOME_GROUP_ID]).to be_nil
      end
    end

    context "outcomes_friendly_description" do
      it "returns true if outcomes_friendly_description feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_friendly_description)
        user_session(@admin)
        get "index", params: { account_id: @account.id }
        expect(assigns[:js_env][:OUTCOMES_FRIENDLY_DESCRIPTION]).to be true
      end

      it "returns false if outcomes_friendly_description feature flag is disabled" do
        Account.site_admin.disable_feature!(:outcomes_friendly_description)
        user_session(@admin)
        get "index", params: { account_id: @account.id }
        expect(assigns[:js_env][:OUTCOMES_FRIENDLY_DESCRIPTION]).to be false
      end
    end

    context "archive_outcomes" do
      it "returns true if archive_outcomes feature flag is enabled" do
        Account.site_admin.enable_feature!(:archive_outcomes)
        user_session(@admin)
        get "index", params: { account_id: @account.id }
        expect(assigns[:js_env][:ARCHIVE_OUTCOMES]).to be true
      end

      it "returns false if archive_outcomes feature flag is disabled" do
        Account.site_admin.disable_feature!(:archive_outcomes)
        user_session(@admin)
        get "index", params: { account_id: @account.id }
        expect(assigns[:js_env][:ARCHIVE_OUTCOMES]).to be false
      end
    end
  end

  context "outcome_average_calculation" do
    it "returns true if outcome_average_calculation feature flag is enabled" do
      @account.root_account.enable_feature!(:outcome_average_calculation)
      user_session(@admin)
      get "index", params: { account_id: @account.id }
      expect(assigns[:js_env][:OUTCOME_AVERAGE_CALCULATION]).to be true
    end

    it "returns false if outcome_average_calculation feature flag is disabled" do
      @account.root_account.disable_feature!(:outcome_average_calculation)
      user_session(@admin)
      get "index", params: { account_id: @account.id }
      expect(assigns[:js_env][:OUTCOME_AVERAGE_CALCULATION]).to be false
    end
  end

  context "menu_option_for_outcome_details_page" do
    it "returns true if menu_option_for_outcome_details_page feature flage is enabled" do
      Account.site_admin.enable_feature!(:menu_option_for_outcome_details_page)
      user_session(@admin)
      get "index", params: { account_id: @account.id }
      expect(assigns[:js_env][:MENU_OPTION_FOR_OUTCOME_DETAILS_PAGE]).to be true
    end

    it "returns false if menu_option_for_outcome_details_page feature flage is disabled" do
      Account.site_admin.disable_feature!(:menu_option_for_outcome_details_page)
      user_session(@admin)
      get "index", params: { account_id: @account.id }
      expect(assigns[:js_env][:MENU_OPTION_FOR_OUTCOME_DETAILS_PAGE]).to be false
    end
  end

  describe "GET 'show'" do
    it "requires authorization" do
      course_outcome
      get "show", params: { course_id: @course.id, id: @outcome.id }
      assert_unauthorized
    end

    it "does not allow students to view outcomes" do
      user_session(@student)
      course_outcome
      get "show", params: { course_id: @course.id, id: @outcome.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@teacher)
      course_outcome
      get "show", params: { course_id: @course.id, id: @outcome.id }
      expect(response).to be_successful
    end

    it "works in accounts" do
      user_session(@admin)
      account_outcome
      get "show", params: { account_id: @account.id, id: @outcome.id }
      expect(response).to be_successful
    end

    it "includes tags from courses when viewed in the account" do
      account_outcome

      quiz = @course.quizzes.create!
      alignment = @outcome.align(quiz, @course)

      user_session(@admin)
      get "show", params: { account_id: @account.id, id: @outcome.id }

      expect(assigns[:alignments].any? { |a| a.id == alignment.id }).to be_truthy
    end

    it "does not allow access to individual outcomes for large_roster courses" do
      course_outcome

      @course.large_roster = true
      @course.save!

      get "show", params: { course_id: @course.id, id: @outcome.id }
      expect(response).to be_redirect
    end
  end

  describe "GET 'details'" do
    it "requires authorization" do
      course_outcome
      get "details", params: { course_id: @course.id, outcome_id: @outcome.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@student)
      course_outcome
      get "details", params: { course_id: @course.id, outcome_id: @outcome.id }
      expect(response).to be_successful
    end

    it "works in accounts" do
      user_session(@admin)
      account_outcome
      get "details", params: { account_id: @account.id, outcome_id: @outcome.id }
    end
  end

  describe "GET 'user_outcome_results'" do
    it "requires authorization" do
      account_outcome
      get "user_outcome_results", params: { account_id: @account.id, user_id: @student.id }
      assert_unauthorized
    end

    it "returns outcomes for the given user" do
      account_outcome
      user_session(@admin)
      get "user_outcome_results", params: { account_id: @account.id, user_id: @student.id }
      expect(response).to be_successful
      expect(response).to render_template("user_outcome_results")
    end

    it "lastest score" do
      course_outcome
      user_session(@admin)
      create_outcome
      rubric = outcome_with_rubric context: @course, outcome: @outcome

      assignment1 = @course.assignments.create!(title: "Assignment 1")
      assignment2 = @course.assignments.create!(title: "Assignment 2")
      assignment3 = @course.assignments.create!(title: "Assignment 3")

      alignment1 = @outcome.align(assignment1, @course)
      alignment2 = @outcome.align(assignment2, @course)
      alignment3 = @outcome.align(@assignment3, @course)

      rubric_association1 = rubric.associate_with(assignment1, @course, purpose: "grading")
      rubric_association3 = rubric.associate_with(assignment3, @course, purpose: "grading")
      rubric_association2 = rubric.associate_with(assignment2, @course, purpose: "grading")

      now = Time.now
      yesterday = now - 1.day
      day_before_yesterday = now - 2.days

      create_learning_outcome_result(@student, 1, assignment1, alignment1, rubric_association1, day_before_yesterday)
      create_learning_outcome_result(@student, 2, assignment2, alignment2, rubric_association2, yesterday)
      create_learning_outcome_result(@student, 3, assignment3, alignment3, rubric_association3, now)

      get "user_outcome_results", params: { course_id: @course.id, user_id: @student.id }

      expect(assigns[:results].last.assessed_at).to eq(now)
      expect(assigns[:results].last.score).to eq(3)
    end

    context "deleted results" do
      before(:once) do
        account_outcome
        assessment_question_bank_with_questions
        @outcome.align(@bank, @bank.context, mastery_score: 0.7)

        @quiz = @course.quizzes.create!(title: "a quiz")
        @quiz.add_assessment_questions [@q1, @q2]

        @submission = @quiz.generate_submission @student
        @submission.quiz_data = @quiz.generate_quiz_data
        @submission.mark_completed
        Quizzes::SubmissionGrader.new(@submission).grade_submission
      end

      it "returns existing results" do
        user_session(@admin)

        get "user_outcome_results", params: { account_id: @account.id, user_id: @student.id }
        expect(response).to be_successful
        expect(assigns[:results]).not_to be_empty
      end

      it "does not return deleted results" do
        user_session(@admin)
        LearningOutcomeResult.find_by!(artifact: @submission, user: @student).destroy

        get "user_outcome_results", params: { account_id: @account.id, user_id: @student.id }
        expect(response).to be_successful
        expect(assigns[:results]).to be_empty
      end
    end
  end

  describe "GET 'list'" do
    it "lists account outcomes for an account context" do
      account_outcome

      user_session(@admin)
      get "list", params: { account_id: @account.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end

    it "lists account outcomes for a subaccount context" do
      account_outcome
      sub_account_1 = @account.sub_accounts.create!

      user_session(@admin)
      get "list", params: { account_id: sub_account_1.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end

    it "lists account outcomes for a course context" do
      account_outcome

      user_session(@teacher)
      get "list", params: { course_id: @course.id }
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end
  end

  describe "POST 'create'" do
    let(:outcome_params) do
      {
        description: "A long description",
        short_description: "A short description"
      }
    end

    it "requires authorization" do
      course_outcome
      post "create", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "does not let a student create a outcome" do
      user_session(@student)
      post "create", params: { course_id: @course.id,
                               learning_outcome: { short_description: "a" } }
      assert_unauthorized
    end

    it "allows creating a new outcome with the root group" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, learning_outcome: outcome_params }
      expect(response).to be_redirect
      expect(assigns[:outcome]).not_to be_nil
      expect(assigns[:outcome][:description]).to eql("A long description")
      expect(assigns[:outcome][:short_description]).to eql("A short description")
      expect(@course.learning_outcome_links.map(&:content).include?(assigns[:outcome])).to be_truthy

      @course.learning_outcome_groups.each do |group|
        if group.child_outcome_links.map(&:content).include?(assigns[:outcome])
          expect(group).to eql(@course.root_outcome_group)
        end
      end
    end

    it "allows creating a new outcome with a specific group" do
      # create a new group that is a child of the root group that we can
      # set our new outcome to belong to
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
        title: "Child outcome group", context: @course
      )
      expect(outcome_group.save).to be_truthy
      expect(outcome_group.id).not_to be_nil
      expect(outcome_group).not_to be_nil

      post "create", params: { course_id: @course.id,
                               learning_outcome_group_id: outcome_group.id,
                               learning_outcome: outcome_params }
      expect(response).to be_redirect
      expect(assigns[:outcome]).not_to be_nil
      expect(assigns[:outcome][:description]).to eql("A long description")
      expect(assigns[:outcome][:short_description]).to eql("A short description")
      expect(@course.learning_outcome_links.map(&:content).include?(assigns[:outcome])).to be_truthy

      @course.learning_outcome_groups.each do |group|
        if group.child_outcome_links.map(&:content).include?(assigns[:outcome])
          expect(group).to eql(outcome_group)
        end
      end
    end
  end

  describe "PUT 'update'" do
    let(:test_string) { "Some test string" }

    before do
      course_outcome
    end

    it "requires authorization" do
      put "update", params: { course_id: @course.id,
                              id: @outcome.id,
                              learning_outcome: { short_description: test_string } }
      assert_unauthorized
    end

    it "does not let a student update the outcome" do
      user_session(@student)
      put "update", params: { course_id: @course.id,
                              id: @outcome.id,
                              learning_outcome: { short_description: test_string } }
      assert_unauthorized
    end

    it "allows updating the outcome" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              id: @outcome.id,
                              learning_outcome: { short_description: test_string } }
      @outcome.reload
      expect(@outcome[:short_description]).to eql test_string
    end
  end

  describe "DELETE 'destroy'" do
    before do
      course_outcome
    end

    it "requires authorization" do
      delete "destroy", params: { course_id: @course.id, id: @outcome.id }
      assert_unauthorized
    end

    it "does not let a student delete the outcome" do
      user_session(@student)
      delete "destroy", params: { course_id: @course.id, id: @outcome.id }
      assert_unauthorized
    end

    it "deletes the outcome from the database" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: @outcome.id }
      @outcome.reload
      expect(@outcome).to be_deleted
    end
  end

  describe "GET 'outcome_result" do
    before do
      course_outcome
    end

    context "with a quiz result" do
      before do
        assessment_question_bank_with_questions
        @outcome.align(@bank, @bank.context, mastery_score: 0.7)

        @quiz = @course.quizzes.create!(title: "a quiz")
        @quiz.add_assessment_questions [@q1, @q2]

        @submission = @quiz.generate_submission @student
        @submission.quiz_data = @quiz.generate_quiz_data
        @submission.mark_completed
        Quizzes::SubmissionGrader.new(@submission).grade_submission
      end

      it "requires teacher authorization" do
        user_session(@student)
        get "outcome_result",
            params: { course_id: @course.id,
                      outcome_id: @outcome.id,
                      id: @outcome.learning_outcome_results.last }
        assert_unauthorized
      end

      it "does not return deleted results" do
        skip("skip due to flakiness, resolve with OUT-4368")
        @outcome.learning_outcome_results.last.destroy
        user_session(@teacher)
        get "outcome_result",
            params: { course_id: @course.id,
                      outcome_id: @outcome.id,
                      id: @outcome.learning_outcome_results.last }
        expect(response).to be_not_found
      end

      it "redirects to show quiz when result is a quiz" do
        user_session(@teacher)
        get "outcome_result",
            params: { course_id: @course.id,
                      outcome_id: @outcome.id,
                      id: @outcome.learning_outcome_results.last }
        expect(response).to redirect_to(/#{Regexp.quote(course_quiz_history_url(quiz_id: @submission.quiz_id))}/)
      end
    end
  end
end
