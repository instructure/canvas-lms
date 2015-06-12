#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

      def self.is_section_csv?(row)
        #This matcher works because an enrollment doesn't have name
        row.include?('section_id') && row.include?('name')
      end

      def self.identifying_fields
        %w[section_id].freeze
      end

      # expected columns
      # section_id,course_id,name,status,start_date,end_date
      def process(csv)
        @sis.counts[:sections] += SIS::SectionImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv) do |row|
            update_progress

            start_date = nil
            end_date = nil
            begin
              start_date = DateTime.parse(row['start_date']) unless row['start_date'].blank?
              end_date = DateTime.parse(row['end_date']) unless row['end_date'].blank?
            rescue
              add_warning(csv, "Bad date format for section #{row['section_id']}")
            end

            begin
              importer.add_section(row['section_id'], row['course_id'], row['name'], row['status'], start_date, end_date, row['integration_id'])
            rescue ImportError => e
              add_warning(csv, "#{e}")
            end
          end
        end
      end
    end
  end
end
