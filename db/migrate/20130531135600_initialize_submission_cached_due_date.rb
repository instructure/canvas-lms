class InitializeSubmissionCachedDueDate < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::InitializeSubmissionCachedDueDate.send_later_if_production(:run)
  end

  def self.down
  end
end
