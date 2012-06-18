class CountExistingCollectionItemsAndFollowers < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::CountExistingCollectionItemsAndFollowers.send_later_if_production(:run)
  end

  def self.down
  end
end
