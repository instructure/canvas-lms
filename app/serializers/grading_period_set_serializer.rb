class GradingPeriodSetSerializer < Canvas::APISerializer
  include PermissionsSerializer
  root :grading_period_set

  attributes :id,
             :title,
             :account_id,
             :course_id,
             :permissions
end
