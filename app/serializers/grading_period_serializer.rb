class GradingPeriodSerializer < Canvas::APISerializer
  root :grading_period

  attributes :id, :course_id, :account_id, :start_date, :end_date, :weight, :title
end
