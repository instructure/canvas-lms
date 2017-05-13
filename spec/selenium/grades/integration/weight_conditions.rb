shared_context 'no grading period or assignment group weighting' do
  before(:each) do
    # C3058158
    @gpg.update_attributes(weighted: false)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "points")
  end
end

shared_context 'assignment group weights' do
  before(:each) do
    # C3058159
    @gpg.update_attributes(weighted: false)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "percent")
  end
end

shared_context 'grading period weights' do
  before(:each) do
    # C3058160
    @gpg.update_attributes(weighted: true)
    @gp1.update_attributes(weight: 30)
    @gp2.update_attributes(weight: 70)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "points")
  end
end

shared_context 'both grading period and assignment group weights' do
  before(:each) do
    # C3058161
    @gpg.update_attributes(weighted: true)
    @gp1.update_attributes(weight: 30)
    @gp2.update_attributes(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "percent")
  end
end

shared_context 'grading period weights with ungraded assignment' do
  before(:each) do
    # C 47.67%"

    @gpg.update_attributes(weighted: true)
    @gp1.update_attributes(weight: 30)
    @gp2.update_attributes(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "points")

    @a5 = @course.assignments.create!(
      title: 'assignment five',
      grading_type: 'points',
      points_possible: 10,
      assignment_group: @ag3,
      due_at: 1.week.from_now
    )
  end
end

shared_context 'assign outside of weighted grading period' do
  before(:each) do
    # C3058164
    @gpg.update_attributes(weighted: true)
    @gp1.update_attributes(weight: 30)
    @gp2.update_attributes(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "percent")

    @a2.update_attributes(due_at: 3.weeks.ago)
  end
end

shared_context 'assign outside of unweighted grading period' do
  before(:each) do
    # C3058165
    @gpg.update_attributes(weighted: false)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "percent")

    @a2.update_attributes(due_at: 3.weeks.ago)
  end
end

shared_context 'no grading periods or assignment weighting' do
  before(:each) do
    # C3058162
    associate_course_to_term("Default Term")
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "points")

    @a2.update_attributes(due_at: 3.weeks.ago)
  end
end

shared_context 'assignment weighting and no grading periods' do
  before(:each) do
    # C3058163
    associate_course_to_term("Default Term")
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update_attributes(group_weighting_scheme: "percent")

    @a2.update_attributes(due_at: 3.weeks.ago)
  end
end
