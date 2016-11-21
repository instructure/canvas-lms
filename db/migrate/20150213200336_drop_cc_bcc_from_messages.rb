class DropCcBccFromMessages < ActiveRecord::Migration[4.2]
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
