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

require 'active_support'
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizRegrader::Submission do

  let(:regrade_options) do
    {1 => 'no_regrade', 2 => 'full_credit', 3 => 'current_correct_only' }
  end

  let(:question_group) do
    double(:pick_count => 1, :question_points => 25)
  end

  let(:question_regrades) do
    1.upto(3).each_with_object({}) do |i, hash|
      hash[i] = double(:quiz_question  => double(:id => i, :question_data => {:id => i}, :quiz_group => question_group),
                     :question_data  => {:id => i},
                     :regrade_option => regrade_options[i])
    end
  end

  let(:quiz_data) do
    question_regrades.map do |id, q|
      q.quiz_question.question_data.dup.merge(question_name: "Question #{id}")
    end
  end

  let(:submission_data) do
    1.upto(3).map {|i| {:question_id => i} }
  end

  let(:submission) do
    double(:score                 => 0,
         :score_before_regrade  => 1,
         :quiz_data             => quiz_data,
         :score=                => nil,
         :score_before_regrade= => nil,
         :submission_data       => submission_data,
         :write_attribute       => {})
  end

  let(:wrapper) do
    Quizzes::QuizRegrader::Submission.new(:submission        => submission,
                                          :question_regrades => question_regrades)
  end


  describe "#initialize" do
    it "saves a reference to the passed submission" do
      expect(wrapper.submission).to eq submission
    end

    it "saves a reference to the passed regrade quiz questions" do
      expect(wrapper.question_regrades).to eq question_regrades
    end
  end

  describe "#regrade!" do
    it "wraps each answer in the submisison's submission_data and regrades" do
      submission_data.each do |answer|
        answer_stub = double
        expect(answer_stub).to receive(:regrade!).once.and_return(1)
        expect(Quizzes::QuizRegrader::Answer).to receive(:new).and_return answer_stub
      end

      # submission data isn't called if not included in question_regrades
      submission_data << {:question_id => 4}
      expect(Quizzes::QuizRegrader::Answer).to receive(:new).with(submission_data.last, nil).never

      # submission updates and saves correct data
      expect(submission).to receive(:save_with_versioning!).once
      expect(submission).to receive(:score=).with(3)
      expect(submission).to receive(:score_before_regrade).and_return nil
      expect(submission).to receive(:score_before_regrade=).with(0)
      expect(submission).to receive(:quiz_data=)
      expect(submission).to receive_messages(:attempts => double(:last_versions => []))

      wrapper.regrade!
    end
  end

  describe "#rescored_submission" do
    before do
      regraded_quiz_data = question_regrades.map do |key, qr|
        Quizzes::QuizQuestionBuilder.decorate_question_for_submission({
          id: key,
          points_possible: question_group.question_points
        }, key)
      end

      expect(submission).to receive(:quiz_data=).with(regraded_quiz_data)

      @regrade_submission = Quizzes::QuizRegrader::Submission.new(
        :submission        => submission,
        :question_regrades => question_regrades)

      expect(@regrade_submission).to receive(:answers_to_grade).and_return []
    end

    it "scores the submission based on the regraded answers" do
      @regrade_submission.rescored_submission
    end

    it "doesn't change question names" do
      allow(@regrade_submission).to receive_messages(submitted_answer_ids: quiz_data.map { |q| q[:id] })

      question_names = @regrade_submission.rescored_submission.quiz_data.map do |q|
        q[:question_name]
      end

      expect(question_names.sort).to eq [
        'Question 1',
        'Question 2',
        'Question 3'
      ]
    end
  end
end
