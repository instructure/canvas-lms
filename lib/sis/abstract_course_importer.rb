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
  class AbstractCourseImporter < SisImporter
    
    def self.is_abstract_course_csv?(row)
      row.header?('abstract_course_id') && !row.header?('course_id') && row.header?('short_name')
    end
    
    def verify(csv, verify)
      abstract_course_ids = (verify[:abstract_course_ids] ||= {})
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        abstract_course_id = row['abstract_course_id']
        add_error(csv, "Duplicate abstract course id #{abstract_course_id}") if abstract_course_ids[abstract_course_id]
        abstract_course_ids[abstract_course_id] = true
        add_error(csv, "No abstract_course_id given for an abstract course") if row['abstract_course_id'].blank?
        add_error(csv, "No short_name given for abstract course #{abstract_course_id}") if row['short_name'].blank?
        add_error(csv, "No long_name given for abstract course #{abstract_course_id}") if row['long_name'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for abstract course #{abstract_course_id}") unless row['status'] =~ /\Aactive|\Adeleted/i
      end
    end
    
    # expected columns
    # abstract_course_id,short_name,long_name,account_id,term_id,status
    def process(csv)
      start = Time.now
      abstract_courses_to_update_sis_batch_id = []
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        update_progress

        logger.debug("Processing AbstractCourse #{row.inspect}")
        term = @root_account.enrollment_terms.find_by_sis_source_id(row['term_id'])
        course = AbstractCourse.find_by_root_account_id_and_sis_source_id(@root_account.id, row['abstract_course_id'])
        course ||= AbstractCourse.new
        course.enrollment_term = term if term
        course.root_account = @root_account
        if row['account_id'].present?
          account = Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['account_id'])
          course.account = account if account
        end
        course.account ||= @root_account

        # only update the name/short_name on new records, and ones that haven't been changed
        # since the last sis import
        if course.new_record? || (course.sis_course_code && course.sis_course_code == course.short_name)
          course.short_name = course.sis_course_code = row['short_name']
        end
        if course.new_record? || (course.sis_name && course.sis_name == course.name)
          course.name = course.sis_name = row['long_name']
        end
        course.sis_source_id = row['abstract_course_id']
        if row['status'] =~ /active/i
          course.workflow_state = 'active'
        elsif row['status'] =~ /deleted/i
          course.workflow_state = 'deleted'
        end

        if course.changed?
          course.sis_batch_id = @batch.id if @batch
          course.save!
        elsif @batch
          abstract_courses_to_update_sis_batch_id << @batch.id
        end
        @sis.counts[:abstract_courses] += 1
      end
      AbstractCourse.update_all({:sis_batch_id => @batch.id}, {:id => abstract_courses_to_update_sis_batch_id}) if @batch && !abstract_courses_to_update_sis_batch_id.empty?
      logger.debug("AbstractCourses took #{Time.now - start} seconds")
    end
  end
end
