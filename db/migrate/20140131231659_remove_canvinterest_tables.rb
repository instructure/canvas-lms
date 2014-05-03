class RemoveCanvinterestTables < ActiveRecord::Migration
  tag :postdeploy

  def self.up
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
    drop_table :user_follows
    drop_table :collection_item_upvotes
    drop_table :collection_item_datas
    drop_table :collection_items
    drop_table :collections

  end

  def self.down
    create_table "user_follows", :force => true do |t|
      t.integer  "following_user_id",  :limit => 8, :null => false
      t.string   "followed_item_type"
      t.integer  "followed_item_id",   :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_follows", ["followed_item_id", "followed_item_type"], :name => "index_user_follows_inverse"
    add_index "user_follows", ["following_user_id", "followed_item_type", "followed_item_id"], :name => "index_user_follows_unique", :unique => true

    create_table "collection_item_upvotes", :force => true do |t|
      t.integer  "collection_item_data_id", :limit => 8, :null => false
      t.integer  "user_id",                 :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "collection_item_upvotes", ["collection_item_data_id", "user_id"], :name => "index_collection_item_upvotes_join", :unique => true

    create_table "collection_item_datas", :force => true do |t|
      t.string   "item_type"
      t.text     "link_url",                                        :null => false
      t.integer  "root_item_id",        :limit => 8
      t.integer  "post_count",                       :default => 0
      t.integer  "upvote_count",                     :default => 0
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "image_pending"
      t.integer  "image_attachment_id", :limit => 8
      t.text     "image_url"
      t.text     "html_preview"
      t.string   "title"
      t.text     "description"
    end

    create_table "collection_items", :force => true do |t|
      t.integer  "collection_item_data_id", :limit => 8, :null => false
      t.integer  "collection_id",           :limit => 8, :null => false
      t.string   "workflow_state",                       :null => false
      t.text     "user_comment"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id",                 :limit => 8, :null => false
    end

    add_index "collection_items", ["collection_id", "workflow_state"], :name => "index_collection_items_on_collection_id_and_workflow_state"
    add_index "collection_items", ["collection_item_data_id", "workflow_state"], :name => "index_collection_items_on_data_id"

    create_table "collections", :force => true do |t|
      t.string   "name"
      t.string   "visibility",                   :default => "private"
      t.string   "context_type",                                        :null => false
      t.integer  "context_id",      :limit => 8,                        :null => false
      t.string   "workflow_state",                                      :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "followers_count",              :default => 0
      t.integer  "items_count",                  :default => 0
    end

    add_index "collections", ["context_id", "context_type", "workflow_state", "visibility"], :name => "index_collections_for_finding"

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
  end
end
