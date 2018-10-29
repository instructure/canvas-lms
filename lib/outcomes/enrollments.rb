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

module Outcomes
  module Enrollments
    def verify_readable_grade_enrollments(user_ids)
      enrollments = @context.enrollments.where(user_id: user_ids)
      enrollment_user_ids = enrollments.map(&:user_id).uniq
      reject! "specified users not enrolled" unless enrollment_user_ids.length == user_ids.length
      reject! "not authorized to read grades for specified users", :forbidden unless enrollments.all? do |e|
        e.grants_right?(@current_user, session, :read_grades)
      end
    end
  end
end
