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

describe CanvasQuizStatistics::Analyzers::Calculated do
  subject { described_class.new(question_data) }

  let(:question_data) { QuestionHelpers.fixture("calculated_question") }

  it "does not blow up when no responses are provided" do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  describe "[:graded]" do
    it "reflects the number of graded answers" do
      output = subject.run([
                             { correct: true },
                             { correct: "true" },
                             { correct: "undefined" },
                             { correct: false },
                             { correct: "false" },
                             {}
                           ])

      expect(output[:graded]).to eq(2)
    end
  end
end
