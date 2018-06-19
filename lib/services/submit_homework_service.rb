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

    EmailJob = Struct.new(:message) do
      def perform
        Mailer.deliver(Mailer.create_message(message))
      end
    end

    class << self
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
        Delayed::Job.enqueue(EmailJob.new(message))
      end
    end
  end
end
