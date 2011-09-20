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

require "skip_callback"

module SIS
  class CourseImporter < SisImporter
    
    def self.is_course_csv?(row)
      row.header?('course_id') && row.header?('short_name')
    end
    
    def verify(csv, verify)
      course_ids = (verify[:course_ids] ||= {})
      csv_rows(csv) do |row|
        course_id = row['course_id']
        add_error(csv, "Duplicate course id #{course_id}") if course_ids[course_id]
        course_ids[course_id] = true
        add_error(csv, "No course_id given for a course") if row['course_id'].blank?
        add_error(csv, "No short_name given for course #{course_id}") if row['short_name'].blank? && row['abstract_course_id'].blank?
        add_error(csv, "No long_name given for course #{course_id}") if row['long_name'].blank? && row['abstract_course_id'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for course #{course_id}") unless row['status'] =~ /\Aactive|\Adeleted|\Acompleted/i
      end
    end
    
    # expected columns
    # course_id,short_name,long_name,account_id,term_id,status
    def process(csv)
      start = Time.now
      courses_to_update_sis_batch_id = []
      course_ids_to_update_associations = [].to_set

      Course.skip_callback(:update_enrollments_later) do
        csv_rows(csv) do |row|
          update_progress

          Course.skip_updating_account_associations do

            logger.debug("Processing Course #{row.inspect}")
            term = @root_account.enrollment_terms.find_by_sis_source_id(row['term_id'])
            course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, row['course_id'])
            course ||= Course.new
            course.enrollment_term = term if term
            course.root_account = @root_account

            account = nil
            account = Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['account_id']) if row['account_id'].present?
            account ||= Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['fallback_account_id']) if row['fallback_account_id'].present?
            course.account = account if account
            course.account ||= @root_account

            update_account_associations = course.account_id_changed? || course.root_account_id_changed?

            course.sis_source_id = row['course_id']
            if row['status'] =~ /active/i
              if course.workflow_state == 'completed'
                course.workflow_state = 'available'
              elsif course.workflow_state != 'available'
                course.workflow_state = 'claimed'
              end
            elsif row['status'] =~ /deleted/i
              course.workflow_state = 'deleted'
            elsif row['status'] =~ /completed/i
              course.workflow_state = 'completed'
            end

            begin
              course.start_at = row['start_date'].blank? ? nil : DateTime.parse(row['start_date'])
              course.conclude_at = row['end_date'].blank? ? nil : DateTime.parse(row['end_date'])
            rescue
              add_warning(csv, "Bad date format for course #{row['course_id']}")
            end
            course.restrict_enrollments_to_course_dates = (course.start_at.present? || course.conclude_at.present?)

            abstract_course = nil
            if row['abstract_course_id'].present? 
              abstract_course = AbstractCourse.find_by_root_account_id_and_sis_source_id(@root_account.id, row['abstract_course_id'])
              add_warning(csv, "unknown abstract course id #{row['abstract_course_id']}, ignoring abstract course reference") unless abstract_course
            end

            if abstract_course
              if row['term_id'].blank? && course.enrollment_term_id != abstract_course.enrollment_term
                course.send(:association_instance_set, :enrollment_term, nil)
                course.enrollment_term_id = abstract_course.enrollment_term_id
              end
              if row['account_id'].blank? && course.account_id != abstract_course.account_id
                course.send(:association_instance_set, :account, nil)
                course.account_id = abstract_course.account_id
              end
            end
            course.abstract_course = abstract_course

            # only update the name/short_name on new records, and ones that haven't been changed
            # since the last sis import
            if course.short_name.blank? || course.sis_course_code == course.short_name
              if row['short_name'].present?
                course.short_name = course.sis_course_code = row['short_name']
              elsif abstract_course && course.short_name.blank?
                course.short_name = course.sis_course_code = abstract_course.short_name
              end
            end
            if course.name.blank? || course.sis_name == course.name
              if row['long_name'].present?
                course.name = course.sis_name = row['long_name']
              elsif abstract_course && course.name.blank?
                course.name = course.sis_name = abstract_course.name
              end
            end

            update_enrollments = !course.new_record? && !(course.changes.keys & ['workflow_state', 'name', 'course_code']).empty?
            if course.changed?
              course.templated_courses.each do |templated_course|
                templated_course.root_account = @root_account
                templated_course.account = course.account
                if templated_course.sis_name && templated_course.sis_name == templated_course.name && course.sis_name && course.sis_name == course.name
                  templated_course.name = course.name
                  templated_course.sis_name = course.sis_name
                end
                if templated_course.sis_course_code && templated_course.sis_course_code == templated_course.short_name && course.sis_course_code && course.sis_course_code == course.short_name
                  templated_course.sis_course_code = course.sis_course_code
                  templated_course.short_name = course.short_name
                end
                templated_course.enrollment_term = course.enrollment_term
                templated_course.sis_batch_id = @batch.id if @batch
                course_ids_to_update_associations.add(templated_course.id) if templated_course.account_id_changed? || templated_course.root_account_id_changed?
                templated_course.save_without_broadcasting!
              end
              course.sis_batch_id = @batch.id if @batch
              course.save_without_broadcasting!
              course_ids_to_update_associations.add(course.id) if update_account_associations
            elsif @batch
              courses_to_update_sis_batch_id << course.id
            end
            @sis.counts[:courses] += 1

            course.update_enrolled_users if update_enrollments
          end
        end
        Course.update_account_associations(course_ids_to_update_associations.to_a) unless course_ids_to_update_associations.empty?

        Course.update_all({:sis_batch_id => @batch.id}, {:id => courses_to_update_sis_batch_id}) if @batch && !courses_to_update_sis_batch_id.empty?
        logger.debug("Courses took #{Time.now - start} seconds")
      end
    end
  end
end
