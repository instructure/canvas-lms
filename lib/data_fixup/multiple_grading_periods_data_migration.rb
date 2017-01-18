module DataFixup::MultipleGradingPeriodsDataMigration
  def self.run
    DataFixup::ReassociateGradingPeriodGroups.run
    DataFixup::MoveSubAccountGradingPeriodsToCourses.run
  end
end
