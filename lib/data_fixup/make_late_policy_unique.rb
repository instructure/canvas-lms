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

module DataFixup
  module MakeLatePolicyUnique
    def self.run
      duplicates = LatePolicy.group(:course_id).having("count(id) > 1").pluck(Arel.sql("course_id, max(id)")).transpose
      LatePolicy.where(course_id: duplicates[0]).where.not(id: duplicates[1]).delete_all
    end
  end
end
