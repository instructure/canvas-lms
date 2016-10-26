module SupportHelpers
  module Crocodoc
    class CrocodocFixer < Fixer
      attr_reader :attempted_resubmit

      BAD_STATES = ["ERROR", nil].freeze

      def initialize(email, after_time = nil)
        @attempted_resubmit = 0
        @prefix = "Crocodoc"
        super(email, after_time)
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
        scope = Attachment.joins(:crocodoc_document).
          preload(:crocodoc_document).
          where(crocodoc_documents: { process_state: BAD_STATES }).
          where(CREATED_FIELD.gt(@after_time))

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
        submission = Submission.preload(attachment: :crocodoc_document).
          where(assignment_id: @assignment_id, user_id: @user_id).first
        if submission
          attachments = submission.attachments.select do |a|
            BAD_STATES.include?(a.crocodoc_document.process_state)
          end
          attachments.each { |a| resubmit_attachment(a) }
        end
      end
    end
  end
end
