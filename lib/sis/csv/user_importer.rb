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
    class UserImporter < CSVBaseImporter

      def self.user_csv?(row)
        row.include?('user_id') && row.include?('login_id')
      end

      def self.identifying_fields
        %w[user_id].freeze
      end

      # expected columns:
      # user_id,login_id,first_name,last_name,email,status
      def process(csv, index=nil, count=nil)
        messages = []
        count = SIS::UserImporter.new(@root_account, importer_opts).process(messages) do |importer|
          csv_rows(csv, index, count) do |row|
            begin
              importer.add_user(create_user(row, csv))
            rescue ImportError => e
              messages << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row['lineno'], row_info: row)
            end
          end
        end
        SisBatch.bulk_insert_sis_errors(messages)
        count
      end

      private
      def create_user(row, csv)
        SIS::Models::User.new(
          user_id: row['user_id'],
          login_id: row['login_id'],
          status: row['status'],
          first_name: row['first_name'],
          last_name: row['last_name'],
          email: row['email'],
          password: row['password'],
          ssha_password: row['ssha_password'],
          integration_id: row['integration_id'],
          short_name: row['short_name'],
          full_name: row['full_name'],
          sortable_name: row['sortable_name'],
          lineno: row['lineno'],
          csv: csv,
          authentication_provider_id: row['authentication_provider_id']
        )
      end
    end
  end
end
