module SupportHelpers
  module Tii
    class TiiFixer < Fixer

      def initialize(email, after_time = nil)
        @buffer_time = Time.now - 1.hour
        @prefix = "TurnItIn"
        super(email, after_time)
      end

      def success_message
        "#{fixer_name} fixed #{prettify_broken_count} in #{elapsed_time} seconds!"
      end

      def broken_objects
        @broken_objects ||= Shackles.activate(:slave) { load_broken_objects }
      end

      private

      def broken_count
        @count ||= broken_objects.count
      end

      def prettify_broken_count
        "#{broken_count} #{object_type.name.downcase.pluralize(broken_count)}"
      end

      def like_error
        "turnitin_data LIKE '%error%'".freeze
      end

      def object_type
        Submission
      end

      def updated_field
        object_type.arel_table[:updated_at]
      end

      def load_broken_objects
        raise "#{self.class.name} must implement #load_broken_objects"
      end
    end

    class Error2305Fixer < TiiFixer
      def fix
        broken_objects.each { |a| AssignmentFixer.new(@email, @after_time, a).fix(fix_type_needed) }
      end

      private

      def fix_type_needed
        :assignment_fix
      end

      def like_error
        "turnitin_settings LIKE '%2305%'".freeze
      end

      def object_type
        Assignment
      end

      def load_broken_objects
        Assignment.where(updated_field.gt(@after_time)).where(like_error).pluck(:id)
      end
    end

    class MD5Fixer < Error2305Fixer

      private

      def fix_type_needed
        :md5_fix
      end

      def like_error
        "turnitin_settings LIKE '%MD5 not authenticated%'".freeze
      end
    end

    class ShardFixer < TiiFixer
      def fix
        broken_objects.each { |a| AssignmentFixer.new(@email, @after_time, a).fix }
      end

      private

      def load_broken_objects
        # By selecting only the id, we delay the full load until we're
        # ready to actually work on the assignment.  Lots of little
        # loads than one giant one.
        Assignment.joins(:submissions)
          .where(updated_field.gt(@after_time))
          .where(updated_field.lt(@buffer_time))
          .where("submissions.#{like_error}")
          .uniq.pluck(:id)
      end

      def object_type
        Assignment
      end

      def updated_field
        Submission.arel_table[:updated_at]
      end
    end

    class LtiAttachmentFixer < TiiFixer
      def initialize(email, after_time, submission_id, attachment_id)
        @submission = Submission.find(submission_id)
        @attachment = Attachment.find(attachment_id)
        super(email, after_time)
      end

      def fix
        Turnitin::AttachmentManager.update_attachment(@submission, @attachment)
      end

      private

      def load_broken_objects
        [@submission]
      end

    end

    class AssignmentFixer < TiiFixer
      def initialize(email, after_time, assignment_id)
        @assignment = Assignment.find(assignment_id)
        super(email, after_time)
      end

      def fix(fix_type = fix_type_needed)
        return if @assignment.context.turnitin_settings.nil?

        case fix_type
        when :no_fix
          return
        when :course_fix
          create_course
          create_assignment
        when :assignment_fix
          create_assignment
        when :assignment_exists_fix
          update_assignment
        when :md5_fix
          save_assignment
        end

        resubmit_submissions
      end

      private

      def load_broken_objects
        # Non-broken sumissions CAN have turnitin_data that has the
        # word error in them that aren't a top level error that we're
        # looking for. There aren't a lot, but we'll select them out here.
        @assignment.submissions.where(updated_field.gt(@after_time))
                               .where(updated_field.lt(@buffer_time))
                               .where(like_error).select { |s| is_bad_submission?(s) }
      end

      def is_bad_submission?(s)
        s.turnitin_data[:status] == "error" || s.turnitin_data.values.any? do |v|
          v.is_a?(Hash) && v[:error_code] == 206
        end
      end

      def fix_type_needed
        # All the submissions will be broken the same way, so how the
        # first is broken is good enough to proceed.
        tii = broken_objects.first.try(:turnitin_data)
        return :no_fix unless tii

        if tii[:student_error].try(:[], :error_code) == 204
          :course_fix
        elsif tii[:student_error].try(:[], :error_code) == 216
          :resubmit_fix
        elsif tii[:assignment_error].try(:[], :error_code) == 206
          :assignment_fix
        elsif tii[:assignment_error].try(:[], :error_code) == 419
          :assignment_exists_fix
        elsif tii.values.any? { |v| v.is_a?(Hash) && v[:error_code] == 206 }
          :assignment_fix
        else
          :no_fix
        end
      end

      def turnitin_client
        @turnitin ||= Turnitin::Client.new(*@assignment.context.turnitin_settings)
      end

      def create_course
        turnitin_client.createCourse(@assignment.context)
      end

      def create_assignment
        @assignment.turnitin_settings.delete(:created)
        @assignment.turnitin_settings.delete(:current)
        @assignment.save

        save_assignment(:create)
      end

      def update_assignment
        @assignment.turnitin_settings[:created] = true
        @assignment.save

        save_assignment(:update)
      end

      def save_assignment(save_reason = nil)
        res = turnitin_client.createOrUpdateAssignment(@assignment, @assignment.turnitin_settings)
        if res[:assignment_id]
          @assignment.turnitin_settings[:created] = true
          @assignment.turnitin_settings[:current] = true
          @assignment.turnitin_settings.delete(:error)
          @assignment.save
        elsif res[:error_code] == 206 && save_reason == :update
          create_assignment
        elsif res[:error_code] == 419 && save_reason == :create
          update_assignment
        else
          raise "assignment #{@assignment.id} is still broken: #{res}"
        end
      end

      def resubmit_submissions
        broken_objects.each do |b|
          b.resubmit_to_turnitin
          sleep 3 if Rails.env.production? # TII's API can't keep up if we don't slow down
        end
      end
    end

    class StuckInPendingFixer < TiiFixer
      def fix
        broken_objects.each do |s|
          Submission.find(s).resubmit_to_turnitin
          sleep 3 if Rails.env.production? # TII's API can't keep up if we don't slow down
        end

        stuck_with_object_ids.each do |s|
          Submission.find(s).check_turnitin_status
          sleep 2 if Rails.env.production? # TII's API can't keep up if we don't slow down
        end
      end

      private

      def like_error
        "turnitin_data LIKE '--- \n:last_processed_attempt: _\n' OR turnitin_data LIKE '--- \n:last_processed_attempt: _\nattachment_________: \n  :status: pending\n'".freeze
      end

      def load_broken_objects
        Submission.where(updated_field.gt(@after_time))
                  .where(updated_field.lt(@buffer_time))
                  .where(like_error)
                  .pluck(:id)
      end

      def stuck_with_object_ids
        # These should be able to just have "check status" called on them.
        Submission.where(updated_field.gt(@after_time))
                  .where(updated_field.lt(@buffer_time))
                  .where("turnitin_data LIKE '--- \n:last_processed_attempt: _\nattachment_________: \n  :status: pending\n  :object_id: \"_________\"\n'")
                  .pluck(:id)
      end
    end

    class ExpiredAccountFixer < StuckInPendingFixer

      private

      def stuck_with_object_ids
        []
      end

      def like_error
        'turnitin_data LIKE E\'%:status: pending\n:status: error\n:assignment_error: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  error_code: 217%\''.freeze
      end
    end
  end
end
