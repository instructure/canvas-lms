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
    class CourseImporter < CSVBaseImporter

      def self.course_csv?(row)
        row.include?('course_id') && row.include?('short_name')
      end

      def self.identifying_fields
        %w[course_id].freeze
      end

      # expected columns
      # course_id,short_name,long_name,account_id,term_id,status
      def process(csv, index=nil, count=nil)
        messages = []
        count = SIS::CourseImporter.new(@root_account, importer_opts).process(messages) do |importer|
          csv_rows(csv, index, count) do |row|
            start_date = nil
            end_date = nil
            begin
              start_date = Time.zone.parse(row['start_date']) if row['start_date'].present?
              end_date = Time.zone.parse(row['end_date']) if row['end_date'].present?
            rescue
              messages << SisBatch.build_error(csv, "Bad date format for course #{row['course_id']}", sis_batch: @batch, row: row['lineno'], row_info: row)
            end
            course_format = row.key?('course_format') && (row['course_format'] || 'not_set')
            begin
              importer.add_course(row['course_id'], row['term_id'], row['account_id'], row['fallback_account_id'], row['status'], start_date, end_date,
                                  row['abstract_course_id'], row['short_name'], row['long_name'], row['integration_id'], course_format, row['blueprint_course_id'])
            rescue ImportError => e
              messages << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row['lineno'], row_info: row)
            end
          end
        end
        errors = []
        messages.each do |message|
          errors << ((message.is_a? SisBatchError) ? message : SisBatch.build_error(csv, message, sis_batch: @batch))
        end
        SisBatch.bulk_insert_sis_errors(errors)
        count
      end
    end
  end
end
