class AddReplaceTokensToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :developer_keys, :replace_tokens, :boolean
  end
end
