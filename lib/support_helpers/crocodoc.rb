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

module SupportHelpers
  module Crocodoc
    class CrocodocFixer < Fixer
      attr_reader :attempted_resubmit

      BAD_STATES = ["ERROR", nil].freeze

      def initialize(email, after_time = nil)
        @attempted_resubmit = 0
        @prefix = "Crocodoc"
        super
      end

      def resubmit_attachment(a)
        cd = a.crocodoc_document
        cd.update_attribute(:uuid, nil)
        a.submit_to_crocodoc
        @attempted_resubmit += 1
        sleep 3 if Rails.env.production?
      end

      private

      def success_message
        "#{fixer_name} resubmitted #{@attempted_resubmit} documents in #{elapsed_time} seconds!"
      end
    end

    class ShardFixer < CrocodocFixer
      CREATED_FIELD = CrocodocDocument.arel_table[:created_at]

      def fix
        scope = Attachment.joins(:crocodoc_document)
                          .preload(:crocodoc_document)
                          .where(crocodoc_documents: { process_state: BAD_STATES })
                          .where(CREATED_FIELD.gt(@after_time))

        scope.find_each { |a| resubmit_attachment(a) }
      end
    end

    class SubmissionFixer < CrocodocFixer
      def initialize(email, after_time, assignment_id, user_id)
        @assignment_id = assignment_id
        @user_id = user_id
        super(email, after_time)
      end

      def fix
        submission = Submission.preload(attachment: :crocodoc_document)
                               .where(assignment_id: @assignment_id, user_id: @user_id).first
        if submission
          attachments = submission.attachments.select do |a|
            BAD_STATES.include?(a.crocodoc_document.process_state) ||
              a.crocodoc_document.process_state == "QUEUED" ||
              (a.crocodoc_document.process_state == "PROCESSING" && a.crocodoc_document.updated_at < 1.day.ago)
          end
          attachments.each { |a| resubmit_attachment(a) }
        end
      end
    end
  end
end
