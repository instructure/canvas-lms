class DropAssetContextCodeFromMessages < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    remove_column :messages, :asset_context_code, :string, limit: 255
  end
end
