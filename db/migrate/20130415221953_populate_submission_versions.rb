class PopulateSubmissionVersions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateSubmissionVersions.send_later_if_production(:run)
  end
end
