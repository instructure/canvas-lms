#
# Copyright (C) 2014 - present Instructure, Inc.
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

module DataFixup::PopulateGroupCategoryOnDiscussionTopics
  def self.run
    Assignment.where('submission_types = ? AND group_category_id IS NOT NULL', 'discussion_topic').find_ids_in_ranges do |min_id, max_id|
      DiscussionTopic.where(assignment_id: min_id..max_id).joins(:assignment).update_all("group_category_id = assignments.group_category_id")
    end
  end
end
