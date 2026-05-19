# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
    class InstitutionalTagImporter < CSVBaseImporter
      def self.institutional_tag_csv?(row)
        row.include?("institutional_tag_id") && row.include?("category_id") && row.include?("name")
      end

      def self.identifying_fields
        %w[institutional_tag_id].freeze
      end

      # expected columns
      # institutional_tag_id, category_id, name, description, status
      def process(csv, index = nil, count = nil)
        errors = []
        count = SIS::InstitutionalTagImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            importer.add_institutional_tag(row["institutional_tag_id"],
                                           row["category_id"],
                                           row["name"],
                                           row["description"],
                                           row["status"])
          rescue ImportError => e
            errors << SisBatch.build_error(csv, e.to_s, sis_batch: @batch, row: row["lineno"], row_info: row)
          end
        end
        SisBatch.bulk_insert_sis_errors(errors)
        count
      end
    end
  end
end
