#
# Copyright (C) 2016 Instructure, Inc.
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
#

require 'spec_helper'

describe DataFixup::PopulateScoresTable do
  before(:once) do
    @course1 = Course.create!
    @course2 = Course.create!

    @student1_enrollment = student_in_course(course: @course1, active_all: true)
    @student1_enrollment.computed_current_score = 76.3
    @student1_enrollment.computed_final_score = 24
    @student1_enrollment.save

    @student2_enrollment = student_in_course(course: @course1, active_all: true)
    @student2_enrollment.computed_final_score = 56.5
    @student2_enrollment.save

    @student3_enrollment = student_in_course(course: @course2, active_all: true)
    @student3_enrollment.computed_current_score = 56.5
    @student3_enrollment.save
    @student4_enrollment = student_in_course(course: @course2, active_all: true)
  end

  it "copies existing enrollment scores to their own Scores table" do
    expect { DataFixup::PopulateScoresTable.run }.to change { Score.count }.from(0).to(4)
                                                .and change { @student1_enrollment.scores.count }.from(0).to(1)
                                                .and change { @student2_enrollment.scores.count }.from(0).to(1)
                                                .and change { @student3_enrollment.scores.count }.from(0).to(1)
                                                .and change { @student4_enrollment.scores.count }.from(0).to(1)
    expect(Score.pluck(:current_score, :final_score)).to match_array([[76.3, 24], [nil, 56.5], [56.5, nil], [nil, nil]])
    expect(Score.pluck(:grading_period_id)).to eq([nil, nil, nil, nil])
  end

  it "does not copy enrollment scores if the relevant Score object already exists" do
    @student2_enrollment.scores.create!(grading_period_id: nil, final_score: 29.3)
    create_grading_periods_for(@course2)
    gp = @course2.grading_periods.first
    @student3_enrollment.scores.where(grading_period: gp).first.update(final_score: 100.3)
    @student3_enrollment.scores.where(grading_period_id: nil).first.delete
    expect { DataFixup::PopulateScoresTable.run }.to change { Score.count }.from(4).to(6)
                                                .and change { @student3_enrollment.scores.count }.from(1).to(2)
    expect(Score.where(grading_period: nil).pluck(:current_score, :final_score)).to match_array(
      [[76.3, 24], [nil, 29.3], [56.5, nil], [nil, nil]]
    )
    expect(Score.pluck(:grading_period_id)).to match_array([nil, nil, gp.id, gp.id, nil, nil])
  end

  it "creates Score object for each grading period, if one doesn't already exist" do
    grader1 = teacher_in_course(course: @course1, active_all: true).user
    grader2 = teacher_in_course(course: @course2, active_all: true).user
    group1 = @course1.grading_period_groups.create!
    gp1 = group1.grading_periods.create!(title: "Way long ago", start_date: 1.year.ago, end_date: 4.months.ago)
    gp2 = group1.grading_periods.create!(title: "Long ago", start_date: 3.months.ago, end_date: 1.day.ago)
    assignment1 = @course1.assignments.create!(due_at: 7.months.ago, points_possible: 100)
    assignment1.grade_student(@student1_enrollment.user, grader: grader1, score: 47.4)
    assignment1.grade_student(@student2_enrollment.user, grader: grader1, score: 51.0)
    assignment2 = @course1.assignments.create!(due_at: 1.month.ago, points_possible: 100)
    assignment2.grade_student(@student1_enrollment.user, grader: grader1, score: 53.0)
    group2 = @course2.grading_period_groups.create!
    gp3 = group2.grading_periods.create!(title: "Way long ago", start_date: 1.year.ago, end_date: 4.months.ago)
    group2.grading_periods.create!(title: "Long ago", start_date: 3.months.ago, end_date: 1.day.ago)
    assignment3 = @course2.assignments.create!(due_at: 7.months.ago, points_possible: 100)
    assignment3.grade_student(@student3_enrollment.user, grader: grader2, score: 10)
    assignment3.grade_student(@student4_enrollment.user, grader: grader2, score: 20)
    assignment4 = @course2.assignments.create!(due_at: 6.months.ago, points_possible: 100)
    assignment4.grade_student(@student3_enrollment.user, grader: grader2, score: 30)
    Score.where.not(grading_period_id: nil).delete_all

    expect { DataFixup::PopulateScoresTable.run }.to change { Score.count }.from(4).to(10)
                                                .and change { @student1_enrollment.scores.count }.from(1).to(3)
                                                .and change { @student2_enrollment.scores.count }.from(1).to(3)
                                                .and change { @student3_enrollment.scores.count }.from(1).to(2)
                                                .and change { @student4_enrollment.scores.count }.from(1).to(2)
    expect(Score.pluck(:current_score)).to match_array(
      [50.2, 51, 20, 20, 47.4, 53.0, 51.0, nil, 20, 20]
    )
    expect(Score.pluck(:grading_period_id)).to match_array(
      [nil, nil, nil, nil, gp1.id, gp1.id, gp2.id, gp2.id, gp3.id, gp3.id]
    )
  end
end
