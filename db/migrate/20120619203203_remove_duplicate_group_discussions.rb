class RemoveDuplicateGroupDiscussions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    # run in migration so that that unique index can be created immediately after
    DataFixup::RemoveDuplicateGroupDiscussions.run
  end

  def self.down
  end
end
