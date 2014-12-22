class GradingPeriodSerializer < Canvas::APISerializer
  root :grading_period

  attributes :id, :start_date, :end_date, :weight, :title
end
