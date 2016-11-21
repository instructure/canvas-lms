class GradingPeriodGradeSummaryPresenter < GradeSummaryPresenter
  attr_reader :grading_period_id

  def initialize(context, current_user, id_param, assignment_order: :due_at, grading_period_id:)
    super(context, current_user, id_param, assignment_order: assignment_order)
    @grading_period_id = grading_period_id
  end

  def assignments_visible_to_student
    grading_period = GradingPeriod.for(@context).where(id: grading_period_id).first
    grading_period.assignments_for_student(super, student)
  end

  def groups
    @groups ||= begin
      assignments.uniq(&:assignment_group_id).map(&:assignment_group)
    end
  end
end
