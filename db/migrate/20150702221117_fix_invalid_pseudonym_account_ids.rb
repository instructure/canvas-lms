class FixInvalidPseudonymAccountIds < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::FixInvalidPseudonymAccountIds.send_later_if_production(:run)
  end

end
