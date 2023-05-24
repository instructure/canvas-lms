# frozen_string_literal: true

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
    class AdminImporter < CSVBaseImporter
      def self.admin_csv?(row)
        row.include?("account_id") && row.include?("user_id")
      end

      def self.identifying_fields
        %w[user_id account_id].freeze
      end

      # possible columns:
      # user_id, account_id, role_id, role
      def process(csv, index = nil, count = nil)
        messages = []
        count = SIS::AdminImporter.new(@root_account, importer_opts).process do |i|
          csv_rows(csv, index, count) do |row|
            i.process_admin(user_id: row["user_id"],
                            account_id: row["account_id"],
                            role_id: row["role_id"],
                            role: row["role"],
                            status: row["status"],
                            root_account: row["root_account"])
          rescue ImportError => e
            messages << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row["lineno"], row_info: row)
          end
        end
        SisBatch.bulk_insert_sis_errors(messages)
        count
      end
    end
  end
end
