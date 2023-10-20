# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe Quizzes::QuizOutcomeResultBuilder do
  describe "quiz level learning outcome results" do
    before :once do
      build_course_quiz_questions_and_a_bank
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      @quiz_results = @outcome.learning_outcome_results.active.where(user_id: @user).to_a
      @quiz_result = @quiz_results.first
      @question_results = @quiz_results.first.learning_outcome_question_results
    end

    it "has valid bank data" do
      expect(@bank.learning_outcome_alignments.length).to be(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      expect(@bank.assessment_question_count).to be(2)
      expect(@sub.score).to be(1.0)
    end

    it "creates learning outcome results" do
      expect(@quiz_results.size).to be(1)
      expect(@question_results.size).to be(2)
    end

    it "has root account ids on learning outcome question results" do
      expect(@question_results.first.root_account_id).to eq @course.root_account_id
    end

    it "considers scores in aggregate" do
      expect(@quiz_result.possible).to be(2.0)
      expect(@quiz_result.score).to be(1.0)
    end

    it "does not declare mastery" do
      expect(@quiz_result.mastery).to be(false)
    end

    context "manually grading via speedgrader" do
      it "updates score to lower score if scoring_policy is keep_highest" do
        expect(@sub.quiz.scoring_policy).to eq "keep_highest"
        expect(@outcome.learning_outcome_results.active.where(user_id: @user).first.score).to equal 1.0
        # if grader_id is present then the score is being updated by speedgrader
        @sub.update_scores({
                             "grader_id" => @teacher.id,
                             "context_id" => @course.id,
                             "override_scores" => true,
                             "context_type" => "Course",
                             "submission_version_number" => "1",
                             "question_score_#{@q1.id}" => "0"
                           })
        @sub.reload
        expect(@sub.score).to be(0.0)
        @outcome.reload
        expect(@outcome.learning_outcome_results.active.where(user_id: @user).count).to equal 1
        expect(@outcome.learning_outcome_results.active.where(user_id: @user).first.score).to equal 0.0
      end
    end

    context "with long quiz titles" do
      before :once do
        @user.update!(name: "a" * 255)
        @sub.update_scores({
                             "context_id" => @course.id,
                             "override_scores" => true,
                             "context_type" => "Course",
                             "submission_version_number" => "1",
                             "question_score_#{@q2.id}" => "0"
                           })
      end

      it "truncates result.title and question_result.title to 250 characters" do
        expect(@quiz_result.reload.title.length).to eq 250
        @question_results.each { |result| expect(result.title.length).to eq 250 }
      end
    end

    context "with two outcomes" do
      before :once do
        course_with_student(active_all: true)
        @quiz = @course.quizzes.create!(title: "test quiz")
        @outcome = @course.created_learning_outcomes.create!(short_description: "new outcome")
        @outcome2 = @course.created_learning_outcomes.create!(short_description: "new outcome #2")

        @bank = @course.assessment_question_banks.create!(title: "bank1")
        @bank2 = @course.assessment_question_banks.create!(title: "bank2")

        @outcome.align(@bank, @bank.context, mastery_score: 0.7)
        @outcome2.align(@bank2, @bank2.context, mastery_score: 0.5)

        @a1 = @bank.assessment_questions.create!(question_data: question_data(true))
        @a3 = @bank.assessment_questions.create!(question_data:)
        @a2 = @bank2.assessment_questions.create!(question_data:)
        @a4 = @bank2.assessment_questions.create!(question_data:)
        @q1 = @quiz.quiz_questions.create!(assessment_question: @a1, question_data: @a1.question_data)
        @q3 = @quiz.quiz_questions.create!(assessment_question: @a3, question_data: @a3.question_data)
        @q2 = @quiz.quiz_questions.create!(assessment_question: @a2, question_data: @a2.question_data)
        @q4 = @quiz.quiz_questions.create!(assessment_question: @a4, question_data: @a4.question_data)

        @quiz.generate_quiz_data(persist: true)
        @sub = @quiz.generate_submission(@user)
        @sub.submission_data = {}
        answer_a_question(@q1, @sub)
        answer_a_question(@q2, @sub)
        answer_a_question(@q3, @sub, correct: false)
        answer_a_question(@q4, @sub, correct: false)
        Quizzes::SubmissionGrader.new(@sub).grade_submission
        @outcome.reload
        @outcome2.reload
        @quiz_results = LearningOutcomeResult.where(user_id: @user).sort_by(&:learning_outcome_id).to_a
        @question_results = @quiz_results.map(&:learning_outcome_question_results)
      end

      it "has valid bank data" do
        expect(@bank.learning_outcome_alignments.length).to be(1)
        expect(@bank2.learning_outcome_alignments.length).to be(1)
        expect(@q1.assessment_question.assessment_question_bank).to eql(@bank)
        expect(@q3.assessment_question.assessment_question_bank).to eql(@bank)
        expect(@q2.assessment_question.assessment_question_bank).to eql(@bank2)
        expect(@q4.assessment_question.assessment_question_bank).to eql(@bank2)
        expect(@bank.assessment_question_count).to be(2)
        expect(@bank2.assessment_question_count).to be(2)
      end

      it "creates two learning outcome results" do
        expect(@question_results.map(&:size)).to eql([2, 2])
        expect(@quiz_results.size).to be(2)
      end

      it "considers scores in aggregate" do
        expect(@quiz_results.map(&:possible)).to eql([2.0, 2.0])
        expect(@quiz_results.map(&:score)).to eql([1.0, 1.0])
      end

      it "declares mastery when equal" do
        expect(@quiz_results.map(&:mastery)).to eql([false, true])
      end
    end
  end

  describe "quiz level learning outcome results from out of order submission" do
    def submission
      sub = @quiz.generate_submission(@user)
      sub.submission_data = {}
      sub
    end

    def answer_and_grade(sub, correct: false)
      answer_a_question(@q1, sub)
      answer_a_question(@q2, sub, correct:)
      Quizzes::SubmissionGrader.new(sub).grade_submission
    end

    before :once do
      build_course_quiz_questions_and_a_bank
      @quiz.generate_quiz_data(persist: true)
      @sub1 = submission
      @sub2 = submission
      # 2nd attempt: both questions answered correctly
      answer_and_grade(@sub2, correct: true)
      # align a second outcome in-between attempts
      @outcome2 = @course.created_learning_outcomes.create!(short_description: "another outcome")
      @bank = @q1.assessment_question.assessment_question_bank
      @outcome2.align(@bank, @bank.context, mastery_score: 0.7)
      # 1st attempt: only one question answered correctly
      answer_and_grade(@sub1)
      @quiz_results = @outcome.reload.learning_outcome_results.active.where(user_id: @user).to_a
      @quiz_results2 = @outcome2.reload.learning_outcome_results.active.where(user_id: @user).to_a
    end

    it "first attempt should not override results from second attempt" do
      expect(@quiz_results.size).to eq 1
      expect(@quiz_results.first.attempt).to eq 2
      # full score since all questions answered correctly on second attempt
      expect(@quiz_results.first.score).to eq 2.0
      expect(@quiz_results.first.possible).to eq 2.0
    end

    it "first attempt should generate a valid result" do
      expect(@quiz_results2.size).to eq 1
      expect(@quiz_results2.first.attempt).to eq 1
      # partial score since the first and only attempt answered only one question correctly
      expect(@quiz_results2.first.score).to eq 1.0
      expect(@quiz_results2.first.possible).to eq 2.0
    end
  end

  describe "question level learning outcomes" do
    it "creates learning outcome results when aligned to assessment questions" do
      build_course_quiz_questions_and_a_bank
      expect(@bank.learning_outcome_alignments.length).to be(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      @q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      @q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to be(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to be(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to be(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to be(false)
    end

    it "updates learning outcome results when aligned to assessment questions and kept score will update" do
      build_course_quiz_questions_and_a_bank({}, { scoring_policy: "keep_latest" })
      expect(@bank.learning_outcome_alignments.length).to be(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to be(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results.sort_by(&:associated_asset_id)
      updated_at_times = @results.map(&:updated_at)
      expect(@results.length).to be(2)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to be(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to be(false)
      @sub = @quiz.generate_submission(@user)
      expect(@sub.attempt).to be(2)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub, correct: false)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to be(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results.sort_by(&:associated_asset_id)
      expect(@results.length).to be(2)
      expect(updated_at_times).not_to eql(@results.map(&:updated_at))
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to be(false)
      expect(@results.first.original_mastery).to be(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to be(true)
      expect(@results.last.original_mastery).to be(false)
    end

    it "does not update learning outcome results when kept score will not update" do
      build_course_quiz_questions_and_a_bank
      expect(@bank.learning_outcome_alignments.length).to be(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to be(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results.sort_by(&:associated_asset_id)
      expect(@results.length).to be(2)
      updated_at_times = @results.map(&:updated_at)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to be(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to be(false)
      @sub = @quiz.generate_submission(@user)
      expect(@sub.attempt).to be(2)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub, correct: false)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to be(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results.sort_by(&:associated_asset_id)
      expect(updated_at_times).to eql(@results.map(&:updated_at))
      expect(@results.first.mastery).to be(true)
      expect(@results.last.mastery).to be(false)
    end

    context "manually grading via speedgrader" do
      it "updates to lower score if scoring_policy is keep_highest" do
        build_course_quiz_questions_and_a_bank
        expect(@quiz.scoring_policy).to eq "keep_highest"
        expect(@bank.learning_outcome_alignments.length).to be(1)
        expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
        @quiz.generate_quiz_data(persist: true)
        @sub = @quiz.generate_submission(@user)
        @sub.submission_data = {}
        answer_a_question(@q1, @sub)
        answer_a_question(@q2, @sub, correct: false)
        Quizzes::SubmissionGrader.new(@sub).grade_submission
        expect(@sub.score).to be(1.0)
        @outcome.reload
        @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
        @results = @quiz_result.learning_outcome_question_results.sort_by(&:associated_asset_id)
        expect(@results.length).to be(2)
        expect(@results.first.associated_asset).to eql(@q1.assessment_question)
        expect(@results.first.mastery).to be(true)
        expect(@results.last.associated_asset).to eql(@q2.assessment_question)
        expect(@results.last.mastery).to be(false)
        expect(@outcome.learning_outcome_results.active.where(user_id: @user).first.score).to equal 1.0
        # if grader_id is present then the score is being updated by speedgrader
        @sub.update_scores({
                             "grader_id" => @teacher.id,
                             "context_id" => @course.id,
                             "override_scores" => true,
                             "context_type" => "Course",
                             "submission_version_number" => "1",
                             "question_score_#{@q1.id}" => "0"
                           })
        @sub.reload
        expect(@sub.score).to be(0.0)
        @outcome.reload
        @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user)
        expect(@quiz_result.count).to equal 1
        expect(@quiz_result.first.score).to equal 0.0
        @results = @quiz_result.first.learning_outcome_question_results.sort_by(&:associated_asset_id)
        expect(@results.first.associated_asset).to eql(@q1.assessment_question)
        expect(@results.first.mastery).to be(false)
        expect(@results.last.associated_asset).to eql(@q2.assessment_question)
        expect(@results.last.mastery).to be(false)
      end
    end
  end

  describe "quizzes with a mix of auto-gradeable and non-auto-gradeable questions" do
    before :once do
      build_course_quiz_questions_and_a_bank(q2: { "question_type" => "essay_question", "answers" => [] })
      @quiz.generate_quiz_data(persist: true)
      @quiz.save!
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
    end

    it "creates an outcome result even if the total score doesn't increase after grading an essay question" do
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).count).to equal 0
      @sub.update_scores({
                           "context_id" => @course.id,
                           "override_scores" => true,
                           "context_type" => "Course",
                           "submission_version_number" => "1",
                           "question_score_#{@q2.id}" => "0"
                         })
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).count).to equal 1
    end
  end

  describe "quizzes that aren't graded or complete" do
    before :once do
      build_course_quiz_questions_and_a_bank({ "question_type" => "essay_question", "answers" => [] })
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
    end

    it "creates and updates an outcome result once fully manually graded" do
      # update_scores is the method fired when manually grading a quiz in speedgrader.
      @sub.update_scores({
                           "context_id" => @course.id,
                           "override_scores" => true,
                           "context_type" => "Course",
                           "submission_version_number" => "1",
                           "question_score_#{@q1.id}" => "1",
                         })
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).count).to equal 0
      @sub.update_scores({
                           "context_id" => @course.id,
                           "override_scores" => true,
                           "context_type" => "Course",
                           "submission_version_number" => "1",
                           "question_score_#{@q2.id}" => "1"
                         })
      results = @outcome.learning_outcome_results.active.where(user_id: @user)
      expect(results.count).to equal 1
      expect(results[0].score).to equal 2.0
      @sub.update_scores({
                           "context_id" => @course.id,
                           "override_scores" => true,
                           "context_type" => "Course",
                           "submission_version_number" => "1",
                           "question_score_#{@q1.id}" => "2"
                         })
      results[0].reload
      expect(results[0].score).to equal 3.0
    end
  end

  describe "ungraded quizzes and surveys" do
    before :once do
      build_course_quiz_questions_and_a_bank
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
    end

    it "does not create learning outcome results for an ungraded survey" do
      @quiz.update_attribute("quiz_type", "survey")
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).length).to be(0)
    end

    it "does not create learning outcome results for a graded survey" do
      @quiz.update_attribute("quiz_type", "graded_survey")
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).length).to be(0)
    end

    it "does not create learning outcome results for a practice quiz" do
      @quiz.update_attribute("quiz_type", "practice_quiz")
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      expect(@outcome.learning_outcome_results.active.where(user_id: @user).length).to be(0)
    end
  end

  describe "quiz questions with no points possible" do
    before :once do
      build_course_quiz_questions_and_a_bank({}, { scoring_policy: "keep_latest" })
      @q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      @q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
    end

    it "does not generate a learning outcome question result for 0 point questions" do
      q2_data = @q2.question_data
      q2_data[:points_possible] = 0.0
      @q2.update_attribute("question_data", q2_data)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to be(1)
      @results = @results.sort_by(&:associated_asset_id)
    end

    it "removes an existing question result when re-assessed if points changed to 0" do
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to be(2)
      q2_data = @q2.question_data
      q2_data[:points_possible] = 0.0
      @q2.update_attribute("question_data", q2_data)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to be(1)
    end
  end

  describe "quizzes with no points possible" do
    before :once do
      build_course_quiz_questions_and_a_bank
      @q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      @q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
    end

    it "does not generate a learning outcome result" do
      q1_data = @q1.question_data
      q1_data[:points_possible] = 0.0
      @q1.update_attribute("question_data", q1_data)
      q2_data = @q2.question_data
      q2_data[:points_possible] = 0.0
      @q2.update_attribute("question_data", q2_data)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      expect(@quiz_result).to be_nil
    end

    it "removes an existing result when re-assessed if points changed to 0" do
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      expect(@quiz_result).to be_present
      q1_data = @q1.question_data
      q1_data[:points_possible] = 0.0
      @q1.update_attribute("question_data", q1_data)
      q2_data = @q2.question_data
      q2_data[:points_possible] = 0.0
      @q2.update_attribute("question_data", q2_data)
      @quiz.generate_quiz_data(persist: true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @quiz_result = @outcome.learning_outcome_results.active.where(user_id: @user).first
      expect(@quiz_result).to be_nil
    end
  end
end
