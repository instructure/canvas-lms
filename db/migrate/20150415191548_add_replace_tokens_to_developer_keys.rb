class AddReplaceTokensToDeveloperKeys < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :developer_keys, :replace_tokens, :boolean
  end
end
