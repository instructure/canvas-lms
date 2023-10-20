# frozen_string_literal: true

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

require_relative "turnitin_spec_helper"
require "turnitin_api"
module Turnitin
  describe OutcomeResponseProcessor do
    subject { described_class.new(tool, lti_assignment, lti_student, outcome_response_json) }

    before do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
    end

    include_context "shared_tii_lti"

    describe "#process" do
      let(:filename) { "my_sample_file" }

      before do
        original_submission_response = double("original_submission_mock")
        allow(original_submission_response).to receive_messages(headers: { "content-disposition" => "attachment; filename=#{filename}", "content-type" => "plain/text" }, body: "1234")
        expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_yield(original_submission_response)

        response_response = double("response_mock")
        allow(response_response).to receive(:body).and_return(tii_response)
        allow_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:response).and_return(response_response)
      end

      it "creates an attachment" do
        subject.process
        attachment = lti_assignment.attachments.first
        expect(lti_assignment.attachments.count).to eq 1
        expect(attachment.display_name).to eq filename
      end

      it "sets the turnitin status to pending" do
        subject.process
        submission = lti_assignment.submissions.first
        attachment = lti_assignment.attachments.first
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq "pending"
      end

      it "sets the submission submitted_at if not nil" do
        subject.process
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).to eq tii_response["meta"]["date_uploaded"]
      end

      it "does not set the submission submitted_at if nil" do
        tii_response["meta"]["date_uploaded"] = nil
        subject.process
        submission = lti_assignment.submissions.first
        expect(submission.submitted_at).not_to be_nil
      end

      it "does not increment attempt twice if submitted_at is not nil" do
        subject.process
        submission = lti_assignment.submissions.first
        expect(submission.attempt).to eq 1
      end

      it "does not create a new submission version if processed twice" do
        subject.process
        submission = lti_assignment.submissions.first
        subject.process
        expect(submission.versions.count).to eq 1
      end
    end

    describe "#process with request errors" do
      context "when it is not the last attempt" do
        it "does not create an error attachment" do
          allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts - 1)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:response).and_raise(Faraday::TimeoutError, "Net::ReadTimeout")
          expect { subject.process }.to raise_error(Faraday::TimeoutError)
          expect(lti_assignment.attachments.count).to eq 0
        end

        it "creates a new job" do
          allow_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:uploaded_at).and_return(tii_response["meta"]["date_uploaded"])
          time = Time.now.utc
          attempt_number = subject.class.max_attempts - 1
          original_submission_response = double("original_submission_mock")
          allow(original_submission_response).to receive_messages(headers: {}, status: 403)
          expect_any_instance_of(TurnitinApi::OutcomesResponseTransformer).to receive(:original_submission).and_yield(original_submission_response)
          allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(attempt_number)
          mock = double
          expect_any_instance_of(subject.class).to receive(:delay).with(
            max_attempts: subject.class.max_attempts,
            priority: Delayed::LOW_PRIORITY,
            attempts: attempt_number,
            run_at: time + (attempt_number**4) + 5
          ).and_return(mock)
          expect(mock).to receive(:new_submission)
          Timecop.freeze(time) do
            subject.process
          end
        end
      end

      context "when it is the last attempt" do
        before do
          response_response = double("response_mock")
          allow(response_response).to receive(:body).and_return(tii_response)
          allow(subject.turnitin_client).to receive(:response).and_return(response_response)
          allow(subject.class).to receive(:max_attempts).and_return(1)
        end

        shared_examples_for "an error occurring when fetching the submission" do
          def process
            expect { subject.process }.to raise_error(error)
          end

          let(:sub) { lti_assignment.submissions.first }

          it "creates an attachment" do
            process
            attachment = lti_assignment.attachments.first
            expect(lti_assignment.attachments.count).to eq 1
            expect(attachment.display_name).to eq "Failed turnitin submission"
          end

          it "creates a submission if we got an uploaded at" do
            process
            expect(sub.workflow_state).to eq("submitted")
            expect(sub.submitted_at).to_not be_nil
            expect(sub.submitted_at).to eq(subject.turnitin_client.uploaded_at)
            expect(sub.turnitin_data).to eq(
              "attachment_#{lti_assignment.attachments.first.id}" => {
                status: "error",
                public_error_message: "Turnitin has not returned a submission after 1 attempts to retrieve one."
              }
            )
          end

          it "creates an attachment but no submission if we got a response w/o date_uploaded" do
            tii_response["meta"].delete "date_uploaded"
            process
            expect(sub.workflow_state).to eq("unsubmitted")
            expect(sub.turnitin_data).to be_blank
            expect(lti_assignment.attachments.count).to eq 1
            expect(lti_assignment.attachments.first.display_name).to eq "Failed turnitin submission"
          end
        end

        context "when getting a Errors::OriginalSubmissionUnavailableError" do
          let(:error) { Errors::OriginalSubmissionUnavailableError }

          before do
            original_submission_response = double("original_submission_mock")
            allow(original_submission_response).to receive_messages(headers: {}, status: 403)
            allow(subject.turnitin_client).to receive(:original_submission).and_yield(original_submission_response)
          end

          it_behaves_like "an error occurring when fetching the submission"

          it "creates an Attachment with the status code in the text" do
            orig_method = lti_assignment.attachments.method(:create!)
            expect(lti_assignment.attachments).to receive(:create!) do |opts|
              data = opts[:uploaded_data]
              expect(data.read).to match(/Status code: 403/)
              data.rewind
              orig_method.call(opts)
            end
            expect { subject.process }.to raise_error(error)
          end
        end

        context "when getting a Faraday::TimeoutError" do
          let(:error) { Faraday::TimeoutError.new("Net::ReadTimeout") }

          before do
            allow(subject.turnitin_client).to receive(:original_submission).and_raise(error)
          end

          it_behaves_like "an error occurring when fetching the submission"
        end

        context "when the error is Errno::ETIMEDOUT" do
          let(:error) { Errno::ETIMEDOUT.new('Connection timed out - connect(2) for "api.turnitin.com" port 443') }

          before do
            allow(subject.turnitin_client).to receive(:original_submission).and_raise(error)
          end

          it_behaves_like "an error occurring when fetching the submission"
        end

        context "when the error is Faraday::ConnectionFailed" do
          let(:error) { Faraday::ConnectionFailed.new('Connection timed out - connect(2) for "api.turnitin.com" port 443') }

          before do
            allow(subject.turnitin_client).to receive(:original_submission).and_raise(error)
          end

          it_behaves_like "an error occurring when fetching the submission"
        end
      end
    end

    describe "#update_originality_data" do
      it "raises an error and sends stat if max attempts are not exceeded" do
        allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts - 1)
        allow(InstStatsd::Statsd).to receive(:increment)
        mock_turnitin_client = double("turnitin_client")
        allow(mock_turnitin_client).to receive(:scored?).and_return(false)
        allow(subject).to receive(:turnitin_client).and_return(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments: [attachment], submission_type: "online_upload")
        expect do
          subject.update_originality_data(submission, attachment.asset_string)
        end.to raise_error Turnitin::Errors::SubmissionNotScoredError
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with(
            "submission_not_scored.account_#{lti_assignment.root_account.global_id}",
            short_stat: "submission_not_scored",
            tags: { root_account_id: lti_assignment.root_account.global_id }
          ).once
      end

      it "sets an error message if max attempts are exceeded" do
        allow_any_instance_of(subject.class).to receive(:attempt_number).and_return(subject.class.max_attempts)
        mock_turnitin_client = double("turnitin_client")
        allow(mock_turnitin_client).to receive(:scored?).and_return(false)
        allow(subject).to receive(:turnitin_client).and_return(mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments: [attachment], submission_type: "online_upload")
        subject.update_originality_data(submission, attachment.asset_string)
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq "error"
        expect(submission.turnitin_data[attachment.asset_string][:public_error_message]).to start_with "Turnitin has not"
      end
    end

    describe "#resubmit" do
      it "doesn't serialize the whole TII client" do
        expect(subject.turnitin_client).to_not be_nil
        submission = Submission.new(id: 1)
        subject.resubmit(submission, "asset_string")
        output_job = Delayed::Job.where(tag: "Turnitin::OutcomeResponseProcessor#update_originality_data").last
        expect(output_job.handler).to_not include("ruby/object:Turnitin::TiiClient")
      end
    end
  end
end
