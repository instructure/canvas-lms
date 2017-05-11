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

class DropWikiNamespaces < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :wiki_namespaces
  end

  def self.recreate_namespace(c)
    connection.execute(["INSERT INTO #{connection.quote_table_name('wiki_namespaces')} (namespace, context_type, context_id) VALUES ('default',?,?)", c.class.to_s, c.id])
  end

  def self.down
    create_table :wiki_namespaces do |t|
      t.integer :wiki_id, :limit => 8
      t.string :namespace
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.integer :collaboration_id, :limit => 8
      t.timestamps
    end
    add_index :wiki_namespaces, [:context_id, :context_type]
    add_index :wiki_namespaces, :wiki_id

    Course.where("wiki_id IS NOT NULL").find_each do |c|
      recreate_namespace(c)
    end
    Group.where("wiki_id IS NOT NULL").find_each do |c|
      recreate_namespace(c)
    end
  end
end
