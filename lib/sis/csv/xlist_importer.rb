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
    class XlistImporter < CSVBaseImporter

      def self.xlist_csv?(row)
        row.include?('xlist_course_id') && row.include?('section_id')
      end

      def self.identifying_fields
        %w[section_id].freeze
      end

      # possible columns:
      # xlist_course_id, section_id, status
      def process(csv, index=nil, count=nil)
        count = SIS::XlistImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            begin
              importer.add_crosslist(row['xlist_course_id'], row['section_id'], row['status'])
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
