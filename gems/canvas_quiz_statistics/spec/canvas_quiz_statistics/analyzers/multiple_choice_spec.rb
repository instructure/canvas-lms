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

describe CanvasQuizStatistics::Analyzers::MultipleChoice do
  subject { described_class.new(question_data) }

  let(:question_data) { QuestionHelpers.fixture("multiple_choice_question") }

  it "does not blow up when no responses are provided" do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  describe "[:responses]" do
    it "counts those who picked a correct answer" do
      expect(subject.run([{ answer_id: 3023 }])[:responses]).to eq(1)
    end

    it "counts those who picked an incorrect answer" do
      expect(subject.run([{ answer_id: 8899 }])[:responses]).to eq(1)
    end

    it "does not count those who picked nothing" do
      expect(subject.run([{}])[:responses]).to eq(0)
    end

    it "does not get confused by picking some non-existing answer" do
      expect(subject.run([{ answer_id: "asdf" }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: nil }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: true }])[:responses]).to eq(0)
    end
  end

  describe "[:answers][]" do
    describe "[:id]" do
      it "stringifies ids" do
        expect(subject.run([])[:answers].pluck(:id).sort).to eq(%w[
                                                                  3023
                                                                  5646
                                                                  7907
                                                                  8899
                                                                ])
      end
    end

    describe "[:text]" do
      it "is included" do
        expect(subject.run([])[:answers][0][:text]).to eq("A")
      end

      context "when missing" do
        it "uses a :html if present" do
          data = question_data.clone
          data[:answers][0].merge!({
                                     html: "<p>Hi.</p>",
                                     text: ""
                                   })

          subject = described_class.new(data)
          expect(subject.run([])[:answers][0][:text]).to eq("<p>Hi.</p>")
        end

        it "justs accept how things are, otherwise" do
          data = question_data.clone
          data[:answers][0].merge!({ html: "", text: "" })

          subject = described_class.new(data)
          expect(subject.run([])[:answers][0][:text]).to eq("")
        end
      end
    end

    describe "[:correct]" do
      it "is true for those with a weight of 100" do
        expect(subject.run([])[:answers][0][:correct]).to be(true)
        expect(subject.run([])[:answers][1][:correct]).to be(false)
        expect(subject.run([])[:answers][2][:correct]).to be(false)
        expect(subject.run([])[:answers][3][:correct]).to be(false)
      end
    end

    describe "[:responses]" do
      it "counts the number of students who got it right" do
        stats = subject.run([{ answer_id: 3023 }])
        answer = stats[:answers].detect { |a| a[:id] == "3023" }
        expect(answer[:responses]).to eq(1)
      end
    end
  end
end
