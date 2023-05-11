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

require_relative "support/answer_serializers_specs"
require_relative "support/textual_answer_serializers_specs"

describe Quizzes::QuizQuestion::AnswerSerializers::FillInMultipleBlanks do
  let :output do
    {
      "question_5_#{AssessmentQuestion.variable_id "answer1"}" => "red",
      "question_5_#{AssessmentQuestion.variable_id "answer3"}" => "green",
      "question_5_#{AssessmentQuestion.variable_id "answer4"}" => "blue"
    }.with_indifferent_access
  end
  let :input do
    {
      answer1: "Red",
      answer3: "Green",
      answer4: "Blue"
    }.with_indifferent_access
  end

  include_examples "Answer Serializers"

  # needed for auto specs
  def sanitize(answer_hash)
    answer_hash.each_pair do |variable, answer_text|
      answer_hash[variable] =
        Quizzes::QuizQuestion::AnswerSerializers::Util.sanitize_text(answer_text)
    end

    answer_hash
  end

  # needed for auto specs
  def format(answer_text)
    { answer1: answer_text }
  end

  describe "#deserialize (full)" do
    it "includes all answer/match pairs" do
      output = subject.deserialize({
        "question_5_#{AssessmentQuestion.variable_id "answer1"}" => "red",
        "question_5_#{AssessmentQuestion.variable_id "answer2"}" => nil,
        "question_5_#{AssessmentQuestion.variable_id "answer3"}" => "green",
        "question_5_#{AssessmentQuestion.variable_id "answer4"}" => "blue",
        "question_5_#{AssessmentQuestion.variable_id "answer5"}" => nil,
        "question_5_#{AssessmentQuestion.variable_id "answer6"}" => nil,
      }.as_json,
                                   full: true)

      expect(output).to eq({
        answer1: "red",
        answer2: nil,
        answer3: "green",
        answer4: "blue",
        answer5: nil,
        answer6: nil,
      }.as_json)
    end
  end

  context "validations" do
    include_examples "Textual Answer Serializers"

    it "rejects unexpected types" do
      ["asdf", nil].each do |bad_input|
        rc = subject.serialize(bad_input)
        expect(rc.error).not_to be_nil
        expect(rc.error).to match(/must be of type hash/i)
      end
    end

    it "rejects an answer to an unknown blank" do
      rc = subject.serialize({ foobar: "yeeeeeeeeee" })
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown blank/i)
    end
  end
end
