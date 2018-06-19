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
require 'spec_helper.rb'
require_dependency 'services/submit_homework_service'

module Services
  describe SubmitHomeworkService do
    let(:user) { user_factory }
    let(:assignment) { assignment_model }
    let(:attachment) do
      attachment_model(
        context: assignment,
        user: user,
        filename: 'Some File'
      )
    end
    let(:submitted_at) { Time.zone.now }
    let(:successful_email) do
      OpenStruct.new(
        from_name: 'notifications@instructure.com',
        subject: "Submission upload successful: #{assignment.name}",
        to: user.email,
        body: "Your file, #{attachment.display_name}, has been successfully "\
              "uploaded to your Canvas assignment, #{assignment.name}"
      )
    end
    let(:failure_email) do
      OpenStruct.new(
        from_name: 'notifications@instructure.com',
        subject: "Submission upload failed: #{assignment.name}",
        to: user.email,
        body: "Your file, #{attachment.display_name}, failed to upload to your "\
              "Canvas assignment, #{assignment.name}. Please re-submit to "\
              "the assignment or contact your instructor if you are no "\
              "longer able to do so."
      )
    end
    let(:eula_agreement_timestamp) { "1522419910" }

    describe '#submit' do
      let(:submission) { described_class.submit(attachment, assignment, submitted_at, eula_agreement_timestamp) }

      it 'should set submitted_at to the Progress#created_at' do
        expect(submission.submitted_at).to eq submitted_at
      end

      it 'should set attachments for the submission' do
        expect(submission.attachments).to eq [attachment]
      end

      it 'should set assignment for the submission' do
        expect(submission.assignment).to eq assignment
      end
    end

    context 'sending an email' do
      let(:email_job) { Delayed::Job.last }

      describe '#successful_email' do
        it 'enqueues a successful email' do
          described_class.successful_email(attachment, assignment)
          expect(email_job.handler).to match(/#{described_class::EmailJob.name}/)
          expect(Mailer).to receive(:deliver).with(Mailer.create_message(successful_email))
          email_job.invoke_job
        end
      end

      describe '#failure_email' do
        it 'enqueues a failure email' do
          described_class.failure_email(attachment, assignment)
          expect(email_job.handler).to match(/#{described_class::EmailJob.name}/)
          expect(Mailer).to receive(:deliver).with(Mailer.create_message(failure_email))
          email_job.invoke_job
        end
      end
    end
  end
end
