class AddDeveloperKeyIdToLtiProductFamily < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :lti_product_families, :developer_key_id, :integer, limit: 8
    add_index :lti_product_families, :developer_key_id

    remove_index :lti_product_families, {column: [:root_account_id, :vendor_code, :product_code], name: 'index_lti_product_families_on_root_account_vend_code_prod_code', unique: true}
    add_index :lti_product_families, [:product_code, :vendor_code, :root_account_id, :developer_key_id], unique: true, name: 'product_family_uniqueness'
  end
end
