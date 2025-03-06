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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateSubmissionSticker do
  def run_mutation(anonymous_id:, assignment_id:, sticker:, current_user:, omit_sticker: false)
    mutation_command = <<~GQL
      mutation {
        updateSubmissionSticker(input: {
          anonymousId: "#{anonymous_id}",
          assignmentId: "#{assignment_id}",
          #{omit_sticker ? "" : "sticker: #{sticker || "null"},"}
        }) {
          submission {
            sticker
          }
        }
      }
    GQL

    result = CanvasSchema.execute(
      mutation_command,
      context: {
        current_user:,
        domain_root_account: @course.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )

    result.to_h.with_indifferent_access
  end

  before do
    account = Account.create!
    @course = account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = @course.assignments.create!(title: "Example Assignment")
    @submission = @assignment.submit_homework(
      student,
      submission_type: "online_text_entry",
      body: "body"
    )
  end

  it "updates the sticker" do
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: "basketball",
      current_user: @teacher
    )
    expect(result.dig("data", "updateSubmissionSticker", "submission", "sticker")).to eql "basketball"
    @submission.reload
    expect(@submission.sticker).to eql "basketball"
  end

  it "removes the sticker" do
    @submission.update!(sticker: "basketball")
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: nil,
      current_user: @teacher
    )
    expect(result.dig("data", "updateSubmissionSticker", "submission", "sticker")).to be_nil
    @submission.reload
    expect(@submission.sticker).to be_nil
  end

  it "requires the sticker param" do
    @submission.update!(sticker: "basketball")
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: nil,
      current_user: @teacher,
      omit_sticker: true
    )
    expect(result.dig("errors", 0, "message")).to eql "'sticker' is required. Provide a value of null to remove a sticker"
  end

  it "requires the sticker to be a supported sticker name" do
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: "potato",
      current_user: @teacher
    )
    expect(result.dig("errors", 0, "message")).to eql "Argument 'sticker' on InputObject 'UpdateSubmissionStickerInput' has an invalid value (potato). Expected type 'Sticker'."
  end

  it "requires stickers to be enabled" do
    @course.disable_feature!(:submission_stickers)
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: "basketball",
      current_user: @teacher
    )
    expect(result.dig("errors", 0, "message")).to eql "Stickers feature flag must be enabled"
  end

  it "returns not found if no submission matches the filters" do
    result = run_mutation(
      anonymous_id: "nonexistent123",
      assignment_id: @assignment.id,
      sticker: "basketball",
      current_user: @teacher
    )
    expect(result.dig("errors", 0, "message")).to eql "not found"
  end

  it "returns not found if current user doesn't have permission to update the sticker" do
    haxor = @course.enroll_student(User.create!, enrollment_state: "active").user
    result = run_mutation(
      anonymous_id: @submission.anonymous_id,
      assignment_id: @assignment.id,
      sticker: "basketball",
      current_user: haxor
    )
    expect(result.dig("errors", 0, "message")).to eql "not found"
  end
end
