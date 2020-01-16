#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

shared_context 'no grading period or assignment group weighting' do
  before(:each) do
    # C3058158
    @gpg.update(weighted: false)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update(group_weighting_scheme: "points")
  end
end

shared_context 'assignment group weights' do
  before(:each) do
    # C3058159
    @gpg.update(weighted: false)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update(group_weighting_scheme: "percent")
  end
end

shared_context 'grading period weights' do
  before(:each) do
    # C3058160
    @gpg.update(weighted: true)
    @gp1.update(weight: 30)
    @gp2.update(weight: 70)
    # assignment weighting: `percent` is on, 'points' is off
    @course.update(group_weighting_scheme: "points")
  end
end

shared_context 'both grading period and assignment group weights' do
  before(:each) do
    # C3058161
    @gpg.update(weighted: true)
    @gp1.update(weight: 30)
    @gp2.update(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "percent")
  end
end

shared_context 'grading period weights with ungraded assignment' do
  before(:each) do
    # C 47.67%"

    @gpg.update(weighted: true)
    @gp1.update(weight: 30)
    @gp2.update(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "points")

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
    @gpg.update(weighted: true)
    @gp1.update(weight: 30)
    @gp2.update(weight: 70)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "percent")

    @a2.update(due_at: 3.weeks.ago)
  end
end

shared_context 'assign outside of unweighted grading period' do
  before(:each) do
    # C3058165
    @gpg.update(weighted: false)
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "percent")

    @a2.update(due_at: 3.weeks.ago)
  end
end

shared_context 'no grading periods or assignment weighting' do
  before(:each) do
    # C3058162
    associate_course_to_term("Default Term")
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "points")

    @a2.update(due_at: 3.weeks.ago)
  end
end

shared_context 'assignment weighting and no grading periods' do
  before(:each) do
    # C3058163
    associate_course_to_term("Default Term")
    # assignment weighting: 'percent' is on, 'points' is off
    @course.update(group_weighting_scheme: "percent")

    @a2.update(due_at: 3.weeks.ago)
  end
end
