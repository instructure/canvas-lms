# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateCollectionItemsCountAndFollowersCountTriggers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_trigger("collection_items_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:insert) do |t|
      t.where("NEW.workflow_state = 'active'") do
        <<-SQL_ACTIONS
      UPDATE collections
      SET items_count = items_count + 1
      WHERE id = NEW.collection_id;
        SQL_ACTIONS
      end
    end

    create_trigger("collection_items_after_update_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:update) do |t|
      t.where("NEW.workflow_state <> OLD.workflow_state") do
        <<-SQL_ACTIONS
      UPDATE collections
      SET items_count = items_count + CASE WHEN (NEW.workflow_state = 'active') THEN 1 ELSE -1 END
      WHERE id = NEW.collection_id;
        SQL_ACTIONS
      end
    end

    create_trigger("collection_items_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("collection_items").
        after(:delete) do |t|
      t.where("OLD.workflow_state = 'active'") do
        <<-SQL_ACTIONS
      UPDATE collections
      SET items_count = items_count - 1
      WHERE id = OLD.collection_id;
        SQL_ACTIONS
      end
    end

    create_trigger("user_follows_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("user_follows").
        after(:insert) do |t|
      t.where("NEW.followed_item_type = 'Collection'") do
        <<-SQL_ACTIONS
      UPDATE collections
      SET followers_count = followers_count + 1
      WHERE id = NEW.followed_item_id;
        SQL_ACTIONS
      end
    end

    create_trigger("user_follows_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("user_follows").
        after(:delete) do |t|
      t.where("OLD.followed_item_type = 'Collection'") do
        <<-SQL_ACTIONS
      UPDATE collections
      SET followers_count = followers_count - 1
      WHERE id = OLD.followed_item_id;
        SQL_ACTIONS
      end
    end
  end

  def self.down
    drop_trigger("collection_items_after_insert_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_insert_row_when_new_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_update_row_when_new_workflow_state_ol_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_tr", "collection_items", :generated => true)

    drop_trigger("collection_items_after_delete_row_when_old_workflow_state_ac_tr", "collection_items", :generated => true)

    drop_trigger("user_follows_after_insert_row_tr", "user_follows", :generated => true)

    drop_trigger("user_follows_after_insert_row_when_new_followed_item_type_co_tr", "user_follows", :generated => true)

    drop_trigger("user_follows_after_delete_row_tr", "user_follows", :generated => true)

    drop_trigger("user_follows_after_delete_row_when_old_followed_item_type_co_tr", "user_follows", :generated => true)
  end
end
