class FixUngradedCountsIncludeQuizEssays < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::FixUngradedCountsIncludeQuizEssays.send_later_if_production(:run)
  end

  def self.down
  end
end
