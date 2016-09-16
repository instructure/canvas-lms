module GradingPeriodHelper
  def self.date_in_closed_grading_period?(date, periods)
    return false if periods.empty?

    if date.nil?
      periods.sort_by(&:end_date).last.closed?
    else
      periods.any? do |period|
        period.in_date_range?(date) && period.closed?
      end
    end
  end
end
