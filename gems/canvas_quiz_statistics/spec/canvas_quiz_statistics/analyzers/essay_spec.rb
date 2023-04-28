# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe CanvasQuizStatistics::Analyzers::Essay do
  subject { described_class.new(question_data) }

  let(:question_data) { QuestionHelpers.fixture("essay_question") }

  it "does not blow up when no responses are provided" do
    expect do
      expect(subject.run([])).to be_present
    end.to_not raise_error
  end

  it_behaves_like "essay [:responses]"

  describe "output [#run]" do
    describe "[:responses]" do
      it "counts students who have written anything" do
        expect(subject.run([{ text: "foo" }])[:responses]).to eq(1)
      end

      it "does not count students who have written a blank response" do
        expect(subject.run([{}])[:responses]).to eq(0)
        expect(subject.run([{ text: nil }])[:responses]).to eq(0)
        expect(subject.run([{ text: "" }])[:responses]).to eq(0)
      end
    end

    it ":graded - should reflect the number of graded answers" do
      output = subject.run([
                             { correct: "defined" }, { correct: "undefined" }
                           ])

      expect(output[:graded]).to eq(1)
    end

    describe ":full_credit" do
      let :question_data do
        { points_possible: 3 }
      end

      it "counts all students who received full credit" do
        output = subject.run([
                               { points: 3 }, { points: 2 }, { points: 3 }
                             ])

        expect(output[:full_credit]).to eq(2)
      end

      it "counts students who received more than full credit" do
        output = subject.run([
                               { points: 3 }, { points: 2 }, { points: 5 }
                             ])

        expect(output[:full_credit]).to eq(2)
      end

      it "is 0 otherwise" do
        output = subject.run([
                               { points: 1 }
                             ])

        expect(output[:full_credit]).to eq(0)
      end

      it "counts those who exceed the maximum points possible" do
        output = subject.run([{ points: 5 }])
        expect(output[:full_credit]).to eq(1)
      end
    end

    describe ":answers" do
      let :question_data do
        { points_possible: 10 }
      end

      it "groups items into answer type buckets with appropriate data" do
        output = subject.run([
                               { points: 0, correct: "undefined", user_id: 100, user_name: "Joe0" },
                               { points: 0, correct: "undefined", user_id: 100, user_name: "Joe0" },
                               { points: 0, correct: "undefined", user_id: 100, user_name: "Joe0" },
                               { points: 1, correct: "defined", user_id: 101, user_name: "Joe1" },
                               { points: 2, correct: "defined", user_id: 102, user_name: "Joe2" },
                               { points: 3, correct: "defined", user_id: 103, user_name: "Joe3" },
                               { points: 4, correct: "defined", user_id: 104, user_name: "Joe4" },
                               { points: 6, correct: "defined", user_id: 106, user_name: "Joe6" },
                               { points: 7, correct: "defined", user_id: 107, user_name: "Joe7" },
                               { points: 8, correct: "defined", user_id: 108, user_name: "Joe8" },
                               { points: 9, correct: "defined", user_id: 109, user_name: "Joe9" },
                               { points: 10, correct: "defined", user_id: 110, user_name: "Joe10" },
                             ])
        answers = output[:answers]

        bottom = answers[2]
        expect(bottom[:responses]).to eq 2
        expect(bottom[:user_ids]).to include(101)
        expect(bottom[:user_names]).to include("Joe1")
        expect(bottom[:full_credit]).to be_falsey

        middle = answers[1]
        expect(middle[:responses]).to eq 5
        expect(middle[:user_ids]).to include(106)
        expect(middle[:user_names]).to include("Joe6")
        expect(middle[:full_credit]).to be_falsey

        top = answers[0]
        expect(top[:responses]).to eq 2
        expect(top[:user_ids]).to include(110)
        expect(top[:user_names]).to include("Joe10")
        expect(top[:full_credit]).to be_truthy

        undefined = answers[3]
        expect(undefined[:responses]).to eq 3
        expect(undefined[:user_ids].uniq).to eq [100]
        expect(undefined[:user_names].uniq).to eq ["Joe0"]
        expect(undefined[:full_credit]).to be_falsey
      end
    end

    describe ":point_distribution" do
      it "maps each score to the number of receivers" do
        output = subject.run([
                               { points: 1, user_id: 1 },
                               { points: 3, user_id: 2 },
                               { points: 3, user_id: 3 },
                               { points: nil, user_id: 5 }
                             ])

        expect(output[:point_distribution]).to include({ score: nil, count: 1 })
        expect(output[:point_distribution]).to include({ score: 1, count: 1 })
        expect(output[:point_distribution]).to include({ score: 3, count: 2 })
      end

      it "sorts them in score ascending mode" do
        output = subject.run([
                               { points: 3, user_id: 2 },
                               { points: 3, user_id: 3 },
                               { points: 1, user_id: 1 },
                               { points: nil, user_id: 5 }
                             ])

        expect(output[:point_distribution].pluck(:score)).to eq([nil, 1, 3])
      end
    end
  end
end
