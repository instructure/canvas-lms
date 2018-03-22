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
    # note these are account-level groups, not course groups
    class GroupImporter < CSVBaseImporter
      def self.group_csv?(row)
        row.include?('group_id') && row.include?('name')
      end

      def self.identifying_fields
        %w[group_id].freeze
      end

      # expected columns
      # group_id,account_id,name,status
      def process(csv, index=nil, count=nil)
        count = SIS::GroupImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            update_progress
            begin
              importer.add_group(row['group_id'], row['group_category_id'], row['account_id'],
                                 row['course_id'], row['name'], row['status'])
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
