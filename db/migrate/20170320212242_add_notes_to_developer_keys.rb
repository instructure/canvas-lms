class AddNotesToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :developer_keys, :notes, :text
  end
end
