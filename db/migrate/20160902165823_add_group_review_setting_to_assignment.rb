class AddGroupReviewSettingToAssignment < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :intra_group_peer_reviews, :boolean
    change_column_default :assignments, :intra_group_peer_reviews, false
  end

  def self.down
    remove_column :assignments, :intra_group_peer_reviews
  end
end
