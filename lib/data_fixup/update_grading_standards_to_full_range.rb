#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup::UpdateGradingStandardsToFullRange
  def self.run
    GradingStandard.where(version: 2).find_ids_in_ranges do |min,max|
      GradingStandard.where(version: 2, id: min..max).each do |grading_standard|
        next if grading_standard.valid?

        # Let's not update any records that already have a 0% bucket
        next unless grading_standard.errors[:data].include?('grading schemes must have 0% for the lowest grade')
        # or any records that have a negative bucket value because technically 0 will fit either in the highest bucket
        # or in the first negative bucket following a positive bucket
        next if grading_standard.errors[:data].include?('grading scheme values cannot be negative')

        buckets = grading_standard.data.sort_by { |bucket| -bucket[1] }
        buckets.last[1] = 0.0

        grading_standard.update_attribute(:data, buckets)
      end
    end
  end
end
