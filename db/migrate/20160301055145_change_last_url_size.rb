class ChangeLastUrlSize < ActiveRecord::Migration
  def change
    change_column :users, :last_url, :text
    change_column :users, :last_url_title, :text
  end
end
