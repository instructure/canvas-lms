# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::RemoveInvalidCoursePaceModuleItems
  def self.run
    # Wrong tag type
    CoursePaceModuleItem.joins(:module_item).where.not(content_tags: { tag_type: "context_module" }).find_ids_in_batches do |ids|
      CoursePaceModuleItem.where(id: ids).delete_all
    end

    # Remove any course pace module items that are no longer valid. Additional validation checks were added that might
    # make old records invalid. For this particular commit it was the additional check that the module item must
    # have a tag_type of "context_module".
    CoursePaceModuleItem.preload(:module_item, :course_pace).find_each do |course_pace_module_item|
      unless course_pace_module_item.valid?
        course_pace_module_item.destroy
        course_pace_module_item.course_pace.create_publish_progress
      end
    end
  end
end
