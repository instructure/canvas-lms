class FixHiddenWikiFrontPages < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    WikiPage.where(:url => 'front-page', :hide_from_students => true).update_all(:hide_from_students => false)
  end

  def self.down
  end
end
