class PopulateStreamItemAssociations < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateStreamItemAssociations.send_later_if_production(:run)
  end

  def self.down
  end
end
