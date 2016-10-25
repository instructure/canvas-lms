module GradebookSetup
  include Factories

  def backend_group_helper
    Factories::GradingPeriodGroupHelper.new
  end

  def backend_period_helper
    Factories::GradingPeriodHelper.new
  end

  def create_multiple_grading_periods(term_name)
    Account.default.enable_feature!(:multiple_grading_periods)

    set1 = backend_group_helper.create_for_account_with_term(Account.default, term_name, "Set 1")
    @gp_closed = backend_period_helper.create_for_group(set1, closed_attributes)
    @gp_ended = backend_period_helper.create_for_group(set1, ended_attributes)
    @gp_current = backend_period_helper.create_for_group(set1, current_attributes)
  end

  def add_teacher_and_student
    course(active_all: true)
    student_in_course
  end

  def associate_course_to_term(term_name)
    @course.enrollment_term = Account.default.enrollment_terms.find_by(name: term_name)
    @course.save!
    @course.reload
  end

  def closed_attributes
    now = Time.zone.now
    {
        title: "GP Closed",
        start_date: 3.weeks.ago(now),
        end_date: 2.weeks.ago(now)
    }
  end

  def ended_attributes
    now = Time.zone.now
    {
        title: "GP Ended",
        start_date: 2.weeks.ago(now),
        end_date: 2.days.ago(now),
        close_date: 2.days.from_now
    }
  end

  def current_attributes
    now = Time.zone.now
    {
        title: "GP Current",
        start_date: 1.day.ago(now),
        end_date: 2.weeks.from_now
    }
  end
end
