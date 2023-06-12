# frozen_string_literal: true

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

describe DataFixup::AddUserUuidToLearningOutcomeResults do
  let_once(:course) do
    Course.create!
  end

  let_once(:student) do
    user_model.tap do |user|
      course.enroll_student(user, active_all: true)
    end
  end

  let_once :quiz do
    quiz_model(assignment: course.assignments.create!)
  end

  let_once :learning_outcome_result do
    outcome = course.created_learning_outcomes.create!(title: "outcome")

    LearningOutcomeResult.new(
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: course,
                                      learning_outcome: outcome
                                    }),
      user: student
    ).tap do |lor|
      lor.association_object = quiz
      lor.context = course
      lor.associated_asset = quiz
      lor.save!
    end
  end

  it "sets learning outcome result user_uuid to user uuid" do
    result = learning_outcome_result
    result.update_column(:user_uuid, nil)

    expect(result.reload.user_uuid).to be_nil
    DataFixup::AddUserUuidToLearningOutcomeResults.run
    expect(result.reload.user_uuid).to eq(student.uuid)
  end
end
