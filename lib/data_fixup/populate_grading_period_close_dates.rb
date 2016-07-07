module DataFixup::PopulateGradingPeriodCloseDates
  def self.run
    GradingPeriod.
      where(close_date: nil).
      where.not(end_date: nil).
      update_all("close_date=end_date")
  end
end
