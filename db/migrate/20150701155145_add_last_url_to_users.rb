class AddLastUrlToUsers < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :users, :last_url, :string
    add_column :users, :last_url_title, :string
  end
end
