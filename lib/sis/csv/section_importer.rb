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
    class SectionImporter < CSVBaseImporter

      def self.section_csv?(row)
        #This matcher works because an enrollment doesn't have name
        row.include?('section_id') && row.include?('name')
      end

      def self.identifying_fields
        %w[section_id].freeze
      end

      # expected columns
      # section_id,course_id,name,status,start_date,end_date
      def process(csv, index=nil, count=nil)
        count = SIS::SectionImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            start_date = nil
            end_date = nil
            begin
              start_date = Time.zone.parse(row['start_date']) if row['start_date'].present?
              end_date = Time.zone.parse(row['end_date']) if row['end_date'].present?
            rescue
              SisBatch.add_error(csv, "Bad date format for section #{row['section_id']}", sis_batch: @batch, row: row['lineno'], row_info: row)
            end

            begin
              importer.add_section(row['section_id'], row['course_id'], row['name'], row['status'], start_date, end_date, row['integration_id'])
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
