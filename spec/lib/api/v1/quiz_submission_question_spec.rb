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

require_relative '../../../spec_helper'

describe Api::V1::QuizSubmissionQuestion do
  before :once do
    course_with_student(active_all: true)
    @quiz = Quizzes::Quiz.create!(title: "quiz", context: @course)
    @quiz_submission = @quiz.generate_submission(@student)
  end

  def create_question(type, factory_options = {}, quiz=@quiz)
    factory = method(:"#{type}_question_data")

    # can't test for #arity directly since it might be an optional parameter
    data = factory.parameters.include?([ :opt, :options ]) ?
    factory.call(factory_options) :
    factory.call

    data = data.except('id', 'assessment_question_id')

    qq = quiz.quiz_questions.create!({ question_data: data })
    qq.assessment_question.question_data = data
    qq.assessment_question.save!

    qq
  end

  class QuizSubmissionsQuestionHarness
    include Api::V1::QuizSubmissionQuestion
    include Api

    def initialize(opts)
      @context = opts[:context] if opts[:context]
    end
  end

  let(:api) { QuizSubmissionsQuestionHarness.new(context: @course) }

  describe "#quiz_submissions_questions_json" do
    subject { api.quiz_submission_questions_json(quiz_questions, @quiz_submission) }

    let(:quiz_questions) do
      1.upto(3).map do |i|
        create_question "multiple_choice"
      end
    end

    let(:submission_data) do
      {}
    end

    it "returns json" do
      is_expected.to be_a Hash
    end

    let(:submission_data) do
      []
    end

    it "handles submitted submission_data" do
      is_expected.to be_a Hash
    end
  end

  describe "quiz_submissions_questions_json shuffle_answers" do
    before{ allow_any_instance_of(Array).to receive(:shuffle!) }
    let(:quiz_questions) do
      [create_question("multiple_choice")]
    end

    let(:submission_data) do
      {}
    end

    describe "shuffle_answers true" do
      subject { api.quiz_submission_questions_json(quiz_questions, @quiz_submission, {shuffle_answers: true}) }
      it "shuffles answers when opt is given" do
        expect_any_instance_of(Array).to receive(:shuffle!).at_least(:once)
        subject[:quiz_submission_questions].first["answers"].map{|a| a["text"]}
      end
    end

    describe "shuffle_answers false" do
      subject { api.quiz_submission_questions_json(quiz_questions, @quiz_submission, {shuffle_answers: false}) }
      it "shuffles answers when opt is given" do
        expect_any_instance_of(Array).to receive(:shuffle!).never
        answer_text = subject[:quiz_submission_questions].first["answers"].map{|a| a["text"]}
        expect(answer_text).to eq(["a","b","c","d"])
      end
    end
  end
end
