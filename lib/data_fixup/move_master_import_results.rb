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

module DataFixup::MoveMasterImportResults
  def self.run
    MasterCourses::MasterMigration.find_ids_in_ranges do |min_id, max_id|
      MasterCourses::MasterMigration.where(:id => min_id..max_id).where.not(:import_results => nil).each do |mig|
        mig.import_results.each do |cm_id, res|
          next if mig.migration_results.where(:content_migration_id => cm_id).exists?

          attrs = {
            :content_migration_id => cm_id,
            :state => res[:state],
            :child_subscription_id => res[:subscription_id],
            :import_type => res[:import_type]
          }
          if res[:skipped].present?
            attrs[:results] = {:skipped => res[:skipped]}
          end
          mig.migration_results.create!(attrs)
        end
        mig.import_results = {}
        mig.save!
      end
    end
  end
end
