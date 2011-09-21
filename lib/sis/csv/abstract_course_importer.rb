#
# Copyright (C) 2011 Instructure, Inc.
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
    class AbstractCourseImporter < BaseImporter

      def self.is_abstract_course_csv?(row)
        row.header?('abstract_course_id') && !row.header?('course_id') && row.header?('short_name')
      end

      # expected columns
      # abstract_course_id,short_name,long_name,account_id,term_id,status
      def process(csv)
        @sis.counts[:abstract_courses] += SIS::AbstractCourseImporter.new(@batch.try(:id), @root_account, logger, @override_sis_stickiness).process do |importer|
          csv_rows(csv) do |row|
            update_progress

            begin
              importer.add_abstract_course(row['abstract_course_id'], row['short_name'], row['long_name'], row['status'], row['term_id'], row['account_id'], row['fallback_account_id'])
            rescue ImportError => e
              add_warning(csv, "#{e}")
            end
          end
        end
      end
    end
  end
end
