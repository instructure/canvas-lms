class AddPositionColumnToPollChoices < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :polling_poll_choices, :position, :integer
  end

  def self.down
    remove_column :polling_poll_choices, :position
  end
end
