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
    Course.where(id: start_at..end_at).find_each(start: 0) do |course|
      next unless course.feature_enabled?(:anonymous_grading) && !course.feature_enabled?(:anonymous_marking)

      course.assignments.in_batches.update_all(anonymous_grading: true)
      course.enable_feature!(:anonymous_marking)
    end
  end
end
