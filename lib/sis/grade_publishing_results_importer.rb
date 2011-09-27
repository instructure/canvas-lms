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
  class GradePublishingResultsImporter < SisImporter

    def self.is_grade_publishing_results_csv?(row)
      row.header?('enrollment_id') && row.header?('grade_publishing_status')
    end

    def verify(csv, verify)
      enrollment_ids = (verify[:enrollment_ids] ||= {})
      csv_rows(csv) do |row|
        enrollment_id = row['enrollment_id']
        add_error(csv, "Duplicate enrollment id #{enrollment_id}") if enrollment_ids[enrollment_id]
        enrollment_ids[enrollment_id] = true
        add_error(csv, "No enrollment_id given") if row['enrollment_id'].blank?
        add_error(csv, "No grade_publishing_status given for enrollment #{enrollment_id}") if row['grade_publishing_status'].blank?
        add_error(csv, "Improper grade_publishing_status \"#{row['grade_publishing_status']}\" for enrollment #{enrollment_id}") unless %w{ published error }.include?(row['grade_publishing_status'].downcase)
      end
    end

    # expected columns
    # enrollment_id,grade_publishing_status
    def process(csv)
      start = Time.now
      csv_rows(csv) do |row|
        update_progress
        logger.debug("Processing Enrollment #{row.inspect}")

        enrollment = Enrollment.find_by_id(row['enrollment_id'])
        enrollment = nil if enrollment && ((enrollment.course && enrollment.course.root_account_id != @root_account.id) || (enrollment.course_section && enrollment.course_section.root_account_id != @root_account.id))
        unless enrollment
          add_warning(csv,"Enrollment #{row['enrollment_id']} doesn't exist")
          next
        end

        enrollment.grade_publishing_status = row['grade_publishing_status'].downcase

        enrollment.save

        @sis.counts[:grade_publishing_results] += 1
      end
      logger.debug("Grade publishing results took #{Time.now - start} seconds")
    end
  end
end
