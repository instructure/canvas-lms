#
# Copyright (C) 2012 - present Instructure, Inc.
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

class PurgeDuplicateDeletedSisEnrollments < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    while true
      pairs = Enrollment.connection.select_rows("
          SELECT user_id, course_section_id, type
          FROM #{Enrollment.quoted_table_name}
          WHERE workflow_state='deleted' AND sis_source_id IS NOT NULL
          GROUP BY user_id, course_section_id, type
          HAVING count(*) > 1 LIMIT 1000")
      break if pairs.empty?
      pairs.each do |(user_id, course_section_id, type)|
        scope = Enrollment.where("user_id=? AND course_section_id=? AND type=? AND sis_source_id IS NOT NULL AND workflow_state='deleted'", user_id.to_i, course_section_id.to_i, type)
        keeper = scope.limit(1).pluck(:id).first
        scope.where("id<>?", keeper).delete_all
      end
    end
  end

  def self.down
  end
end
