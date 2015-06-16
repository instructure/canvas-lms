class GradingPeriodSerializer < Canvas::APISerializer
  include PermissionsSerializer
  root :grading_period

  attributes :id, :start_date, :end_date, :weight, :title, :permissions
end
