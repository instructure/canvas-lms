class InitializeSubmissionLateness < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::InitializeSubmissionLateness.send_later_if_production(:run)
  end

  def self.down
  end
end
