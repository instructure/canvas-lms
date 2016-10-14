class PopulateGradingPeriodCloseDates < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::PopulateGradingPeriodCloseDates.run
  end
end

