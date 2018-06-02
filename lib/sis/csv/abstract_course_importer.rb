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
    class AbstractCourseImporter < CSVBaseImporter

      def self.abstract_course_csv?(row)
        row.include?('abstract_course_id') && !row.include?('course_id') && row.include?('short_name')
      end

      # expected columns
      # abstract_course_id,short_name,long_name,account_id,term_id,status
      def process(csv, index=nil, count=nil)
        count = SIS::AbstractCourseImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            begin
              importer.add_abstract_course(row['abstract_course_id'], row['short_name'],
                                           row['long_name'], row['status'], row['term_id'],
                                           row['account_id'], row['fallback_account_id'])
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
