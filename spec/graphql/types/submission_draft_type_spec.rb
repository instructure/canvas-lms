#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative '../graphql_spec_helper'

RSpec.describe Types::SubmissionDraftType do
  before(:once) do
    @submission = submission_model
    @submission_draft = SubmissionDraft.create!(
      submission: @submission,
      submission_attempt: @submission.attempt
    )
  end

  def resolve_submission_draft
    result = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher})
      query {
        assignment(id: "#{@assignment.id}") {
          submissionsConnection(filter: {states: [unsubmitted, graded, pending_review, submitted]}) {
            nodes {
              submissionDraft {
                _id
                attachments {
                  _id
                  displayName
                }
                submissionAttempt
              }
            }
          }
        }
      }
    GQL

    result.dig(
      'data',
      'assignment',
      'submissionsConnection',
      'nodes'
    ).first['submissionDraft']
  end

  it 'returns the submission attempt' do
    submission_draft = resolve_submission_draft
    expect(submission_draft['submissionAttempt']).to eq(@submission.attempt)
  end

  it 'returns the draft attachments' do
    attachment = attachment_model
    @submission_draft.attachments = [
      attachment
    ]

    submission_draft = resolve_submission_draft
    expect(submission_draft['attachments'].first['displayName']).to eq(attachment.display_name)
  end
end
