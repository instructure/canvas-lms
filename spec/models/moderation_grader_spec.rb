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

describe ModerationGrader do
  subject { ModerationGrader.create!(user: @user, assignment: @assignment, anonymous_id: "aaaaa") }

  before(:once) do
    course_with_teacher
    @assignment = @course.assignments.create!(title: "test assignment")
  end

  it "requires a specific format for the anonymous_id" do
    common_params = { user: @user, assignment: @assignment }
    expect(ModerationGrader.new(**common_params, anonymous_id: "AaZz0")).to be_valid
    expect(ModerationGrader.new(**common_params, anonymous_id: "AaZz+")).not_to be_valid
    expect(ModerationGrader.new(**common_params, anonymous_id: "AaZz")).not_to be_valid
    expect(ModerationGrader.new(**common_params, anonymous_id: "AaZz99")).not_to be_valid
  end

  describe "#with_slot_taken" do
    before(:once) do
      course = Course.create!
      @teacher = User.create!
      course.enroll_teacher(@teacher, enrollment_state: :active)
      @assignment = course.assignments.create!(moderated_grading: true, grader_count: 2)
    end

    it "includes moderation graders that have taken a slot" do
      @assignment.create_moderation_grader(@teacher, occupy_slot: true)
      expect(@assignment.moderation_graders.with_slot_taken.pluck(:user_id)).to include @teacher.id
    end

    it "excludes moderation graders that have not taken a slot" do
      @assignment.create_moderation_grader(@teacher, occupy_slot: false)
      expect(@assignment.moderation_graders.with_slot_taken.pluck(:id)).not_to include @teacher.id
    end
  end
end
