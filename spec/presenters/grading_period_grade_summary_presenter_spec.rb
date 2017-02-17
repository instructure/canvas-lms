require 'spec_helper'

describe GradingPeriodGradeSummaryPresenter do
  before(:once) do
    @course = Course.create!
    @student = User.create!
    @course.enroll_student(@student)
    root_account = @course.root_account
    grading_period_group = root_account.grading_period_groups.create!
    grading_period_group.enrollment_terms << @course.enrollment_term
    @now = Time.zone.now
    @period = grading_period_group.grading_periods.create!(
      title: "grading period",
      start_date: 10.days.ago(@now),
      end_date: 10.days.from_now(@now),
      close_date: 10.days.from_now(@now)
    )
    @first_group = @course.assignment_groups.create!(name: "first group")
    @assignment_due_in_period = @course.assignments.create!(
      assignment_group: @first_group,
      due_at: @now
    )

    @second_group = @course.assignment_groups.create!(name: "second group")
    @assignment_not_due_in_period = @course.assignments.create!(
      assignment_group: @second_group,
      due_at: 15.days.from_now(@now)
    )
  end

  let(:presenter) do
    GradingPeriodGradeSummaryPresenter.new(
      @course,
      @student,
      nil,
      grading_period_id: @period.id
    )
  end

  describe "#assignments_visible_to_student" do
    it "excludes assignments that are not due for the student in the given grading period" do
      expect(presenter.assignments_visible_to_student).not_to include(@assignment_not_due_in_period)
    end

    it "includes assignments that are due for the student in the given grading period" do
      expect(presenter.assignments_visible_to_student).to include(@assignment_due_in_period)
    end

    it "includes overridden assignments that are due for the student in the given grading period" do
      student_override = @assignment_not_due_in_period.assignment_overrides.create!(due_at: @now)
      student_override.assignment_override_students.create!(user: @student)
      expect(presenter.assignments_visible_to_student).to include(@assignment_not_due_in_period)
    end
  end

  describe "#groups" do
    it "excludes groups that have no assignments due in the given period for the given user" do
      expect(presenter.groups).not_to include(@second_group)
    end

    it "includes groups that have not-overridden assignments due in the given period for the given user" do
      expect(presenter.groups).to include(@first_group)
    end

    it "includes groups that have overridden assignments due in the given period for the given user" do
      student_override = @assignment_not_due_in_period.assignment_overrides.create!(due_at: @now)
      student_override.assignment_override_students.create!(user: @student)
      expect(presenter.groups).to include(@second_group)
    end

    it "does not include any duplicate groups" do
      @course.assignments.create!(
        assignment_group: @first_group,
        due_at: @now
      )
      group_ids = presenter.groups.map(&:id)
      expect(group_ids.uniq).to eq(group_ids)
    end
  end
end
