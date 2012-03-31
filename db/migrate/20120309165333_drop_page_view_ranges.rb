class DropPageViewRanges < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    drop_table :page_view_ranges
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
