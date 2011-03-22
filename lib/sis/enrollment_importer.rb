#
# Copyright (C) 2011 Instructure, Inc.
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

module SIS
  class EnrollmentImporter < SisImporter

    def self.is_enrollment_csv?(row)
      row.header?('course_id') and row.header?('user_id')
    end

    def verify(csv, verify)
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        add_error(csv, "No course_id or section_id given for an enrollment") if row['course_id'].blank? && row['section_id'].blank?
        add_error(csv, "No user_id given for an enrollment") if row['user_id'].blank?
        add_error(csv, "Improper role \"#{row['role']}\" for an enrollment") unless row['role'] =~ /\Astudent|\Ateacher|\Ata|\Aobserver|\Adesigner/i
        add_error(csv, "Improper status \"#{row['status']}\" for an enrollment") unless row['status'] =~ /\Aactive|\Adeleted|\Acompleted|\Ainactive/i
      end
    end

    # expected columns
    # course_id,user_id,role,section_id,status
    def process(csv)
      start = Time.now
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        logger.debug("Processing Enrollment #{row.inspect}")
        update_progress
        pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, row['user_id'])
        user = pseudo.user rescue nil
        course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, row['course_id'])
        section = CourseSection.find_by_root_account_id_and_sis_source_id(@root_account.id, row['section_id'])
        unless user && (course || section)
          add_warning csv, "Neither course #{row['course_id']} nor section #{row['section_id']} existed for user enrollment" unless (course || section)
          add_warning csv, "User #{row['user_id']} didn't exist for user enrollment" unless user
          next
        end

        if row['section_id'] && !section
          add_warning csv, "An enrollment referenced a non-existent section #{row['section_id']}"
          next
        end

        if row['course_id'] && !course
          add_warning csv, "An enrollment referenced a non-existent course #{row['course_id']}"
          next
        end

        unless section
          section = course.course_sections.find_by_sis_source_id(row['section_id'])
          section ||= course.default_section
        end

        course ||= section.course

        if course != section.course
          add_warning csv, "An enrollment listed a section and a course that are unrelated"
          next
        end

        enrollment = section.enrollments.find_by_user_id(user.id)
        unless enrollment
          enrollment = Enrollment.new
          enrollment.course_id = course.id
          enrollment.user_id = user.id
          enrollment.root_account_id = @root_account.id
        end
        enrollment.sis_batch_id = @batch.id if @batch
        enrollment.sis_source_id = [row['course_id'], row['user_id'], row['role'], section.name].compact.join(":")

        enrollment.course_id = course.id
        enrollment.course_section_id = section.id
        if row['role'] =~ /\Ateacher\z/i
          enrollment.type = 'TeacherEnrollment'
        elsif row['role'] =~ /student/i
          enrollment.type = 'StudentEnrollment'
        elsif row['role'] =~ /\Ata\z|assistant/i
          enrollment.type = 'TaEnrollment'
        elsif row['role'] =~ /\Aobserver\z/i
          enrollment.type = 'ObserverEnrollment'
          if row['associated_user_id']
            pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, row['associated_user_id'])
            associated_enrollment = pseudo && course.student_enrollments.find_by_user_id(pseudo.user_id)
            enrollment.associated_user_id = associated_enrollment && associated_enrollment.user_id
          end
        elsif row['role'] =~ /\Adesigner\z/i
          enrollment.type = 'DesignerEnrollment'
        end

        # special-case status that bases the enrollment state
        # off of availability dates instead of explicitly setting it.
        if row['status']=~ /active_if_available/i
          row['status'] = course.enrollment_state_based_on_date(enrollment)
        end  
        
        if row['status']=~ /active/i
          if user.workflow_state != 'deleted'
            enrollment.workflow_state = 'active'
          else
            enrollment.workflow_state = 'deleted'
            add_warning csv, "Attempted enrolling of deleted user #{row['user_id']} in course #{row['course_id']}"
          end
        elsif  row['status']=~ /deleted/i
          enrollment.workflow_state = 'deleted'
        elsif  row['status']=~ /completed/i
          enrollment.workflow_state = 'completed'
        elsif  row['status']=~ /inactive/i
          enrollment.workflow_state = 'inactive'
        end

        enrollment.save_without_broadcasting
        @sis.counts[:enrollments] += 1
      end
      logger.debug("Enrollments took #{Time.now - start} seconds")
    end
  end
end
