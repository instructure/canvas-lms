class FixHiddenWikiFrontPages < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    WikiPage.find_ids_in_ranges do |first, last|
      WikiPage.where("url = ? AND hide_from_students = ? AND id >= ? AND id <= ?", 'front-page', true, first, last).
          update_all(:hide_from_students => false)
    end
  end

  def self.down
  end
end
