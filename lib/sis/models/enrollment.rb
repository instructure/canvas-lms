module SIS
  module Models
    class Enrollment
      attr_accessor :course_id, :section_id, :user_id, :user_integration_id,
                    :role, :status, :associated_user_id, :root_account_id,
                    :role_id, :start_date, :end_date, :sis_batch_id,
                    :limit_section_privileges

      def initialize(opts = {})
        self.course_id = opts[:course_id]
        self.section_id = opts[:section_id]
        self.user_id = opts[:user_id]
        self.user_integration_id = opts[:user_integration_id]
        self.role = opts[:role]
        self.status = opts[:status]
        self.associated_user_id = opts[:associated_user_id]
        self.root_account_id = opts[:root_account_id]
        self.role_id = opts[:role_id]
        self.limit_section_privileges = opts[:limit_section_privileges]
        self.start_date = opts[:start_date]
        self.end_date = opts[:end_date]
        # adding sis_batch_id here for plugins that are not going through
        # the initialize of enrollment_importer
        self.sis_batch_id = opts[:sis_batch_id]
      end

      def valid_context?
        !course_id.blank? || !section_id.blank?
      end

      def valid_user?
        !user_id.blank? || !user_integration_id.blank?
      end

      def valid_status?
        status =~ /\Aactive|\Adeleted|\Acompleted|\Ainactive/i
      end

      def to_a
        [course_id.to_s, section_id.to_s, user_id.to_s, role, role_id, status, start_date, end_date, associated_user_id, root_account_id]
      end
    end
  end
end


