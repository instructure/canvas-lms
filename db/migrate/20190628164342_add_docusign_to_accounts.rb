class AddDocusignToAccounts < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :accounts, :docusign_access_token, :text
    add_column :accounts, :docusign_refresh_token, :text
    add_column :accounts, :docusign_account_id, :text
    add_column :accounts, :docusign_base_uri, :text
    add_column :accounts, :docusign_token_expiration, :datetime

    add_column :users, :docusign_template_id, :text
  end
end
