class DeprecateHideFromStudentsOnWikiPages < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    change_column_default(:wiki_pages, :hide_from_students, nil)
    DataFixup::DeprecateHideFromStudentsOnWikiPages.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
  end

  def self.down
    change_column_default(:wiki_pages, :hide_from_students, false)
  end
end
