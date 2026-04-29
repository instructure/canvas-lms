# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
    class DifferentiationTagSetImporter < CSVBaseImporter
      def self.differentiation_tag_set_csv?(row)
        row.include?("tag_set_id") && row.include?("set_name")
      end

      def self.identifying_fields
        %w[tag_set_id].freeze
      end

      # expected columns
      # tag_set_id, course_id, set_name, status
      def process(csv, index = nil, count = nil)
        SIS::GroupCategoryImporter.new(@root_account, importer_opts).process do |importer|
          csv_rows(csv, index, count) do |row|
            importer.add_differentiation_tag_set(row["tag_set_id"],
                                                 row["course_id"],
                                                 row["set_name"],
                                                 row["status"])
          rescue ImportError => e
            SisBatch.add_error(csv, e.to_s, sis_batch: @batch, row: row["lineno"], row_info: row)
          end
        end
      end
    end
  end
end
