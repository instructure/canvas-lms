class AddAutoExpireTokensToDeveloperKey < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :developer_keys, :auto_expire_tokens, :boolean
  end

end
