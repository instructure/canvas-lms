class CreateBrandConfigs < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  LENGTH_OF_AN_MD5_HASH = 32

  def up
    create_table :brand_configs, id: false do |t|
      t.string :md5, limit: LENGTH_OF_AN_MD5_HASH, null: false, unique: true
      t.column :variables, :text, null: false
      t.boolean :share, default: false, null: false
      t.string :name
      t.datetime :created_at, null: false
    end
    # because we didn't use the rails default `id` int primary key, we have to add it manually
    execute %{ ALTER TABLE #{BrandConfig.quoted_table_name} ADD PRIMARY KEY (md5); }
    add_index :brand_configs, :share

    add_column      :accounts, :brand_config_md5, :string, limit: LENGTH_OF_AN_MD5_HASH
    add_foreign_key :accounts, :brand_configs, column: 'brand_config_md5', primary_key: 'md5'
    add_index       :accounts, :brand_config_md5, where: 'brand_config_md5 IS NOT NULL', algorithm: :concurrently
  end

  def down
    remove_column :accounts, :brand_config_md5
    drop_table :brand_configs
  end

end
