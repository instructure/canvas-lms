# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
    # NOTE: these are account-level groups, not course groups
    class LoginImporter < CSVBaseImporter
      def self.login_csv?(row)
        row.intersect?(%w[existing_user_id existing_integration_id existing_canvas_user_id])
      end

      def self.identifying_fields
        %w[user_id].freeze
      end

      # expected columns:
      # existing_user_id user_id,login_id,email
      def process(csv, index = nil, count = nil)
        messages = []
        count = SIS::UserImporter.new(@root_account, importer_opts).process(messages, login_only: true) do |importer|
          csv_rows(csv, index, count) do |row|
            p = create_user(row, csv)
            importer.add_user(p, login_only: true)
          rescue ImportError => e
            messages << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row["lineno"], row_info: p.login_row_info)
          end
        end
        SisBatch.bulk_insert_sis_errors(messages)
        count
      end

      private

      def create_user(row, csv)
        SIS::Models::User.new(
          user_id: row["user_id"],
          login_id: row["login_id"],
          status: "active",
          existing_user_id: row["existing_user_id"],
          existing_integration_id: row["existing_integration_id"],
          existing_canvas_user_id: row["existing_canvas_user_id"],
          root_account_id: row["root_account"],
          email: row["email"],
          password: row["password"],
          ssha_password: row["ssha_password"],
          integration_id: row["integration_id"],
          lineno: row["lineno"],
          csv:,
          row:,
          authentication_provider_id: row["authentication_provider_id"]
        )
      end
    end
  end
end
