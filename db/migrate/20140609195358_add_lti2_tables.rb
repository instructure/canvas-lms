class AddLti2Tables < ActiveRecord::Migration
  tag :predeploy

  def self.up

    create_table :lti_product_families do |t|
      t.string :vendor_code, null: false
      t.string :product_code, null: false
      t.string :vendor_name, null: false
      t.text :vendor_description
      t.string :website
      t.string :vendor_email
      t.integer :root_account_id, limit: 8, null: false
      t.timestamps
    end

    create_table :lti_message_handlers do |t|
      t.string :message_type, null: false
      t.string :launch_path, null: false
      t.text :capabilities
      t.text :parameters
      t.integer :resource_handler_id, limit: 8, null: false
      t.timestamps
    end

    create_table :lti_resource_handlers do |t|
      t.string :resource_type_code, null: false
      t.string :placements
      t.string :name, null: false
      t.text :description
      t.text :icon_info
      t.integer :tool_proxy_id, limit: 8, null: false
      t.timestamps
    end

    create_table :lti_resource_placements do |t|
      t.integer :resource_handler_id, limit: 8, null: false
      t.string :placement, null: false
      t.timestamps
    end

    create_table :lti_tool_proxies do |t|
      t.string :shared_secret, null: false
      t.string :guid, null: false
      t.string :product_version, null: false
      t.string :lti_version, null: false
      t.integer :product_family_id, limit: 8, null: false
      t.integer :root_account_id, limit: 8, null: false
      t.string :workflow_state, null: false
      t.text :raw_data, null: false
      t.timestamps
    end

    create_table :lti_tool_proxy_bindings do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.integer :tool_proxy_id, limit:8, null: false
      t.timestamps
    end

    add_index :lti_product_families, [:root_account_id, :vendor_code, :product_code], name: 'index_lti_product_families_on_root_account_vend_code_prod_code', unique: true
    add_index :lti_message_handlers, [:resource_handler_id, :message_type], name: 'index_lti_message_handlers_on_resource_handler_and_type', unique: true
    add_index :lti_resource_handlers, [:tool_proxy_id, :resource_type_code], name: 'index_lti_resource_handlers_on_tool_proxy_and_type_code', unique: true
    add_index :lti_resource_placements, [:placement, :resource_handler_id], name: 'index_lti_resource_placements_on_placement_and_handler', unique: true
    add_index :lti_tool_proxies, [:root_account_id, :product_family_id, :product_version], name: 'index_lti_tool_proxies_on_root_account_prod_fam_and_prod_ver', unique: true
    add_index :lti_tool_proxy_bindings, [:context_id, :context_type, :tool_proxy_id], name: 'index_lti_tool_proxy_bindings_on_context_and_tool_proxy', unique: true
    add_index :lti_tool_proxies, [:guid]

    add_foreign_key :lti_product_families, :accounts, column: :root_account_id
    add_foreign_key :lti_message_handlers, :lti_resource_handlers, column: :resource_handler_id
    add_foreign_key :lti_resource_handlers, :lti_tool_proxies, column: :tool_proxy_id
    add_foreign_key :lti_resource_placements, :lti_resource_handlers, column: :resource_handler_id
    add_foreign_key :lti_tool_proxies, :lti_product_families, column: :product_family_id
    add_foreign_key :lti_tool_proxies, :accounts, column: :root_account_id
    add_foreign_key :lti_tool_proxy_bindings, :lti_tool_proxies, column: :tool_proxy_id

  end

  def self.down
    drop_table :lti_tool_proxy_bindings
    drop_table :lti_message_handlers
    drop_table :lti_resource_placements
    drop_table :lti_resource_handlers
    drop_table :lti_tool_proxies
    drop_table :lti_product_families
  end

end
