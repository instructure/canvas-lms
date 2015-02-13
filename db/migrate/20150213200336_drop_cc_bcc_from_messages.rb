class DropCcBccFromMessages < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :messages, :cc
    remove_column :messages, :bcc
  end

  def down
    add_column :messages, :cc, :string
    add_column :messages, :bcc, :string
  end
end
