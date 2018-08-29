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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutcomesController do
  def context_outcome(context)
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(:title => 'outcome')
    @outcome_group.add_outcome(@outcome)
  end

  def course_outcome
    context_outcome(@course)
  end

  def account_outcome
    context_outcome(@account)
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @account = Account.default
    account_admin_user
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>15,'hidden'=>true}])
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_successful
    end

    it "should work in accounts" do
      user_session(@admin)
      account_outcome
      get 'index', params: {:account_id => @account.id}
    end

    it "should find a common core group from settings" do
      user_session(@admin)
      account_outcome
      Setting.set(AcademicBenchmark.common_core_setting_key, @outcome_group.id)
      get 'index', params: {:account_id => @account.id}
      expect(assigns[:js_env][:COMMON_CORE_GROUP_ID]).to eq @outcome_group.id
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_outcome
      get 'show', params: {:course_id => @course.id, :id => @outcome.id}
      assert_unauthorized
    end

    it "should not allow students to view outcomes" do
      user_session(@student)
      course_outcome
      get 'show', params: {:course_id => @course.id, :id => @outcome.id}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      course_outcome
      get 'show', params: {:course_id => @course.id, :id => @outcome.id}
      expect(response).to be_successful
    end

    it "should work in accounts" do
      user_session(@admin)
      account_outcome
      get 'show', params: {:account_id => @account.id, :id => @outcome.id}
      expect(response).to be_successful
    end

    it "should include tags from courses when viewed in the account" do
      account_outcome

      quiz = @course.quizzes.create!
      alignment = @outcome.align(quiz, @course)

      user_session(@admin)
      get 'show', params: {:account_id => @account.id, :id => @outcome.id}

      expect(assigns[:alignments].any?{ |a| a.id == alignment.id }).to be_truthy
    end

    it "should not allow access to individual outcomes for large_roster courses" do
      course_outcome

      @course.large_roster = true
      @course.save!

      get 'show', params: {:course_id => @course.id, :id => @outcome.id}
      expect(response).to be_redirect
    end
  end

  describe "GET 'details'" do
    it "should require authorization" do
      course_outcome
      get 'details', params: {:course_id => @course.id, :outcome_id => @outcome.id}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      course_outcome
      get 'details', params: {:course_id => @course.id, :outcome_id => @outcome.id}
      expect(response).to be_successful
    end

    it "should work in accounts" do
      user_session(@admin)
      account_outcome
      get 'details', params: {:account_id => @account.id, :outcome_id => @outcome.id}
    end
  end

  describe "GET 'user_outcome_results'" do
    it "should require authorization" do
      account_outcome
      get 'user_outcome_results', params: {:account_id => @account.id, :user_id => @student.id}
      assert_unauthorized
    end

    it "should return outcomes for the given user" do
      account_outcome
      user_session(@admin)
      get 'user_outcome_results', params: {:account_id => @account.id, :user_id => @student.id}
      expect(response).to be_successful
      expect(response).to render_template('user_outcome_results')
    end
  end

  describe "GET 'list'" do
    it "should list account outcomes for an account context" do
      account_outcome

      user_session(@admin)
      get 'list', params: {:account_id => @account.id}
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end

    it "should list account outcomes for a subaccount context" do
      account_outcome
      sub_account_1 = @account.sub_accounts.create!

      user_session(@admin)
      get 'list', params: {:account_id => sub_account_1.id}
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end

    it "should list account outcomes for a course context" do
      account_outcome

      user_session(@teacher)
      get 'list', params: {:course_id => @course.id}
      expect(response).to be_successful
      data = json_parse
      expect(data).not_to be_empty
    end
  end

  describe "POST 'create'" do
    before :once do
      OUTCOME_PARAMS = {
        :description => "A long description",
        :short_description => "A short description"
      }
    end

    it "should require authorization" do
      course_outcome
      post 'create', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should not let a student create a outcome" do
      user_session(@student)
      post 'create', params: {:course_id => @course.id,
                     :learning_outcome => { :short_description => TEST_STRING }}
      assert_unauthorized
    end

    it "should allow creating a new outcome with the root group" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :learning_outcome => OUTCOME_PARAMS}
      expect(response).to be_redirect
      expect(assigns[:outcome]).not_to be_nil
      expect(assigns[:outcome][:description]).to eql("A long description")
      expect(assigns[:outcome][:short_description]).to eql("A short description")
      expect(@course.learning_outcome_links.map { |n| n.content }.include?(assigns[:outcome])).to be_truthy

      @course.learning_outcome_groups.each do |group|
        if group.child_outcome_links.map { |n| n.content }.include?(assigns[:outcome])
          expect(group).to eql(@course.root_outcome_group)
        end
      end
    end

    it "should allow creating a new outcome with a specific group" do
      # create a new group that is a child of the root group that we can
      # set our new outcome to belong to
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
                                  :title => "Child outcome group", :context => @course)
      expect(outcome_group.save).to be_truthy
      expect(outcome_group.id).not_to be_nil
      expect(outcome_group).not_to be_nil

      post 'create', params: {:course_id => @course.id, :learning_outcome_group_id => outcome_group.id,
                     :learning_outcome => OUTCOME_PARAMS}
      expect(response).to be_redirect
      expect(assigns[:outcome]).not_to be_nil
      expect(assigns[:outcome][:description]).to eql("A long description")
      expect(assigns[:outcome][:short_description]).to eql("A short description")
      expect(@course.learning_outcome_links.map { |n| n.content }.include?(assigns[:outcome])).to be_truthy

      @course.learning_outcome_groups.each do |group|
        if group.child_outcome_links.map { |n| n.content }.include?(assigns[:outcome])
          expect(group).to eql(outcome_group)
        end
      end
    end
  end

  describe "PUT 'update'" do
    TEST_STRING = "Some test String"

    before :each do
      course_outcome
    end

    it "should require authorization" do
      put 'update', params: {:course_id => @course.id, :id => @outcome.id,
                    :learning_outcome => { :short_description => TEST_STRING }}
      assert_unauthorized
    end

    it "should not let a student update the outcome" do
      user_session(@student)
      put 'update', params: {:course_id => @course.id, :id => @outcome.id,
                    :learning_outcome => { :short_description => TEST_STRING }}
      assert_unauthorized
    end

    it "should allow updating the outcome" do
      user_session(@teacher)
      put 'update', params: {:course_id => @course.id, :id => @outcome.id,
                    :learning_outcome => { :short_description => TEST_STRING }}
      @outcome.reload
      expect(@outcome[:short_description]).to eql TEST_STRING
    end
  end

  describe "DELETE 'destroy'" do
    before :each do
      course_outcome
    end

    it "should require authorization" do
      delete 'destroy', params: {:course_id => @course.id, :id => @outcome.id}
      assert_unauthorized
    end

    it "should not let a student delete the outcome" do
      user_session(@student)
      delete 'destroy', params: {:course_id => @course.id, :id => @outcome.id}
      assert_unauthorized
    end

    it "should delete the outcome from the database" do
      user_session(@teacher)
      delete 'destroy', params: {:course_id => @course.id, :id => @outcome.id}
      @outcome.reload
      expect(@outcome).to be_deleted
    end
  end

  describe "GET 'outcome_result" do
    before :each do
      course_outcome
    end

    context "with a quiz result" do
      before :each do
        assessment_question_bank_with_questions
        @outcome.align(@bank, @bank.context, :mastery_score => 0.7)

        @quiz = @course.quizzes.create!(:title => "a quiz")
        @quiz.add_assessment_questions [ @q1, @q2 ]

        @submission = @quiz.generate_submission @student
        @submission.quiz_data = @quiz.generate_quiz_data
        @submission.mark_completed
        Quizzes::SubmissionGrader.new(@submission).grade_submission
      end

      it "should require teacher authorization" do
        user_session(@student)
        get 'outcome_result',
          params: {:course_id => @course.id,
          :outcome_id => @outcome.id,
          :id => @outcome.learning_outcome_results.last}
        assert_unauthorized
      end

      it "should redirect to show quiz when result is a quiz" do
        user_session(@teacher)
        get 'outcome_result',
          params: {:course_id => @course.id,
          :outcome_id => @outcome.id,
          :id => @outcome.learning_outcome_results.last}
        expect(response).to redirect_to(/#{Regexp.quote(course_quiz_history_url(quiz_id: @submission.quiz_id))}/)
      end
    end
  end
end
