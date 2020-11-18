# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::AddUserUuidToLearningOutcomeResults
  def self.run
    batch = 1000
    final = LearningOutcomeResult.maximum(:id) || 0
    (0..final).step(batch).each do |ix|
      LearningOutcomeResult.connection.exec_update(
        update_sql(ix, ix + batch)
      )
    end
  end

  def self.update_sql(start_id, end_id)
    <<-SQL
      UPDATE #{LearningOutcomeResult.quoted_table_name} AS lor
      SET user_uuid = users.uuid
      FROM (SELECT id, uuid FROM #{User.quoted_table_name}) AS users(id, uuid)
      WHERE lor.user_id = users.id AND lor.id >= #{start_id} AND lor.id < #{end_id}
    SQL
  end
end
