#
# Copyright (C) 2017 - present Instructure, Inc.
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
    class ChangeSisIdImporter < CSVBaseImporter

      def self.change_sis_id_csv?(row)
        row.include?('old_id') || row.include?('old_integration_id')
      end

      def self.identifying_fields
        %w[old_id old_integration_id].freeze
      end

      # possible columns:
      # old_id, new_id, old_integration_id, new_integration_id, type
      def process(csv, index=nil, count=nil)
        count = SIS::ChangeSisIdImporter.new(@root_account, importer_opts).process do |i|
          csv_rows(csv, index, count) do |row|
            begin
              i.process_change_sis_id(create_change_data(row))
            rescue ImportError => e
              SisBatch.add_error(csv, e.to_s, sis_batch: @batch, row: row['lineno'], row_info: row)
            end
          end
        end
        count
      end

      private
      def create_change_data(row)
        SIS::Models::DataChange.new(
          old_id: row['old_id'],
          new_id: row['new_id'],
          old_integration_id: row['old_integration_id'],
          new_integration_id: row['new_integration_id'],
          type: row['type'])
      end
    end
  end
end
