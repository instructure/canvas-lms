class GradingPeriodSerializer < Canvas::APISerializer
  include PermissionsSerializer
  root :grading_period

  attributes :id, :grading_period_group_id, :start_date, :end_date, :weight, :title, :permissions
end
