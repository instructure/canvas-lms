class FixDeletedEnrollmentStates < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::FixDeletedEnrollmentStates.send_later_if_production(:run)
  end

  def down
  end
end
