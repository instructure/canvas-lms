# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Quizzes::QuizRegrader::Regrader do
  around do |example|
    Timecop.freeze(Time.zone.local(2013), &example)
  end

  let(:questions) do
    1.upto(4).map do |i|
      double(id: i, question_data: { id: i, regrade_option: "full_credit" })
    end
  end

  let(:submissions) do
    1.upto(4).map { |i| double(id: i, completed?: true, latest_submitted_attempt: 1) }
  end

  let(:current_quiz_question_regrades) do
    1.upto(4).map { |i| double(quiz_question_id: i, regrade_option: "full_credit") }
  end

  let(:quiz) do
    double(quiz_questions: questions,
           id: 1,
           version_number: 1,
           current_quiz_question_regrades:,
           quiz_submissions: submissions)
  end

  let(:quiz_regrade) { double(id: 1, quiz:) }

  let(:quiz_regrader) { Quizzes::QuizRegrader::Regrader.new(quiz:) }

  before do
    allow(quiz).to receive(:current_regrade).and_return quiz_regrade
    allow(Quizzes::QuizQuestion).to receive(:where).with(quiz_id: quiz.id).and_return questions
    allow(Quizzes::QuizSubmission).to receive(:where).with(quiz_id: quiz.id).and_return submissions
  end

  describe "#initialize" do
    it "saves the quiz passed" do
      expect(quiz_regrader.quiz).to eq quiz
    end

    it "takes an optional submissions argument" do
      submissions = []
      expect(Quizzes::QuizRegrader::Regrader.new(quiz:, submissions:)
        .submissions).to eq submissions
    end
  end

  describe "#quiz" do
    it "finds the passed version of the quiz if present" do
      quiz_stub = double
      options = {
        quiz:,
        version_number: 2
      }

      allow(Version).to receive(:where).with(
        versionable_type: Quizzes::Quiz.class_names,
        number: 2,
        versionable_id: quiz.id
      ).once.and_return([double(model: quiz_stub)])

      expect(Quizzes::QuizRegrader::Regrader.new(options).quiz).to eq quiz_stub
    end
  end

  describe "#submissions" do
    it "skips submissions that are in progress with no prior attempts" do
      questions << double(id: 5, question_data: { regrade_option: "no_regrade" })

      uncompleted_submission = double(id: 5, completed?: false, latest_submitted_attempt: nil)
      submissions << uncompleted_submission

      expect(quiz_regrader.submissions.length).to eq 4
      expect(quiz_regrader.submissions.detect { |s| s.id == 5 }).to be_nil
    end

    it "does not skip submissions that are in progress that have prior attempts" do
      questions << double(id: 5, question_data: { regrade_option: "no_regrade" })

      uncompleted_submission = double(id: 5, completed?: false, latest_submitted_attempt: 1)
      submissions << uncompleted_submission

      expect(quiz_regrader.submissions.length).to eq 5
      expect(quiz_regrader.submissions.detect { |s| s.id == 5 }).to_not be_nil
    end
  end

  describe "#regrade!" do
    it "creates a QuizRegrader::Submission for each submission and regrades them" do
      questions << double(id: 5, question_data: { regrade_option: "no_regrade" })
      questions << double(id: 6, question_data: {})

      expect(Quizzes::QuizRegradeRun).to receive(:perform).with(quiz_regrade)
      allow_any_instance_of(Quizzes::QuizRegrader::Submission).to receive(:regrade!)

      quiz_regrader.regrade!
    end
  end
end
