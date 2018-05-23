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

require_relative '../spec_helper'

describe AssignmentScoreStatisticsGenerator do
  # Because this functionality has been transplanted out of the grade
  # summary presenter, there are tests there that check the
  # correctness of the math. Tests in this file are currently focused
  # on the storage of generated data

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
        submission = Submission.find_by!(user: @student, assignment: assignment)
        submission.update!(score: scores[index], workflow_state: 'graded')
      end
    end
  end

  it 'updates score statistics for all assignments with graded submissions' do
    ScoreStatistic.where(assignment: @assignments).destroy_all

    expect { AssignmentScoreStatisticsGenerator.update_score_statistics(@course.id) }.to change {
      ScoreStatistic.where(assignment: @assignments).size
    }.from(0).to(2)
  end

end
