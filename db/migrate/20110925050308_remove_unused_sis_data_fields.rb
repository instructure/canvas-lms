class RemoveUnusedSisDataFields < ActiveRecord::Migration
  def self.up
    remove_column :pseudonyms, :sis_update_data
    remove_column :enrollment_terms, :sis_data
  end

  def self.down
    add_column :enrollment_terms, :sis_data, :text
    add_column :pseudonyms, :sis_update_data, :text
  end
end
