#
# Copyright (C) 2016 Instructure, Inc.
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
    class UserObserverImporter < CSVBaseImporter

      def self.user_observer_csv?(row)
        row.include?('observer_id') && row.include?('student_id')
      end

      def self.identifying_fields
        %w[observer_id].freeze
      end

      # possible columns:
      # observer_id, student_id, status
      def process(csv)
        @sis.counts[:user_observers] += SIS::UserObserverImporter.new(@root_account, importer_opts).process do |i|
          csv_rows(csv) do |row|
            update_progress

            begin
              i.process_user_observer(row['observer_id'], row['student_id'], row['status'])
            rescue ImportError => e
              add_warning(csv, "#{e}")
            end
          end
        end
      end
    end
  end
end
