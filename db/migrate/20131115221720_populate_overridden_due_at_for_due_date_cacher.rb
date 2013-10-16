class PopulateOverriddenDueAtForDueDateCacher < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateOverriddenDueAtForDueDateCacher.send_later_if_production(:run)
  end
end
