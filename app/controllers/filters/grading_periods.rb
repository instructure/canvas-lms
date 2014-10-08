module Filters::GradingPeriods
  def check_feature_flag
    unless multiple_grading_periods?
      render status: 404, template: "shared/errors/404_message"
    end
  end
end
