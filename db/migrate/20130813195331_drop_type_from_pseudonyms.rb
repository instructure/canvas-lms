class DropTypeFromPseudonyms < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :pseudonyms, :type
  end

  def self.down
    add_column :pseudonyms, :type, :string
  end
end
