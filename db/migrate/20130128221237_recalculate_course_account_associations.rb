class RecalculateCourseAccountAssociations < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # a bug was fixed in Course.update_account_associations; we need to recalculate them all
    DataFixup::RecalculateCourseAccountAssociations.send_later_if_production(:run)
  end
end
