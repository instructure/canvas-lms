# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../graphql_spec_helper"

describe Types::AiGradeResultType do
  before(:once) do
    student_in_course(active_all: true)
    @assignment = @course.assignments.create!(name: "test", submission_types: "online_text_entry", points_possible: 10)
    @submission = @assignment.grade_student(@student, score: 8, grader: @teacher).first
    @auto_grade_result = AutoGradeResult.create!(
      submission: @submission,
      attempt: 1,
      grade_data: [
        {
          "id" => "criterion_1",
          "description" => "Use of Scholarly Sources",
          "comments" => "Good use of sources.",
          "rating" => {
            "id" => "rating_1",
            "description" => "Uses multiple credible sources.",
            "rating" => 3.0,
            "reasoning" => "The essay cites two credible sources."
          }
        }
      ],
      grading_attempts: 1,
      root_account_id: @course.root_account_id
    )
  end

  let(:type) { GraphQLTypeTester.new(@submission, current_user: @teacher, request: ActionDispatch::TestRequest.create) }

  it "returns top-level fields" do
    expect(type.resolve("aiGradeResult { attempt }")).to eq 1
    expect(type.resolve("aiGradeResult { gradingAttempts }")).to eq 1
    expect(type.resolve("aiGradeResult { errorMessage }")).to be_nil
  end

  it "returns grade data" do
    expect(type.resolve("aiGradeResult { gradeData { id } }")).to eq ["criterion_1"]
    expect(type.resolve("aiGradeResult { gradeData { description } }")).to eq ["Use of Scholarly Sources"]
    expect(type.resolve("aiGradeResult { gradeData { comments } }")).to eq ["Good use of sources."]
  end

  it "returns rating within grade data" do
    expect(type.resolve("aiGradeResult { gradeData { rating { id } } }")).to eq ["rating_1"]
    expect(type.resolve("aiGradeResult { gradeData { rating { description } } }")).to eq ["Uses multiple credible sources."]
    expect(type.resolve("aiGradeResult { gradeData { rating { rating } } }")).to eq [3.0]
    expect(type.resolve("aiGradeResult { gradeData { rating { reasoning } } }")).to eq ["The essay cites two credible sources."]
  end
end
