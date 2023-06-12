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

module Services
  class SubmitHomeworkService
    CloneUrlError = Class.new(StandardError)

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

    CopyWorker = Struct.new(:attachment_id, :progress_id, :clone_url_executor) do
      def progress
        @progress ||= Progress.find(progress_id)
      end

      def attachment
        @attachment ||= Attachment.find(attachment_id)
      end

      def perform
        progress.start! unless progress.running?
        clone_url_executor.execute(attachment)

        raise(CloneUrlError, attachment.upload_error_message) if attachment.file_state == "errored"

        progress.complete! unless progress.failed?
      rescue => e
        mark_as_failure(e)
      end

      def on_permanent_failure(error)
        mark_as_failure(error)
      end

      private

      def mark_as_failure(error)
        Canvas::Errors.capture_exception(self.class.name, error)[:error_report]
        progress.message = error
        progress.save!
        progress.fail!
      end
    end

    SubmitWorker = Struct.new(:attachment_id, :progress_id, :eula_agreement_timestamp, :comment, :clone_url_executor) do
      def progress
        @progress ||= Progress.find(progress_id)
      end

      def attachment
        @attachment ||= Attachment.find(attachment_id)
      end

      def homework_service
        @homework_service ||= SubmitHomeworkService.new(attachment, progress)
      end

      def perform
        return unless attachment

        homework_service.start!
        clone_url_executor.execute(attachment)

        raise(CloneUrlError, attachment.upload_error_message) if attachment.file_state == "errored"

        homework_service.submit(eula_agreement_timestamp, comment)
        homework_service.success!
      rescue => e
        mark_as_failure(e)
      end

      def on_permanent_failure(error)
        mark_as_failure(error)
      end

      private

      def mark_as_failure(error)
        homework_service.failed!(error)
      end
    end

    class << self
      def create_clone_url_executor(url, duplicate_handling, check_quota, opts)
        CloneUrlExecutor.new(url, duplicate_handling, check_quota, opts)
      end

      def submit_job(attachment, progress, eula_agreement_timestamp, comment, executor, submit_assignment)
        if progress.context.is_a?(Assignment) && submit_assignment
          SubmitWorker
            .new(attachment.id, progress.id, eula_agreement_timestamp, comment, executor)
            .tap { |worker| enqueue_attachment_job(worker) }
        else
          CopyWorker
            .new(attachment.id, progress.id, executor)
            .tap { |worker| enqueue_attachment_job(worker) }
        end
      end

      def enqueue_attachment_job(worker)
        Delayed::Job.enqueue(
          worker,
          priority: Delayed::HIGH_PRIORITY,
          n_strand: Attachment.clone_url_strand(worker.clone_url_executor.url)
        )
      end
    end

    def initialize(attachment, progress)
      @attachment = attachment
      @progress = progress
    end

    def submit(eula_agreement_timestamp, comment)
      start!

      if @attachment
        opts = {
          submission_type: "online_upload",
          submitted_at: @progress.created_at,
          attachments: [@attachment],
          eula_agreement_timestamp:,
          comment:
        }

        @progress.context.submit_homework(@progress.user, opts)
      end
    end

    def start!
      progress_start!(@progress)
      AttachmentUploadStatus.pending!(@attachment)
    end

    def success!
      progress_success!(@progress, @attachment)
      AttachmentUploadStatus.success!(@attachment)
    end

    def failed!(error)
      progress_failed!(@progress, error)
      AttachmentUploadStatus.failed!(@attachment, error)
      failure_email if @attachment
    end

    def failure_email
      display_name = @attachment.display_name
      assignment_name = @progress.context.name
      body = "Your file, #{display_name}, failed to upload to your " \
             "Canvas assignment, #{assignment_name}. Please re-submit to " \
             "the assignment or contact your instructor if you are no " \
             "longer able to do so."

      message = OpenStruct.new(
        from_name: "notifications@instructure.com",
        subject: "Submission upload failed: #{assignment_name}",
        to: @progress.user.email,
        body:
      )
      queue_email(message)
    end

    private

    def progress_start!(progress)
      unless progress.running?
        progress.start
        progress.save!
      end
    end

    def progress_success!(progress, attachment)
      progress.reload
      progress.set_results("id" => attachment.id) if attachment
      progress.complete!
    end

    def progress_failed!(progress, message)
      progress.reload
      progress.message = message
      progress.save!
      progress.fail
    end

    def queue_email(message)
      Delayed::Job.enqueue(EmailWorker.new(message))
    end
  end
end
