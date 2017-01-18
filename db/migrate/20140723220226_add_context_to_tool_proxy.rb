class AddContextToToolProxy < ActiveRecord::Migration
  tag :predeploy

  def self.up
    remove_index :lti_tool_proxies, name: 'index_lti_tool_proxies_on_root_account_prod_fam_and_prod_ver'
    remove_foreign_key :lti_tool_proxies, column: :root_account_id

    rename_column :lti_tool_proxies, :root_account_id, :context_id
    add_column :lti_tool_proxies, :context_type, :string, null: false, default: 'Account'
    change_column :lti_tool_proxies, :context_type, :string, null:false

  end

  def self.down

    Lti::ToolProxy.where("context_type <> 'Account'").preload(:context).each do |tp|
      tp.context_id = tp.context.root_account_id
      tp.save
    end

    rename_column :lti_tool_proxies, :context_id, :root_account_id
    remove_column :lti_tool_proxies, :context_type
    add_index :lti_tool_proxies, [:root_account_id, :product_family_id, :product_version], name: 'index_lti_tool_proxies_on_root_account_prod_fam_and_prod_ver', unique: true
    add_foreign_key :lti_tool_proxies, :accounts, column: :root_account_id

  end

end
