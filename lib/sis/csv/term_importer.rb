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
    class TermImporter < CSVBaseImporter

      def self.term_csv?(row)
        #This matcher works because a course has long_name/short_name
        row.include?('term_id') && row.include?('name')
      end

      def self.identifying_fields
        %w[term_id].freeze
      end

      # expected columns
      # account_id,parent_account_id,name,status
      def process(csv, index=nil, count=nil)
        count = SIS::TermImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            start_date = nil
            end_date = nil
            begin
              start_date = Time.zone.parse(row['start_date']) if row['start_date'].present?
              end_date = Time.zone.parse(row['end_date']) if row['end_date'].present?
            rescue
              SisBatch.add_error(csv, "Bad date format for term #{row['term_id']}", sis_batch: @batch, row: row['lineno'], row_info: row)
            end

            begin
              importer.add_term(row['term_id'], row['name'], row['status'], start_date, end_date, row['integration_id'], row['date_override_enrollment_type'])
            rescue ImportError => e
              SisBatch.add_error(csv, e.to_s, sis_batch: @batch, row: row['lineno'], row_info: row)
            end
          end
        end
        count
      end
    end
  end
end
