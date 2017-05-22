#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AddIndexOnCourseWikiId < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :courses, :wiki_id, algorithm: :concurrently, where: "wiki_id IS NOT NULL"
    if connection.adapter_name == 'PostgreSQL'
      remove_index :groups, :wiki_id
      add_index :groups, :wiki_id, algorithm: :concurrently, where: "wiki_id IS NOT NULL"
    end
  end

  def self.down
    remove_index :courses, :wiki_id
    if connection.adapter_name == 'PostgreSQL'
      remove_index :groups, :wiki_id
      add_index :groups, :wiki_id
    end
  end
end
