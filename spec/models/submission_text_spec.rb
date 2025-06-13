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

describe SubmissionText do
  before(:once) do
    course_with_student(active_all: true)
    @assignment = @course.assignments.create!
    @attachment = Attachment.create!(
      context: @assignment,
      uploaded_data: StringIO.new("a file"),
      filename: "file.doc",
      display_name: "file.doc",
      instfs_uuid: "old-instfs-uuid"
    )
    @submission = @assignment.submit_homework(@student)
    @root_account = @course.root_account

    @submission_text = SubmissionText.create!(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "This is the extracted text.",
      attempt: 1
    )
  end

  it "validates presence of submission" do
    submission_text = SubmissionText.new(
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Text without submission",
      attempt: 1
    )
    expect(submission_text).not_to be_valid
    expect(submission_text.errors[:submission]).to include("must exist")
  end

  it "validates presence of attachment" do
    submission_text = SubmissionText.new(
      submission: @submission,
      root_account_id: @root_account.id,
      text: "Text without attachment",
      attempt: 1
    )
    expect(submission_text).not_to be_valid
    expect(submission_text.errors[:attachment]).to include("must exist")
  end

  it "validates presence of text" do
    submission_text = SubmissionText.new(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: nil,
      attempt: 1
    )
    expect(submission_text).not_to be_valid
    expect(submission_text.errors[:text]).to include("can't be blank")
  end

  it "validates presence and positivity of attempt" do
    submission_text = SubmissionText.new(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Valid text",
      attempt: 0
    )
    expect(submission_text).not_to be_valid
    expect(submission_text.errors[:attempt]).to include("must be greater than 0")
  end

  it "validates uniqueness of [submission_id, attachment_id, attempt]" do
    duplicate = SubmissionText.new(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Duplicate record",
      attempt: 1
    )
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:submission_id]).to include("has already been taken")
  end

  it "allows same submission_id and attachment_id for different attempt" do
    submission_text = SubmissionText.new(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Retry attempt",
      attempt: 2
    )
    expect(submission_text).to be_valid
  end

  it "allows same submission_id for a different attachment" do
    another_attachment = Attachment.create!(
      context: @assignment,
      uploaded_data: StringIO.new("a new file"),
      filename: "file2.doc",
      display_name: "file2.doc",
      instfs_uuid: "old-instfs-uuid"
    )
    submission_text = SubmissionText.new(
      submission: @submission,
      attachment: another_attachment,
      root_account_id: @root_account.id,
      text: "Same submission, different attachment",
      attempt: 1
    )
    expect(submission_text).to be_valid
  end

  it "belongs to a submission" do
    expect(@submission_text.submission).to eq @submission
  end

  it "belongs to an attachment" do
    expect(@submission_text.attachment).to eq @attachment
  end

  it "defaults contains_images to false" do
    submission_text = SubmissionText.create!(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Default test text",
      attempt: 2
    )
    expect(submission_text.contains_images).to be false
  end

  it "allows setting contains_images to true" do
    submission_text = SubmissionText.create!(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Text with images",
      attempt: 3,
      contains_images: true
    )
    expect(submission_text.contains_images).to be true
  end

  it "is invalid if contains_images is nil" do
    submission_text = SubmissionText.new(
      submission: @submission,
      attachment: @attachment,
      root_account_id: @root_account.id,
      text: "Text with nil flag",
      attempt: 4,
      contains_images: nil
    )
    expect(submission_text).not_to be_valid
    expect(submission_text.errors[:contains_images]).to include("is not included in the list")
  end
end
