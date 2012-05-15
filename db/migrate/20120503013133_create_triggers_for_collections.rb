# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersForCollections < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_trigger("collection_items_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:insert) do |t|
      t.where("NEW.workflow_state = 'active'") do
        <<-SQL_ACTIONS
      UPDATE collection_item_datas
      SET post_count = post_count + 1
      WHERE id = NEW.collection_item_data_id;
        SQL_ACTIONS
      end
    end

    create_trigger("collection_items_after_update_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:update) do |t|
      t.where("NEW.workflow_state <> OLD.workflow_state") do
        <<-SQL_ACTIONS
      UPDATE collection_item_datas
      SET post_count = post_count + CASE WHEN (NEW.workflow_state = 'active') THEN 1 ELSE -1 END
      WHERE id = NEW.collection_item_data_id;
        SQL_ACTIONS
      end
    end

    create_trigger("collection_items_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:delete) do |t|
      t.where("OLD.workflow_state = 'active'") do
        <<-SQL_ACTIONS
      UPDATE collection_item_datas
      SET post_count = post_count - 1
      WHERE id = OLD.collection_item_data_id;
        SQL_ACTIONS
      end
    end

    create_trigger("collection_item_upvotes_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("collection_item_upvotes").
        after(:insert) do
      <<-SQL_ACTIONS
    UPDATE collection_item_datas
    SET upvote_count = upvote_count + 1
    WHERE id = NEW.collection_item_data_id;
      SQL_ACTIONS
    end

    create_trigger("collection_item_upvotes_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("collection_item_upvotes").
        after(:delete) do
      <<-SQL_ACTIONS
    UPDATE collection_item_datas
    SET upvote_count = upvote_count - 1
    WHERE id = OLD.collection_item_data_id;
      SQL_ACTIONS
    end
  end

  def self.down
    drop_trigger("collection_items_after_insert_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_insert_row_when_new_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_when_new_workflow_state_ol_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_when_old_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("collection_item_upvotes_after_insert_row_tr", "collection_item_upvotes", :generated => true)

    drop_trigger("collection_item_upvotes_after_delete_row_tr", "collection_item_upvotes", :generated => true)
  end
end
