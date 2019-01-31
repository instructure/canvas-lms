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

module DataFixup::AddLtiIdToUsers
  def self.run
    User.where(lti_id: nil).find_ids_in_batches(:batch_size => 10_000) do |batch|
      updates = []
      batch.each {|id| updates << [id, SecureRandom.uuid]}
      sql_updates = updates.map { |v| "(#{v.first},'#{v.last}')" }.join(',')

      User.connection.select_values(update_sql(sql_updates))

      delay = Setting.get("lti_id_datafixup_delay", "0").to_i
      sleep(delay) if delay > 0
    end
  end

  def self.update_sql(sql_updates)
    <<-SQL
      UPDATE #{User.quoted_table_name} AS t
      SET lti_id = x.lti_id
      FROM (VALUES #{sql_updates}) AS x(id, lti_id)
      WHERE t.id=x.id
    SQL
  end
end
