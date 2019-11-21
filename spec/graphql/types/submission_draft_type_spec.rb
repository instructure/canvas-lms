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
    @media_object = factory_with_protected_attributes(MediaObject, :media_id => 'm-123456', :title => 'CreedThoughts')
  end

  def resolve_submission_draft
    result = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher, request: ActionDispatch::TestRequest.create})
      query {
        assignment(id: "#{@assignment.id}") {
          submissionsConnection(filter: {states: [unsubmitted, graded, pending_review, submitted]}) {
            nodes {
              submissionDraft {
                _id
                activeSubmissionType
                attachments {
                  _id
                  displayName
                }
                body
                mediaObject {
                  _id
                  title
                }
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

  it 'returns the media object' do
    @submission_draft.media_object_id = @media_object.media_id
    @submission_draft.save!

    submission_draft = resolve_submission_draft
    expect(submission_draft['mediaObject']['_id']).to eq(@media_object.media_id)
    expect(submission_draft['mediaObject']['title']).to eq(@media_object.title)
  end

  it 'returns the active submission type' do
    @submission_draft.active_submission_type = 'online_upload'
    @submission_draft.save!

    submission_draft = resolve_submission_draft
    expect(submission_draft['activeSubmissionType']).to eq('online_upload')
  end
end
