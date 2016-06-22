class GradingPeriodSetSerializer < Canvas::APISerializer
  include PermissionsSerializer
  root :grading_period_set

  attributes :id,
             :title,
             :account_id,
             :course_id,
             :grading_periods,
             :permissions,
             :created_at

  def grading_periods
    @grading_periods ||= object.grading_periods.active.map do |period|
      GradingPeriodSerializer.new(period, controller: @controller, scope: @scope, root: false)
    end
  end

  def serializable_object
    stringify!(super)
  end
end
