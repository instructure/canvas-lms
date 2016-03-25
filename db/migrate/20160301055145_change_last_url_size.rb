class ChangeLastUrlSize < ActiveRecord::Migration
  tag :predeploy
  def change
    change_column :users, :last_url, :text
    change_column :users, :last_url_title, :text
  end
end
