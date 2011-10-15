class AddSisOptions < ActiveRecord::Migration

  def self.up
    add_column :sis_batches, :options, :text
  end

  def self.down
    drop_column :sis_batches, :options
  end

end
