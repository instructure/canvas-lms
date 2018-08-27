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
    class GradePublishingResultsImporter < CSVBaseImporter

      def self.grade_publishing_results_csv?(row)
        row.include?('enrollment_id') && row.include?('grade_publishing_status')
      end

      # expected columns
      # enrollment_id,grade_publishing_status
      def process(csv, index=nil, count=nil)
        count = SIS::GradePublishingResultsImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            begin
              importer.add_grade_publishing_result(row['enrollment_id'], row['grade_publishing_status'], row['message'])
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
