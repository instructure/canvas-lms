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
#

module DataFixup::BackfillAnonymousGradingData
  def self.run(start_at, end_at)
    Course.where("id >= ? AND id <= ?", start_at, end_at).find_each(start: 0) do |course|
      next unless course.feature_enabled?(:anonymous_grading) && !course.feature_enabled?(:anonymous_marking)

      course.assignments.in_batches.update_all(anonymous_grading: true)

      # Manually build the feature flag because we're going to ignore
      # validations at save time. This is because the feature is still
      # in development, but we're doing a backfill for legacy courses
      # so they are ready for the new code when its unveiled.
      anonymous_marking_flag = course.feature_flags.where(feature: :anonymous_marking).first_or_initialize
      if anonymous_marking_flag.state != 'on'
        anonymous_marking_flag.state = 'on'
        anonymous_marking_flag.save!(validate: false)
      end
    end
  end
end
