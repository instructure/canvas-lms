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

describe Quizzes::QuizQuestion::AnswerSerializers::Matching do
  let :factory_options do
    {
      answer_parser_compatibility: true
    }
  end
  let :output do
    {
      "question_5_answer_7396" => "6061",
      "question_5_answer_4224" => "3855"
    }.with_indifferent_access
  end
  let :input do
    [
      { answer_id: "7396", match_id: "6061" },
      { answer_id: "4224", match_id: "3855" }
    ].map(&:with_indifferent_access)
  end

  include_examples "Answer Serializers"

  describe "#deserialize (full)" do
    it "includes all answer/match pairs" do
      output = subject.deserialize({
        "question_5_answer_7396" => "6061",
        "question_5_answer_6081" => nil,
        "question_5_answer_4224" => "3855",
        "question_5_answer_7397" => nil,
        "question_5_answer_7398" => nil,
        "question_5_answer_7399" => nil,
      }.as_json,
                                   full: true).as_json.sort_by { |v| v["answer_id"] }

      expect(output).to eq([
        { answer_id: "4224", match_id: "3855" },
        { answer_id: "6081", match_id: nil },
        { answer_id: "7396", match_id: "6061" },
        { answer_id: "7397", match_id: nil },
        { answer_id: "7398", match_id: nil },
        { answer_id: "7399", match_id: nil },
      ].as_json)
    end
  end

  context "validations" do
    it "rejects a bad pairing set" do
      [nil, "asdf"].each do |bad_input|
        rc = subject.serialize(bad_input)
        expect(rc.error).not_to be_nil
        expect(rc.error).to match(/of type array/i)
      end
    end

    it "rejects a bad pairing entry" do
      rc = subject.serialize(["asdf"])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/of type hash/i)
    end

    it "rejects a pairing entry missing a required parameter" do
      rc = subject.serialize([match_id: 123])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/missing parameter "answer_id"/i)

      rc = subject.serialize([answer_id: 123])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/missing parameter "match_id"/i)
    end

    it "rejects a match for an unknown answer" do
      rc = subject.serialize([{
                               answer_id: 123,
                               match_id: 6061
                             }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown answer/i)
    end

    it "rejects an unknown match" do
      rc = subject.serialize([{
                               answer_id: 7396,
                               match_id: 123_456
                             }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown match/i)
    end

    it "rejects a bad match" do
      rc = subject.serialize([{
                               answer_id: 7396,
                               match_id: "adooken"
                             }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end

    it "rejects a bad answer" do
      rc = subject.serialize([{
                               answer_id: "ping",
                               match_id: 6061
                             }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end
  end
end
