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
      submission_attempt: @submission.attempt + 1
    )
  end

  def resolve_submission_draft
    result = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher, request: ActionDispatch::TestRequest.create})
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
                body
                meetsAssignmentCriteria
                submissionAttempt
                url
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
    expect(submission_draft['submissionAttempt']).to eq(@submission.attempt + 1)
  end

  it 'returns the draft attachments' do
    attachment = attachment_model
    @submission_draft.attachments = [
      attachment
    ]

    submission_draft = resolve_submission_draft
    expect(submission_draft['attachments'].first['displayName']).to eq(attachment.display_name)
  end

  it 'returns the draft body' do
    @submission_draft.body = 'some text'
    @submission_draft.save!

    submission_draft = resolve_submission_draft
    expect(submission_draft['body']).to eq('some text')
  end

  it 'returns the meetsAssignmentCriteria field' do
    submission_draft = resolve_submission_draft
    expect(submission_draft['meetsAssignmentCriteria']).to eq(false)
  end

  it 'returns the draft url' do
    @submission_draft.url = 'http://www.google.com'
    @submission_draft.save!

    submission_draft = resolve_submission_draft
    expect(submission_draft['url']).to eq('http://www.google.com')
  end
end
