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

module DataFixup::FixInvalidCourseIdsOnEnrollments
  def self.run
    Enrollment.joins(:course_section).preload(:course_section).
      where("course_sections.course_id<>enrollments.course_id").
      find_each do |e|
      Enrollment.where(id: e).update_all(course_id: e.course_section.course_id)
    end
  end
end
