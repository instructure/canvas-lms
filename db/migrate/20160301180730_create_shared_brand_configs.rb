class CreateSharedBrandConfigs < ActiveRecord::Migration[4.2]
  tag :predeploy
  LENGTH_OF_AN_MD5_HASH = 32


  def up
    create_table :shared_brand_configs do |t|
      t.string :name
      t.references :account, null: true, limit: 8, index: true, foreign_key: true
      t.string :brand_config_md5, limit: LENGTH_OF_AN_MD5_HASH, null: false, index: true
      t.timestamps null: false
    end
    add_foreign_key :shared_brand_configs, :brand_configs, column: 'brand_config_md5', primary_key: 'md5'

    # Move the existing "shared" brand configs that we made into the new shared_brand_configs_table.
    # In the postdeploy migration that comes after this, we drop the `name` and `share` columns from brand_configs.
    BrandConfig.where(share: true).find_each do |brand_config|
      SharedBrandConfig.create(name: brand_config.name, brand_config_md5: brand_config.md5)
    end
  end

  def down
    # restore the globally shared ones (like "K12 Theme") back
    SharedBrandConfig.where(account_id: nil).find_each do |shared_brand_config|
      shared_brand_config.brand_config.name = shared_brand_config.name
      shared_brand_config.brand_config.share = true
      shared_brand_config.brand_config.save_without_callbacks
    end
    drop_table :shared_brand_configs
  end
end
