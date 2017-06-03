#
# Copyright (C) 2016 - present Instructure, Inc.
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

class CreateChildContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_child_content_tags do |t|
      t.integer :child_subscription_id, limit: 8, null: false # mainly for bulk loading on import

      t.string :content_type, null: false
      t.integer :content_id, limit: 8, null: false

      t.text :downstream_changes
    end

    add_index :master_courses_child_content_tags, [:content_type, :content_id], :unique => true,
      :name => "index_child_content_tags_on_content"

    add_foreign_key :master_courses_child_content_tags, :master_courses_child_subscriptions, column: "child_subscription_id"
    add_index :master_courses_child_content_tags, :child_subscription_id, :name => "index_child_content_tags_on_subscription"

    # may as well add these now too
    add_column :master_courses_master_templates, :default_restrictions, :text

    add_column :master_courses_master_content_tags, :restrictions, :text # my gut tells me that we might not leave this at settings/content
    add_column :master_courses_master_content_tags, :migration_id, :string
    add_index :master_courses_master_content_tags, :migration_id, :unique => true, :name => "index_master_content_tags_on_migration_id"
  end
end
