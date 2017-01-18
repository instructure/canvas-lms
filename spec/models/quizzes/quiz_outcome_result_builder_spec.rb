#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizOutcomeResultBuilder do
  def question_data(reset=false)
    @qdc = (reset || !@qdc) ? 1 : @qdc + 1
    {:name => "question #{@qdc}", :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' =>
      [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]
    }
  end

  def build_course_quiz_questions_and_a_bank
    course_with_student(:active_all => true)
    @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
    @q1 = @quiz.quiz_questions.create!(:question_data => question_data(true))
    @q2 = @quiz.quiz_questions.create!(:question_data => question_data)
    @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
    @bank = @q1.assessment_question.assessment_question_bank
    @outcome.align(@bank, @bank.context, :mastery_score => 0.7)
  end

  def find_the_answer_from_a_question(question)
    question.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
  end

  def answer_a_question(question, submission, correct: true)
    q_id = question.data[:id]
    answer = if correct
              find_the_answer_from_a_question(question)
             else
               find_the_answer_from_a_question(question) + 1
             end
    submission.submission_data["question_#{q_id}"] = answer
  end

  describe "quiz level learning outcome results" do
    before :once do
      build_course_quiz_questions_and_a_bank
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      @outcome.reload
      @quiz_results = @outcome.learning_outcome_results.where(user_id: @user).to_a
      @quiz_result = @quiz_results.first
      @question_results = @quiz_results.first.learning_outcome_question_results
    end
    it 'has valid bank data' do
      expect(@bank.learning_outcome_alignments.length).to eql(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      expect(@bank.assessment_question_count).to eql(2)
      expect(@sub.score).to eql(1.0)
    end
    it "should create learning outcome results" do
      expect(@quiz_results.size).to eql(1)
      expect(@question_results.size).to eql(2)
    end
    it 'should consider scores in aggregate' do
      expect(@quiz_result.possible).to eql(2.0)
      expect(@quiz_result.score).to eql(1.0)
    end
    it "shouldn't declare mastery" do
      expect(@quiz_result.mastery).to eql(false)
    end
    context 'with two outcomes' do
      before :once do
        course_with_student(active_all: true)
        @quiz = @course.quizzes.create!(title: 'test quiz')
        @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
        @outcome2 = @course.created_learning_outcomes.create!(:short_description => 'new outcome #2')

        @bank = @course.assessment_question_banks.create!(:title => 'bank1')
        @bank2 = @course.assessment_question_banks.create!(:title => 'bank2')

        @outcome.align(@bank, @bank.context, :mastery_score => 0.7)
        @outcome2.align(@bank2, @bank2.context, :mastery_score => 0.5)

        @a1 = @bank.assessment_questions.create!(question_data: question_data(true))
        @a3 = @bank.assessment_questions.create!(question_data: question_data)
        @a2 = @bank2.assessment_questions.create!(question_data: question_data)
        @a4 = @bank2.assessment_questions.create!(question_data: question_data)
        @q1 = @quiz.quiz_questions.create!(assessment_question: @a1, question_data: @a1.question_data)
        @q3 = @quiz.quiz_questions.create!(assessment_question: @a3, question_data: @a3.question_data)
        @q2 = @quiz.quiz_questions.create!(assessment_question: @a2, question_data: @a2.question_data)
        @q4 = @quiz.quiz_questions.create!(assessment_question: @a4, question_data: @a4.question_data)

        @quiz.generate_quiz_data(:persist => true)
        @sub = @quiz.generate_submission(@user)
        @sub.submission_data = {}
        answer_a_question(@q1, @sub)
        answer_a_question(@q2, @sub)
        answer_a_question(@q3, @sub, correct: false)
        answer_a_question(@q4, @sub, correct: false)
        Quizzes::SubmissionGrader.new(@sub).grade_submission
        @outcome.reload
        @outcome2.reload
        @quiz_results = LearningOutcomeResult.where(user_id: @user).to_a
        @question_results = @quiz_results.map(&:learning_outcome_question_results)
      end
      it "has valid bank data" do
        expect(@bank.learning_outcome_alignments.length).to eql(1)
        expect(@bank2.learning_outcome_alignments.length).to eql(1)
        expect(@q1.assessment_question.assessment_question_bank).to eql(@bank)
        expect(@q3.assessment_question.assessment_question_bank).to eql(@bank)
        expect(@q2.assessment_question.assessment_question_bank).to eql(@bank2)
        expect(@q4.assessment_question.assessment_question_bank).to eql(@bank2)
        expect(@bank.assessment_question_count).to eql(2)
        expect(@bank2.assessment_question_count).to eql(2)
      end
      it "should create two learning outcome results" do
        expect(@question_results.map(&:size)).to eql([2,2])
        expect(@quiz_results.size).to eql(2)
      end
      it 'should consider scores in aggregate' do
        expect(@quiz_results.map(&:possible)).to eql([2.0,2.0])
        expect(@quiz_results.map(&:score)).to eql([1.0,1.0])
      end
      it "should declare mastery when equal" do
        expect(@quiz_results.map(&:mastery)).to eql([false, true])
      end
    end
  end

  describe "question level learning outcomes" do
    it "should create learning outcome results when aligned to assessment questions" do
      build_course_quiz_questions_and_a_bank
      expect(@bank.learning_outcome_alignments.length).to eql(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      @q1.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @q2.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(false)
    end

    it "should update learning outcome results when aligned to assessment questions" do
      build_course_quiz_questions_and_a_bank
      expect(@bank.learning_outcome_alignments.length).to eql(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub)
      answer_a_question(@q2, @sub, correct: false)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(false)
      @sub = @quiz.generate_submission(@user)
      expect(@sub.attempt).to eql(2)
      @sub.submission_data = {}
      answer_a_question(@q1, @sub, correct: false)
      answer_a_question(@q2, @sub)
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @quiz_result = @outcome.learning_outcome_results.where(user_id: @user).first
      @results = @quiz_result.learning_outcome_question_results
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(false)
      expect(@results.first.original_mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(true)
      expect(@results.last.original_mastery).to eql(false)
    end
  end
end