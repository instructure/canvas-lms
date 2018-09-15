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
    class AccountImporter < CSVBaseImporter

      def self.account_csv?(row)
        row.include?('account_id') && row.include?('parent_account_id')
      end

      def self.identifying_fields
        %w[account_id].freeze
      end

      # expected columns
      # account_id,parent_account_id
      def process(csv, index=nil, count=nil)
        count = SIS::AccountImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            begin
              importer.add_account(row['account_id'], row['parent_account_id'],
                                   row['status'], row['name'], row['integration_id'])
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
