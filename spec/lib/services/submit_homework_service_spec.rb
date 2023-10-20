# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require "spec_helper"

module Services
  describe SubmitHomeworkService do
    subject { described_class.new(attachment, progress) }

    let(:submission) { submission_model }
    let(:assignment) { submission.assignment }
    let(:progress) { Progress.create!(context: assignment, user:, tag: "test") }
    let(:user) { user_factory }
    let(:attachment) do
      attachment_model(
        context: assignment,
        user:,
        filename: "Some File"
      )
    end
    let(:submit_assignment) { true }
    let(:failure_email) do
      OpenStruct.new(
        from_name: "notifications@instructure.com",
        subject: "Submission upload failed: #{assignment.name}",
        to: user.email,
        body: "Your file, #{attachment.display_name}, failed to upload to your " \
              "Canvas assignment, #{assignment.name}. Please re-submit to " \
              "the assignment or contact your instructor if you are no " \
              "longer able to do so."
      )
    end
    let(:eula_agreement_timestamp) { "1522419910" }
    let(:comment) { "what a comment" }
    let(:url) { "url" }
    let(:dup_handling) { false }
    let(:check_quota) { false }
    let(:opts) { { fancy: "very" } }
    let(:executor) do
      described_class.create_clone_url_executor(url, dup_handling, check_quota, opts)
    end

    describe ".create_clone_url_executor" do
      it "sets the url" do
        expect(executor.url).to eq url
      end

      it "sets the duplicate_handling" do
        expect(executor.duplicate_handling).to eq dup_handling
      end

      it "sets the check_quota" do
        expect(executor.check_quota).to eq check_quota
      end

      it "sets the opts" do
        expect(executor.opts).to eq opts
      end
    end

    describe ".submit_job" do
      let(:service) { described_class.new(attachment, progress) }
      let(:worker) do
        described_class.submit_job(attachment, progress, eula_agreement_timestamp, comment, executor, submit_assignment)
      end

      before do
        allow(worker).to receive_messages(homework_service: service, attachment:)
      end

      it "clones and submit the url when submit_assignment is true" do
        expect(attachment).to receive(:clone_url).with(url, dup_handling, check_quota, opts)
        expect(service).to receive(:submit).with(eula_agreement_timestamp, comment)
        worker.perform

        expect(progress.reload.workflow_state).to eq "completed"
      end

      it "clones and not submit the url when submit_assignment is false" do
        worker = described_class.submit_job(attachment, progress, eula_agreement_timestamp, comment, executor, false)
        allow(worker).to receive_messages(homework_service: service, attachment:)
        expect(attachment).to receive(:clone_url).with(url, dup_handling, check_quota, opts)
        expect(service).not_to receive(:submit)
        worker.perform

        expect(progress.reload.workflow_state).to eq "completed"
      end

      context "on an error" do
        before { worker.on_permanent_failure("error") }

        it "marks progress as failed" do
          latest_progress = progress.reload
          expect(latest_progress.workflow_state).to eq "failed"
          expect(latest_progress.message).to eq "error"
        end

        it "creates an AttachmentUploadStatus" do
          failure = AttachmentUploadStatus.find_by(attachment:)
          expect(failure.error).to eq "error"
          expect(AttachmentUploadStatus.upload_status(attachment)).to eq "failed"
        end

        it "sends a failure email" do
          email_job = Delayed::Job.order(:id).last
          expect(email_job.handler).to match(/#{described_class::EmailWorker.name}/)
          expect(Mailer).to receive(:deliver).with(Mailer.create_message(failure_email))
          email_job.invoke_job
        end
      end

      context "queues up a delayed job" do
        let(:worker_job) { Delayed::Job.order(:id).last }

        it "enqueues the worker job" do
          expect(worker_job.handler).to include described_class::SubmitWorker.name
        end
      end
    end

    describe "#submit" do
      let(:submitted) { subject.submit(eula_agreement_timestamp, comment) }
      let(:recent_assignment) { assignment.reload }

      it "sets submitted_at to the Progress#created_at" do
        expect(submitted.submitted_at).to eq progress.created_at
      end

      it "sets attachments for the submission" do
        expect(submitted.attachments).to eq [attachment]
      end

      it "sets assignment for the submission" do
        expect(submitted.assignment).to eq recent_assignment
      end

      it "submits with the comment" do
        expect(submitted.submission_comments.first.comment).to eq(comment)
      end

      it "is a successful upload" do
        submitted
        expect(AttachmentUploadStatus.upload_status(attachment)).to eq "success"
      end
    end

    context "sending an email" do
      let(:email_job) { Delayed::Job.last }

      describe "#failure_email" do
        it "enqueues a failure email" do
          subject.failure_email
          expect(email_job.handler).to match(/#{described_class::EmailWorker.name}/)
          expect(Mailer).to receive(:deliver).with(Mailer.create_message(failure_email))
          email_job.invoke_job
        end
      end
    end
  end
end
