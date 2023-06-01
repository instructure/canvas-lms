# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

RSpec.describe Mutations::DeleteSubmissionDraft do
  let_once(:submission) { submission_model }
  let_once(:student) { submission.user }

  def mutation_str(submission_id:)
    <<~GQL
      mutation {
        deleteSubmissionDraft(input: {
          submissionId: "#{submission_id}"
        }) {
          submissionDraftIds
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(submission_id: submission.id, current_user: student)
    result = CanvasSchema.execute(
      mutation_str(submission_id:),
      context: { current_user:, request: ActionDispatch::TestRequest.create }
    )
    result.to_h.with_indifferent_access
  end

  it "deletes an existing draft on the specified submission" do
    submission.submission_drafts.create!(submission_attempt: 1)

    expect do
      run_mutation
    end.to change {
      submission.reload.submission_drafts.count
    }.from(1).to(0)
  end

  it "deletes multiple drafts if somehow present" do
    submission.submission_drafts.create!(submission_attempt: 1)
    submission.submission_drafts.create!(submission_attempt: 2)

    expect do
      run_mutation
    end.to change {
      submission.reload.submission_drafts.count
    }.from(2).to(0)
  end

  it "returns the IDs of the deleted drafts" do
    draft = submission.submission_drafts.create!(submission_attempt: 1)
    result = run_mutation
    expect(result.dig(:data, :deleteSubmissionDraft, :submissionDraftIds)).to eq [draft.id.to_s]
  end

  it "returns an error if no drafts exist on the specified submission" do
    result = run_mutation
    expect(result.dig(:errors, 0, :message)).to eq "no drafts found"
  end

  it "returns an error if the submission is deleted" do
    submission.update!(workflow_state: "deleted")
    result = run_mutation
    expect(result.dig(:errors, 0, :message)).to eq "not found"
  end

  it "returns an error if the caller cannot modify the specified submission" do
    teacher = submission.course.enroll_teacher(User.create!, enrollment_state: "active").user
    result = run_mutation(current_user: teacher)
    expect(result.dig(:errors, 0, :message)).to eq "not found"
  end
end
