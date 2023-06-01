# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe ScoreStatisticsGenerator do
  # Because this functionality has been transplanted out of the grade
  # summary presenter, there are tests there that check the
  # correctness of the assignments math. Tests in this file are currently
  # focused on the storage of generated data for the assignment stats.

  before :once do
    course_with_student active_all: true

    @assignments = Array.new(3) do |assignment_idx|
      @course.assignments.create!(
        title: assignment_idx.to_s,
        points_possible: 150
      )
    end

    # We need to create some graded submissions because without grades,
    # no stats are returned to store.
    scores = [10, 20]
    @assignments.each_with_index do |assignment, index|
      if scores[index]
        submission = Submission.find_by!(user: @student, assignment:)
        submission.update!(score: scores[index], workflow_state: "graded", posted_at: Time.now.utc)
      end
    end
  end

  it "queues an update using the appropriate strand / singleton" do
    delayed_job_args = {
      n_strand: ["ScoreStatisticsGenerator", @course.global_root_account_id],
      singleton: "ScoreStatisticsGenerator:#{@course.global_id}",
    }

    expect(ScoreStatisticsGenerator).to receive(:delay_if_production).with(hash_including(**delayed_job_args)).and_return(ScoreStatisticsGenerator)

    ScoreStatisticsGenerator.update_score_statistics_in_singleton(@course)
  end

  it "updates score statistics for all assignments with graded submissions" do
    ScoreStatistic.where(assignment: @assignments).destroy_all

    expect { ScoreStatisticsGenerator.update_score_statistics(@course.id) }.to change {
      ScoreStatistic.where(assignment: @assignments).size
    }.from(0).to(2)
  end

  it "updates course score statistic if graded/posted assignments exist" do
    CourseScoreStatistic.where(course: @course).destroy_all

    expect { ScoreStatisticsGenerator.update_score_statistics(@course.id) }.to change {
      CourseScoreStatistic.where(course: @course).size
    }.from(0).to(1)
  end

  it "removes course score statistic if no graded/posted assignments exist" do
    @course.submissions.update_all(posted_at: nil)
    @course.recompute_student_scores
    CourseScoreStatistic.create!(course_id: @course, average: 123, score_count: 234)

    expect { ScoreStatisticsGenerator.update_score_statistics(@course.id) }.to change {
      CourseScoreStatistic.where(course: @course).size
    }.from(1).to(0)
  end

  it "does not generate a score statistic if no graded/posted assignments exist" do
    @course.submissions.update_all(posted_at: nil)
    @course.recompute_student_scores
    CourseScoreStatistic.where(course: @course).destroy_all

    expect { ScoreStatisticsGenerator.update_score_statistics(@course.id) }.not_to change {
      CourseScoreStatistic.where(course: @course).size
    }
  end

  it "sets the root account ID for generated assignment score statistics" do
    ScoreStatisticsGenerator.update_score_statistics(@course.id)

    relevant_statistics = ScoreStatistic.joins(:assignment).where(assignments: { course: @course })
    expect(relevant_statistics.pluck(:root_account_id).uniq).to eq [@course.root_account_id]
  end

  context "course statistic math" do
    before(:once) do
      student2 = User.create!
      student3 = User.create!
      @course.enroll_student(student2, enrollment_state: :active)
      @course.enroll_student(student3, enrollment_state: :active)

      # student 1 should have 10% current score
      scores = {
        student2 => [100, 100, 100], # 66.67% current score
        student3 => [80, 90, 150] # 71.11% current score
      }
      scores.each do |student, student_scores|
        @assignments.each_with_index do |assignment, index|
          submission = Submission.find_by!(user: student, assignment:)
          submission.update!(score: student_scores[index], workflow_state: "graded", posted_at: Time.now.utc)
        end
      end
    end

    it "calculates the average when all enrollments are active" do
      # (10 + 66.67 + 71.11) / 3 = 49.26
      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(49.26)
    end

    it "stores the number of scores used in the calculation when all enrollments are active" do
      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(3)
    end

    it "ignores students that have no course score yet when calculating the average" do
      @course.student_enrollments.find_by(user_id: @student).scores.where(course_score: true).update_all(current_score: nil)
      ScoreStatisticsGenerator.update_course_score_statistic(@course.id)

      # (66.67 + 71.11) / 2 = 68.89
      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(68.89)
    end

    it "ignores students that have no course score yet when storing the score count" do
      @course.student_enrollments.find_by(user_id: @student).scores.where(course_score: true).update_all(current_score: nil)
      ScoreStatisticsGenerator.update_course_score_statistic(@course.id)

      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(2)
    end

    it "uses invited enrollments when it calculates the average" do
      @course.student_enrollments.find_by(user_id: @student).update!(workflow_state: :invited)
      @course.recompute_student_scores

      # (10 + 66.67 + 71.11) / 3 = 49.26
      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(49.26)
    end

    it "uses invited enrollments when stores the number of students used in the calculation" do
      @course.student_enrollments.find_by(user_id: @student).update!(workflow_state: :invited)
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(3)
    end

    it "ignores inactive enrollments when calculating average" do
      @course.student_enrollments.find_by(user_id: @student).deactivate
      @course.recompute_student_scores

      # (66.67 + 71.11) / 2 = 68.89
      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(68.89)
    end

    it "ignores inactive enrollments when counting students" do
      @course.student_enrollments.find_by(user_id: @student).deactivate
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(2)
    end

    it "ignores concluded enrollments when calculating average" do
      # (66.67 + 71.11) / 2 = 68.89
      @course.student_enrollments.find_by(user_id: @student).conclude
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(68.89)
    end

    it "ignores concluded enrollments when counting students" do
      @course.student_enrollments.find_by(user_id: @student).conclude
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(2)
    end

    it "ignores deleted enrollments when calculating average" do
      # (66.67 + 71.11) / 2 = 68.89
      @course.student_enrollments.find_by(user_id: @student).update!(workflow_state: :deleted)
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).average).to eq(68.89)
    end

    it "ignores deleted enrollments when counting students" do
      @course.student_enrollments.find_by(user_id: @student).update!(workflow_state: :deleted)
      @course.recompute_student_scores

      expect(CourseScoreStatistic.find_by(course: @course).score_count).to eq(2)
    end

    it "doesn't write to the database if the average is too large" do
      @course.student_enrollments.find_by(user_id: @student).scores.where(course_score: true).update_all(current_score: 10_000_000.0)

      expect(CourseScoreStatistic).not_to receive(:connection)
      ScoreStatisticsGenerator.update_course_score_statistic(@course.id)
    end

    it "doesn't write to the database if the average is too small" do
      @course.student_enrollments.find_by(user_id: @student).scores.where(course_score: true).update_all(current_score: -10_000_000.0)

      expect(CourseScoreStatistic).not_to receive(:connection)
      ScoreStatisticsGenerator.update_course_score_statistic(@course.id)
    end
  end
end
