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
  module CSV
    class EnrollmentImporter < CSVBaseImporter

      def self.is_enrollment_csv?(row)
        (row.include?('section_id') || row.include?('course_id')) && row.include?('user_id')
      end

      # expected columns
      # course_id,user_id,role,section_id,status
      def process(csv)
        messages = []
        @sis.counts[:enrollments] += SIS::EnrollmentImporter.new(@root_account, importer_opts).process(messages, @sis.updates_every) do |importer|
          csv_rows(csv) do |row|
            update_progress

            start_date = nil
            end_date = nil
            begin
              start_date = DateTime.parse(row['start_date']) unless row['start_date'].blank?
              end_date = DateTime.parse(row['end_date']) unless row['end_date'].blank?
            rescue
              messages << "Bad date format for user #{row['user_id']} in #{row['course_id'].blank? ? 'section' : 'course'} #{row['course_id'].blank? ? row['section_id'] : row['course_id']}"
            end

            begin
              importer.add_enrollment(row['course_id'], row['section_id'], row['user_id'], row['role'], row['status'], start_date, end_date, row['associated_user_id'], row['root_account'])
            rescue ImportError => e
              messages << "#{e}"
              next
            end
          end
        end
        messages.each { |message| add_warning(csv, message) }
      end
    end
  end
end
