module Filters::GradingPeriods
  def check_feature_flag
    unless multiple_grading_periods?
      if api_request?
        render json: {message: t('Page not found')}, status: :not_found
      else
        render status: 404, template: "shared/errors/404_message"
      end
    end
  end
end
