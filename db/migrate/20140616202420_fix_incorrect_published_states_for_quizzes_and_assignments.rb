class FixIncorrectPublishedStatesForQuizzesAndAssignments < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixIncorrectPublishedStatesOnQuizzesAndAssignments.send_later_if_production(:run)
  end

  def self.down
  end
end
