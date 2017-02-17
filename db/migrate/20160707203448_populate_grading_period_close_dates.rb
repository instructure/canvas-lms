class PopulateGradingPeriodCloseDates < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::PopulateGradingPeriodCloseDates.run
  end
end

