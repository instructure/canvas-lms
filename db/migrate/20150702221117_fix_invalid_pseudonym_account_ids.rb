class FixInvalidPseudonymAccountIds < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::FixInvalidPseudonymAccountIds.send_later_if_production(:run)
  end

end
