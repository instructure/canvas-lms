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

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class DropTriggersForCollections < ActiveRecord::Migration[4.2]
  tag :predeploy

  # we had to switch to another strategy rather than triggers because the
  # different rows might be in different databases
  #
  # the triggers may not exist in the db, since we deleted the migration that
  # creates them -- drop_trigger will handle that gracefully
  def self.up
    drop_trigger("collection_items_after_insert_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_insert_row_when_new_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_when_new_workflow_state_ol_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_when_old_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("collection_item_upvotes_after_insert_row_tr", "collection_item_upvotes", :generated => true)

    drop_trigger("collection_item_upvotes_after_delete_row_tr", "collection_item_upvotes", :generated => true)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
