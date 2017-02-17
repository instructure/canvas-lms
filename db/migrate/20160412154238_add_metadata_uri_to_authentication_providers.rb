class AddMetadataUriToAuthenticationProviders < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :account_authorization_configs, :metadata_uri, :string
    add_index :account_authorization_configs, :metadata_uri, where: "metadata_uri IS NOT NULL"
  end
end
