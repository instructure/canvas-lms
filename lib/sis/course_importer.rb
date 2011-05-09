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
  class CourseImporter < SisImporter
    
    def self.is_course_csv?(row)
      row.header?('course_id') && row.header?('short_name')
    end
    
    def verify(csv, verify)
      course_ids = (verify[:course_ids] ||= {})
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        course_id = row['course_id']
        add_error(csv, "Duplicate course id #{course_id}") if course_ids[course_id]
        course_ids[course_id] = true
        add_error(csv, "No course_id given for a course") if row['course_id'].blank?
        add_error(csv, "No short_name given for course #{course_id}") if row['short_name'].blank?
        add_error(csv, "No long_name given for course #{course_id}") if row['long_name'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for course #{course_id}") unless row['status'] =~ /\Aactive|\Adeleted|\Acompleted/i
      end
    end
    
    # expected columns
    # course_id,short_name,long_name,account_id,term_id,status
    def process(csv)
      start = Time.now
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        update_progress
        
        Course.skip_updating_account_associations do
          update_account_association = false

          logger.debug("Processing Course #{row.inspect}")
          if row['account_id']
            account = Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['account_id'])
          else
            account = nil
          end
          term = @root_account.enrollment_terms.find_by_sis_source_id(row['term_id'])
          course = nil
          course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, row['course_id'])
          course ||= Course.new
          course.enrollment_term = term if term
          course.root_account = @root_account
          course.account = account || @root_account

          update_account_association = course.account_id_changed? || course.root_account_id_changed?
        
          # only update the name/short_name on new records, and ones that haven't been changed
          # since the last sis import
          if course.new_record? || (course.sis_course_code && course.sis_course_code == course.short_name)
            course.short_name = course.sis_course_code = row['short_name']
          end
          if course.new_record? || (course.sis_name && course.sis_name == course.name)
            course.name = course.sis_name = row['long_name']
          end
          course.sis_source_id = row['course_id']
          course.sis_batch_id = @batch.id if @batch
          if row['status'] =~ /active/i
            if course.workflow_state == 'completed'
              course.workflow_state = 'available'
            elsif course.workflow_state != 'available'
              course.workflow_state = 'claimed'
            end
          elsif  row['status'] =~ /deleted/i
            course.workflow_state = 'deleted'
          elsif  row['status'] =~ /completed/i
            course.workflow_state = 'completed'
          end

          begin
            course.start_at = DateTime.parse(row['start_date']) unless row['start_date'].blank?
            course.conclude_at = DateTime.parse(row['end_date']) unless row['end_date'].blank?
          rescue
            add_warning(csv, "Bad date format for course #{row['course_id']}")
          end

          course.save_without_broadcasting!
          @sis.counts[:courses] += 1

          course.update_account_associations if update_account_association
        end
      end
      logger.debug("Courses took #{Time.now - start} seconds")
    end
    
  end
end
