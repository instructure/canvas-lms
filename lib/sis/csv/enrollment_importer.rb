#
# Copyright (C) 2011 - present Instructure, Inc.
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
  module CSV
    class EnrollmentImporter < CSVBaseImporter

      def self.enrollment_csv?(row)
        (row.include?('section_id') || row.include?('course_id')) &&
          (row.include?('user_id') || row.include?('user_integration_id'))
      end

      def self.identifying_fields
        %w[course_id section_id user_id user_integration_id role associated_user_id].freeze
      end

      # expected columns
      # course_id,user_id,role,section_id,status
      def process(csv, index=nil, count=nil)
        messages = []
        count = SIS::EnrollmentImporter.new(@root_account, importer_opts).process(messages) do |importer|
          csv_rows(csv, index, count) do |row|
            update_progress
            begin
              importer.add_enrollment(create_enrollment(row, messages, csv: csv))
            rescue ImportError => e
              messages << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row['lineno'], row_info: row)
            end
          end
        end
        SisBatch.bulk_insert_sis_errors(messages)
        count
      end

      private
      def create_enrollment(row, messages, csv: nil)
        enrollment = SIS::Models::Enrollment.new(
          course_id: row['course_id'],
          section_id: row['section_id'],
          user_id: row['user_id'],
          user_integration_id: row['user_integration_id'],
          role: row['role'],
          status: row['status'],
          associated_user_id: row['associated_user_id'],
          root_account_id: row['root_account'],
          role_id: row['role_id'],
          limit_section_privileges: row['limit_section_privileges'],
          lineno: row['lineno'],
          csv: csv
        )

        begin
          enrollment.start_date = DateTime.parse(row['start_date']) if row['start_date'].present?
          enrollment.end_date = DateTime.parse(row['end_date']) if row['end_date'].present?
        rescue ArgumentError
          message = "Bad date format for user #{row['user_id']} in #{row['course_id'].blank? ? 'section' : 'course'} #{row['course_id'].presence || row['section_id']}"
          messages << SisBatch.build_error(csv, message, sis_batch: @batch, row: enrollment.lineno, row_info: row)
        end

        enrollment
      end
    end
  end
end
