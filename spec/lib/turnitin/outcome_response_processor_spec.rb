require_dependency "turnitin/outcome_response_processor"
require File.expand_path(File.dirname(__FILE__) + '/turnitin_spec_helper')
require 'turnitin_api'
module Turnitin
  describe OutcomeResponseProcessor do
    include_context "shared_tii_lti"
    subject { described_class.new(tool, lti_assignment, lti_student, outcome_response_json) }

    describe '#process' do
      let(:filename) {'my_sample_file'}

      before(:each) do
        original_submission_response = mock('original_submission_mock')
        original_submission_response.stubs(:headers).returns(
            {'content-disposition' => "attachment; filename=#{filename}", 'content-type' => 'plain/text'}
        )
        original_submission_response.stubs(:body).returns('1234')
        TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).yields(original_submission_response)

        response_response = mock('response_mock')
        response_response.stubs(:body).returns(tii_response)
        TurnitinApi::OutcomesResponseTransformer.any_instance.stubs(:response).returns(response_response)
      end

      it 'creates an attachment' do
        subject.process_without_send_later
        attachment = lti_assignment.attachments.first
        expect(lti_assignment.attachments.count).to eq 1
        expect(attachment.display_name).to eq filename
      end

      it 'sets the turnitin status to pending' do
        subject.process_without_send_later
        submission = lti_assignment.submissions.first
        attachment = lti_assignment.attachments.first
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'pending'
      end

      it 'sets the submission submitted_at if not nil' do
        subject.process_without_send_later
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).to eq tii_response['meta']['date_uploaded']
      end

      it 'does not set the submission submitted_at if nil' do
        tii_response['meta']['date_uploaded'] = nil
        subject.process_without_send_later
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).not_to be_nil
      end
    end

    describe "#process with request errors" do
      context 'when it is not the last attempt' do
        it 'does not create an error attachment' do
          subject.class.any_instance.stubs(:attempt_number).returns(subject.class.max_attempts-1)
          TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).raises(Faraday::TimeoutError, 'Net::ReadTimeout')
          expect { subject.process_without_send_later }.to raise_error(Faraday::TimeoutError)
          expect(lti_assignment.attachments.count).to eq 0
        end
      end

      context 'when it is the last attempt' do
        it 'creates an attachment for "Faraday::TimeoutError"' do
          subject.class.stubs(:max_attempts).returns(1)
          TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).raises(Faraday::TimeoutError, 'Net::ReadTimeout')
          expect { subject.process_without_send_later }.to raise_error(Faraday::TimeoutError)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end

        it 'creates an attachment for "Errno::ETIMEDOUT"' do
          subject.class.stubs(:max_attempts).returns(1)
          TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).raises(Errno::ETIMEDOUT, 'Connection timed out - connect(2) for "api.turnitin.com" port 443')
          expect { subject.process_without_send_later }.to raise_error(Errno::ETIMEDOUT)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end

        it 'creates an attachment for "Faraday::ConnectionFailed"' do
          subject.class.stubs(:max_attempts).returns(1)
          TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).raises(Faraday::ConnectionFailed, 'Connection reset by peer')
          expect { subject.process_without_send_later }.to raise_error(Faraday::ConnectionFailed)
          attachment = lti_assignment.attachments.first
          expect(lti_assignment.attachments.count).to eq 1
          expect(attachment.display_name).to eq "Failed turnitin submission"
        end
      end
    end

    describe "#update_originality_data" do
      it 'raises an error if max attempts are not exceeded' do
        subject.class.any_instance.stubs(:attempt_number).returns(subject.class.max_attempts-1)
        mock_turnitin_client = mock('turnitin_client')
        mock_turnitin_client.stubs(:scored?).returns(false)
        subject.stubs(:turnitin_client).returns(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments:[attachment], submission_type: 'online_upload')
        expect do
          subject.update_originality_data(submission, attachment.asset_string)
        end.to raise_error Turnitin::Errors::SubmissionNotScoredError
      end

      it 'sets an error message if max attempts are exceeded' do
        subject.class.any_instance.stubs(:attempt_number).returns(subject.class.max_attempts)
        mock_turnitin_client = mock('turnitin_client')
        mock_turnitin_client.stubs(:scored?).returns(false)
        subject.stubs(:turnitin_client).returns(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments:[attachment], submission_type: 'online_upload')
        subject.update_originality_data(submission, attachment.asset_string)
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'error'
        expect(submission.turnitin_data[attachment.asset_string][:public_error_message]).to start_with "Turnitin has not"
      end
    end
  end
end
