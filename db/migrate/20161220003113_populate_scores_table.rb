class PopulateScoresTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    DataFixup::PopulateScoresTable.run
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
