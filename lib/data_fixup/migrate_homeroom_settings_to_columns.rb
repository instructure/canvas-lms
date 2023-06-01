# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
  module MigrateHomeroomSettingsToColumns
    def self.run
      Course.where("settings like '%homeroom%'").find_each do |course|
        settings = course.settings
        if settings[:homeroom_course] || settings[:sync_enrollments_from_homeroom] || settings[:homeroom_course_id].present?
          # Check for strings when we want ints
          homeroom_course_id = settings[:homeroom_course_id].to_i.zero? ? nil : settings[:homeroom_course_id].presence
          Course.where(id: course.id).update_all(
            homeroom_course: settings[:homeroom_course] || false,
            sync_enrollments_from_homeroom: settings[:sync_enrollments_from_homeroom] || false,
            homeroom_course_id:
          )
        end
      end
    end
  end
end
