#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'active_support/dependencies'
require_dependency "turnitin/outcome_response_processor"
require File.expand_path(File.dirname(__FILE__) + '/turnitin_spec_helper')
require 'turnitin_api'
module Turnitin
  describe OutcomeResponseProcessor do
    before do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) {'encryption-secret-5T14NjaTbcYjc4'}
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) {'signing-secret-vp04BNqApwdwUYPUI'}
    end

    include_context "shared_tii_lti"
    subject { described_class.new(tool, lti_assignment, lti_student, outcome_response_json) }

    describe '#process' do
      let(:filename) {'my_sample_file'}

      before(:each) do
        original_submission_response = double('original_submission_mock')
        allow(original_submission_response).to receive(:headers).and_return(
            {'content-disposition' => "attachment; filename=#{filename}", 'content-type' => 'plain/text'}
        )
        allow(original_submission_response).to receive(:body).and_return('1234')
        expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_yield(original_submission_response)

        response_response = double('response_mock')
        allow(response_response).to receive(:body).and_return(tii_response)
        allow_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:response).and_return(response_response)
      end

      it 'creates an attachment' do
        subject.process
        attachment = lti_assignment.attachments.first
        expect(lti_assignment.attachments.count).to eq 1
        expect(attachment.display_name).to eq filename
      end

      it 'sets the turnitin status to pending' do
        subject.process
        submission = lti_assignment.submissions.first
        attachment = lti_assignment.attachments.first
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'pending'
      end

      it 'sets the submission submitted_at if not nil' do
        subject.process
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).to eq tii_response['meta']['date_uploaded']
      end

      it 'does not set the submission submitted_at if nil' do
        tii_response['meta']['date_uploaded'] = nil
        subject.process
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).not_to be_nil
      end
    end

    describe "#process with request errors" do
      context 'when it is not the last attempt' do
        it 'does not create an error attachment' do
          allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts-1)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_raise(Faraday::TimeoutError, 'Net::ReadTimeout')
          expect { subject.process }.to raise_error(Faraday::TimeoutError)
          expect(lti_assignment.attachments.count).to eq 0
        end

        it 'creates a new job' do
          time = Time.now.utc
          attempt_number = subject.class.max_attempts-1
          original_submission_response = double('original_submission_mock')
          allow(original_submission_response).to receive(:headers).and_return({})
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_yield(original_submission_response)
          allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(attempt_number)
          expect_any_instance_of(subject.class).to receive(:send_later_enqueue_args).with(
            :process,
            {
              max_attempts: subject.class.max_attempts,
              priority: Delayed::LOW_PRIORITY,
              attempts: attempt_number,
              run_at: time + (attempt_number ** 4) + 5
            }
          )
          Timecop.freeze(time) do
            subject.process
          end
        end
      end

      context 'when it is the last attempt' do
        it 'creates an attachment for "Errors::ScoreStillPendingError"' do
          allow(subject.class).to receive(:max_attempts).and_return(1)
          original_submission_response = double('original_submission_mock')
          allow(original_submission_response).to receive(:headers).and_return({})
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_yield(original_submission_response)
          expect { subject.process }.to raise_error(Errors::ScoreStillPendingError)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end

        it 'creates an attachment for "Faraday::TimeoutError"' do
          allow(subject.class).to receive(:max_attempts).and_return(1)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_raise(Faraday::TimeoutError, 'Net::ReadTimeout')
          expect { subject.process }.to raise_error(Faraday::TimeoutError)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end

        it 'creates an attachment for "Errno::ETIMEDOUT"' do
          allow(subject.class).to receive(:max_attempts).and_return(1)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_raise(Errno::ETIMEDOUT, 'Connection timed out - connect(2) for "api.turnitin.com" port 443')
          expect { subject.process }.to raise_error(Errno::ETIMEDOUT)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end

        it 'creates an attachment for "Faraday::ConnectionFailed"' do
          allow(subject.class).to receive(:max_attempts).and_return(1)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_raise(Faraday::ConnectionFailed, 'Connection reset by peer')
          expect { subject.process }.to raise_error(Faraday::ConnectionFailed)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end
      end
    end

    describe "#update_originality_data" do
      it 'raises an error if max attempts are not exceeded' do
        allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts-1)
        mock_turnitin_client = double('turnitin_client')
        allow(mock_turnitin_client).to receive(:scored?).and_return(false)
        allow(subject).to receive(:turnitin_client).and_return(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments:[attachment], submission_type: 'online_upload')
        expect do
          subject.update_originality_data(submission, attachment.asset_string)
        end.to raise_error Turnitin::Errors::SubmissionNotScoredError
      end

      it 'sets an error message if max attempts are exceeded' do
        allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts)
        mock_turnitin_client = double('turnitin_client')
        allow(mock_turnitin_client).to receive(:scored?).and_return(false)
        allow(subject).to receive(:turnitin_client).and_return(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments:[attachment], submission_type: 'online_upload')
        subject.update_originality_data(submission, attachment.asset_string)
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'error'
        expect(submission.turnitin_data[attachment.asset_string][:public_error_message]).to start_with "Turnitin has not"
      end
    end
  end
end
