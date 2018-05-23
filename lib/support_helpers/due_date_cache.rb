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

module SupportHelpers
  module DueDateCache
    class CourseFixer < Fixer
      def initialize(email, after_time, course_id)
        @course_id = course_id
        super(email, after_time)
      end

      def fix
        course = Course.find(@course_id)
        DueDateCacher.recompute_course(course, update_grades: true)
      end
    end
  end
end
