module GradingPeriodHelper
  def self.date_in_closed_grading_period?(date, periods)
    if date.nil?
      last_period = periods.sort_by(&:end_date).last
      last_period && last_period.closed?
    else
      periods.any? do |period|
        period.in_date_range?(date) && period.closed?
      end
    end
  end
end
