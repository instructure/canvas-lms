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

describe Quizzes::QuizRegrader::AttemptVersion do

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

  let(:questions) do
    question_regrades.values.map { |q| q.quiz_question.question_data.dup }
  end

  let(:submission_data) do
    1.upto(3).map {|i| {:question_id => i} }
  end

  let(:submission) do
    double(:score                 => 0,
         :score_before_regrade  => 1,
         :questions             => questions,
         :score=                => nil,
         :score_before_regrade= => nil,
         :submission_data       => submission_data,
         :write_attribute       => {})
  end

  let(:version) do
    double(:model => submission)
  end

  let(:attempt_version) do
    Quizzes::QuizRegrader::AttemptVersion.new(:version        => version,
                                              :question_regrades => question_regrades)
  end

  describe "#initialize" do
    it "saves a reference to the passed version" do
      expect(attempt_version.version).to eq version
    end

    it "saves a reference to the passed regrade quiz questions" do
      expect(attempt_version.question_regrades).to eq question_regrades
    end
  end

  describe "#regrade!" do

    it "assigns the model and saves the version" do
      submission_data.each do |answer|
        answer_stub = double
        expect(answer_stub).to receive(:regrade!).once.and_return(1)
        expect(Quizzes::QuizRegrader::Answer).to receive(:new).and_return answer_stub
      end

      # submission data isn't called if not included in question_regrades
      submission_data << {:question_id => 4}
      expect(Quizzes::QuizRegrader::Answer).to receive(:new).with(submission_data.last, nil).never

      expect(submission).to receive(:score=).with(3)
      expect(submission).to receive(:score_before_regrade).and_return nil
      expect(submission).to receive(:score_before_regrade=).with(0)
      expect(submission).to receive(:quiz_data=)

      expect(version).to receive(:model=)
      expect(version).to receive(:save!)

      attempt_version.regrade!
    end
  end
end
