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

module Services
  class SubmitHomeworkService
    EmailWorker = Struct.new(:message) do
      def perform
        Mailer.deliver(Mailer.create_message(message))
      end

      def on_permanent_failure(error)
        Canvas::Errors.capture_exception(self.class.name, error)
      end
    end

    CloneUrlExecutor = Struct.new(:url, :duplicate_handling, :check_quota, :opts) do
      def execute(attachment)
        attachment.clone_url(url, duplicate_handling, check_quota, opts)
      end
    end

    SubmitWorker = Struct.new(:progress_id, :attachment_id, :eula_agreement_timestamp, :clone_url_executor) do
      def progress
        @progress ||= Progress.find(progress_id)
      end

      def attachment
        @attachment ||= Attachment.find(attachment_id)
      end

      def perform
        progress.start
        assignment = progress.context
        clone_url_executor.execute(attachment)
        SubmitHomeworkService.submit(attachment, assignment, progress.created_at, eula_agreement_timestamp)
        progress.complete
        SubmitHomeworkService.successful_email(attachment, assignment)
      rescue => error
        mark_as_failure(error)
      end

      def on_permanent_failure(error)
        mark_as_failure(error)
      end

      private

      def mark_as_failure(error)
        error_id = Canvas::Errors.capture_exception(self.class.name, error)[:error_report]
        progress.message = "Unexpected error, ID: #{error_id || 'unknown'}"
        progress.save
        progress.fail
        SubmitHomeworkService.failure_email(attachment, attachment.context)
      end
    end

    class << self
      def create_clone_url_executor(url, duplicate_handling, check_quota, opts)
        CloneUrlExecutor.new(url, duplicate_handling, check_quota, opts)
      end

      def submit_job(progress, attachment, eula_agreement_timestamp, clone_url_executor)
        SubmitWorker.new(progress.id, attachment.id, eula_agreement_timestamp, clone_url_executor).
          tap do |worker|
            Delayed::Job.enqueue(worker, n_strand: 'file_download')
          end
      end

      def submit(attachment, assignment, submitted_at, eula_agreement_timestamp)
        opts = {
          submission_type: 'online_upload',
          submitted_at: submitted_at,
          attachments: [attachment],
          eula_agreement_timestamp: eula_agreement_timestamp
        }

        assignment.submit_homework(attachment.user, opts)
      end

      def successful_email(attachment, assignment)
        body = "Your file, #{attachment.display_name}, has been successfully "\
               "uploaded to your Canvas assignment, #{assignment.name}"
        user_email = User.find(attachment.user_id).email

        message = OpenStruct.new(
          from_name: 'notifications@instructure.com',
          subject: "Submission upload successful: #{assignment.name}",
          to: user_email,
          body: body
        )
        deliver_email(message)
      end

      def failure_email(attachment, assignment)
        body = "Your file, #{attachment.display_name}, failed to upload to your "\
               "Canvas assignment, #{assignment.name}. Please re-submit to "\
               "the assignment or contact your instructor if you are no "\
               "longer able to do so."
        user_email = User.where(id: attachment.user_id).first.email

        message = OpenStruct.new(
          from_name: 'notifications@instructure.com',
          subject: "Submission upload failed: #{assignment.name}",
          to: user_email,
          body: body
        )
        deliver_email(message)
      end

      def deliver_email(message)
        Delayed::Job.enqueue(EmailWorker.new(message))
      end
    end
  end
end
