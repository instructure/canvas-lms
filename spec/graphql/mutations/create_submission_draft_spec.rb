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

RSpec.describe Mutations::CreateSubmissionDraft do
  before(:once) do
    @submission = submission_model
    @attachments = [
      attachment_with_context(@student),
      attachment_with_context(@student)
    ]
  end

  def mutation_str(
    submission_id: @submission.id,
    active_submission_type: nil,
    attempt: nil,
    body: nil,
    file_ids: [],
    url: nil
  )
    <<~GQL
      mutation {
        createSubmissionDraft(input: {
          submissionId: "#{submission_id}"
          #{"activeSubmissionType: #{active_submission_type}" if active_submission_type}
          #{"attempt: #{attempt}" if attempt}
          #{"body: \"#{body}\"" if body}
          fileIds: #{file_ids}
          #{"url: \"#{url}\"" if url}
        }) {
          submissionDraft {
            _id
            submissionAttempt
            activeSubmissionType
            attachments {
              _id
              displayName
            }
            body
            url
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(mutation_str(opts), context: {current_user: current_user, request: ActionDispatch::TestRequest.create})
    result.to_h.with_indifferent_access
  end

  it 'creates a new submission draft' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      file_ids: @attachments.map(&:id)
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :_id)
    ).to eq SubmissionDraft.last.id.to_s
  end

  it 'updates an existing submission draft' do
    first_result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      file_ids: @attachments.map(&:id)
    )
    attachment_ids = first_result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).map { |attachment| attachment[:_id] }
    expect(attachment_ids.count).to eq 2
    @attachments.each do |attachment|
      expect(attachment_ids.include?(attachment[:id].to_s)).to be true
    end

    second_result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      file_ids: [@attachments[0].id]
    )
    attachment_ids = second_result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).map { |attachment| attachment[:_id] }
    expect(attachment_ids.count).to eq 1
    expect(attachment_ids[0]).to eq @attachments[0].id.to_s

    expect(
      first_result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq second_result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
  end

  it 'allows you to set a body on the submission draft' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_text_entry',
      attempt: @submission.attempt,
      body: 'some text body'
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to eq 'some text body'
  end

  it 'allows you to set a url on the submission draft' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_url',
      attempt: @submission.attempt,
      url: 'http://www.google.com'
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq 'http://www.google.com'
  end

  it 'allows you to set an active_submission_type on the submission draft' do
    result = run_mutation(
      active_submission_type: 'online_text_entry',
      attempt: @submission.attempt,
      body: 'some text body',
      submission_id: @submission.id
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :activeSubmissionType)
    ).to eq 'online_text_entry'
  end

  it 'only updates attachments when the active submission type is online_upload' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      body: 'some text body',
      file_ids: @attachments.map(&:id)
    )
    attachment_ids = result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).map { |attachment| attachment[:_id] }

    expect(attachment_ids.count).to eq 2
    @attachments.each do |attachment|
      expect(attachment_ids.include?(attachment[:id].to_s)).to be true
    end

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to be nil
  end

  it 'only updates the body when the active submission type is online_text_entry' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_text_entry',
      attempt: @submission.attempt,
      body: 'some text body',
      url: 'http://www.google.com'
    )

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to eq 'some text body'

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to be nil
  end

  it 'only updates the url when the active submission type is online_url' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_url',
      attempt: @submission.attempt,
      body: 'some text body',
      url: 'http://www.google.com'
    )

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to be nil

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq 'http://www.google.com'
  end

  it 'returns an error if the active submission type is not included' do
    result = run_mutation(
      attempt: @submission.attempt,
      body: 'some text body',
      submission_id: @submission.id
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to include "Argument 'activeSubmissionType' on InputObject 'CreateSubmissionDraftInput' is required"
  end

  it 'returns an error if the active submission type is not valid' do
    result = run_mutation(
      active_submission_type: 'thundercougarfalconbird',
      attempt: @submission.attempt,
      body: 'some text body',
      submission_id: @submission.id
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to include "Expected type 'DraftableSubmissionType!'"
  end

  it 'prefixes the url with a scheme if missing' do
    @submission.assignment.update!(submission_types: 'online_url')
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_url',
      attempt: @submission.attempt,
      url: 'www.google.com'
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq 'http://www.google.com'
  end

  it 'returns an error if the attachments are not owned by the user' do
    attachment = attachment_with_context(@teacher)
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      file_ids: [attachment.id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq "No attachments found for the following ids: [\"#{attachment.id}\"]"
  end

  it 'returns an error if the attachments don\'t have an allowed file extension' do
    @submission.assignment.update!(allowed_extensions: ['lemon'])
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: @submission.attempt,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq 'Invalid file type'
  end

  it 'returns a graceful error if the submission is not found' do
    result = run_mutation(
      submission_id: 1337,
      active_submission_type: 'online_upload',
      attempt: 0,
      file_ids: []
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to eq 'not found'
  end

  it 'returns an error if the draft is more then one attempt more the current submission attempt' do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: 1337,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq 'submission draft cannot be more then one attempt ahead of the current submission'
  end

  it 'uses the submission attempt plus one if an explicit attempt is not provided' do
    result = run_mutation(
      active_submission_type: 'online_upload',
      submission_id: @submission.id,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq @submission.attempt + 1
  end

  it 'uses the given attempt when provided' do
    @submission.update!(attempt: 2)
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: 'online_upload',
      attempt: 1,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq 1
  end
end
