#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DataFixup
  module FixImportedAssignmentTurnitin
    def self.run
      start_at = DateTime.parse("2016-06-24")
      Assignment.find_ids_in_ranges(:batch_size => 10_000) do |min_id, max_id|
        assmt_ids = Assignment.where(:id => min_id..max_id, :turnitin_enabled => true).where("assignments.created_at > ?", start_at).where.not(:migration_id => nil).
          joins("LEFT OUTER JOIN #{Submission.quoted_table_name} ON submissions.assignment_id=assignments.id").where("submissions IS NULL").pluck(:id)
        next unless assmt_ids.any?

        Assignment.where(:id => assmt_ids).each do |assmt|
          settings = assmt.turnitin_settings
          if settings[:created]
            settings[:created] = false
            assmt.turnitin_settings = settings
            assmt.save!
          end
        end
      end
    end
  end
end