# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

require_relative "../spec_helper"

describe AutoGradeResult do
  before(:once) do
    course_with_student(active_all: true)
    @assignment = @course.assignments.create!
    @submission = @assignment.submit_homework(@student)
    @root_account = @course.root_account
    # Create the original record
    @auto_grade_result = AutoGradeResult.create!(
      submission: @submission,
      attempt: 1,
      root_account_id: @root_account.id,
      grade_data: {},
      grading_attempts: 1
    )
  end

  it "validates presence of submission" do
    result = AutoGradeResult.new(
      attempt: 1,
      root_account_id: @root_account.id,
      grade_data: {},
      grading_attempts: 0
    )
    expect(result).not_to be_valid
    expect(result.errors[:submission]).to include("must exist")
  end

  it "validates presence of attempt" do
    result = AutoGradeResult.new(
      submission: @submission,
      root_account_id: @root_account.id,
      grade_data: {},
      grading_attempts: 0
    )
    expect(result).not_to be_valid
    expect(result.errors[:attempt]).to include("can't be blank")
  end

  it "validates attempt is greater than 0" do
    @auto_grade_result.attempt = 0
    expect(@auto_grade_result).not_to be_valid
    expect(@auto_grade_result.errors[:attempt]).to include("must be greater than 0")
  end

  it "validates grading_attempts is greater than 0" do
    @auto_grade_result.grading_attempts = 0
    expect(@auto_grade_result).not_to be_valid
    expect(@auto_grade_result.errors[:grading_attempts]).to include("must be greater than 0")
  end

  it "allows empty grade_data hash" do
    @auto_grade_result.grade_data = {}
    expect(@auto_grade_result).to be_valid
  end

  it "validates uniqueness of submission_id scoped to attempt" do
    duplicate = AutoGradeResult.new(
      submission: @submission,
      attempt: 1, # Use same attempt as original
      root_account_id: @root_account.id,
      grade_data: {},
      grading_attempts: 1 # Must be >= 1 to pass validation
    )
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:submission_id]).to include("has already been taken")
  end

  it "allows different attempts for the same submission" do
    result = AutoGradeResult.new(
      submission: @submission,
      attempt: 2, # Different attempt
      root_account_id: @root_account.id,
      grade_data: {},
      grading_attempts: 1
    )
    expect(result).to be_valid
  end

  it "belongs to a submission" do
    expect(@auto_grade_result.submission).to eq @submission
  end
end
