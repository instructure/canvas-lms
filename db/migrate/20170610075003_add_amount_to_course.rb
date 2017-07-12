class AddAmountToCourse < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :courses, :amount, :float
  end

  def self.down
    remove_column :courses, :amount, :float
  end
end
