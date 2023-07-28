# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe Quizzes::QuizEligibility do
  before do
    course_with_student(active_all: true)
    @quiz = course_quiz(active: true)
    @eligibility = Quizzes::QuizEligibility.new(course: @course, user: @student, quiz: @quiz)
  end

  describe "#eligible?" do
    it "always returns true if the user is a teacher" do
      allow(@quiz).to receive(:grants_right?).and_return(false)
      allow(@quiz).to receive(:grants_right?)
        .with(anything, anything, :manage).and_return(true)

      expect(@eligibility).to be_eligible
      expect(@eligibility).to be_potentially_eligible
    end

    it "always returns true if the user can submit" do
      allow(@quiz).to receive(:grants_right?).and_return(false)
      allow(@quiz).to receive(:grants_right?)
        .with(anything, anything, :submit).and_return(true)

      expect(@eligibility).to be_eligible
      expect(@eligibility).to be_potentially_eligible
    end

    it "returns false if no course is provided" do
      allow(@eligibility).to receive(:course).and_return(nil)

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to_not be_potentially_eligible
    end

    it "returns false if the student is inactive" do
      allow(@user).to receive(:workflow_state).and_return("deleted")

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to_not be_potentially_eligible
    end

    it "returns false if a user cannot submit or read as an admin" do
      allow(@quiz).to receive(:grants_right?).and_return(false)
      allow(@course).to receive(:grants_right?).and_return(false)

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to_not be_potentially_eligible
    end

    it "returns true if a user can read as an admin" do
      allow(@quiz).to receive(:grants_right?).and_return(true)
      allow(@quiz).to receive(:grants_right?)
        .with(anything, anything, :manage).and_return(false)
      allow(@course).to receive(:grants_right?).and_return(false)
      allow(@course).to receive(:grants_right?)
        .with(anything, anything, :read_as_admin).and_return(true)

      expect(@eligibility).to be_eligible
      expect(@eligibility).to be_potentially_eligible
    end

    it "returns false if a quiz is access code restricted (but is still potentially_eligible)" do
      @quiz.access_code = "x"

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to be_potentially_eligible
    end

    it "returns false if a quiz is ip restricted (but is still potentially_eligible)" do
      @quiz.ip_filter = "1.1.1.1"

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to be_potentially_eligible
    end

    it "returns false if course is completed" do
      other_user = user_factory
      @course.enroll_student(other_user, enrollment_state: "complete")
      allow(@eligibility).to receive(:user).and_return(other_user)

      expect(@eligibility).to_not be_eligible
      expect(@eligibility).to_not be_potentially_eligible
    end

    it "otherwise returns true" do
      expect(@eligibility).to be_eligible
      expect(@eligibility).to be_potentially_eligible
    end
  end

  describe "#declined_reason_renders" do
    it "returns nil when no additional information should be rendered" do
      expect(@eligibility.declined_reason_renders).to be_nil
    end

    it "returns :access_code when an access code is needed" do
      @quiz.access_code = "x"
      expect(@eligibility.declined_reason_renders).to eq(:access_code)
    end

    it "returns :invalid_ip an invalid IP is used to attempt to take a quiz" do
      @quiz.ip_filter = "1.1.1.1"
      expect(@eligibility.declined_reason_renders).to eq(:invalid_ip)
    end
  end

  describe "#locked?" do
    it "returns false the quiz is not locked" do
      expect(@eligibility).to_not be_locked
    end

    it "returns false if quiz explicitly grant access to the user" do
      allow(@quiz).to receive_messages(locked_for?: true, grants_right?: true)
      expect(@eligibility).to_not be_locked
    end

    it "returns true if the quiz is locked and access is not granted" do
      allow(@quiz).to receive_messages(locked_for?: true, grants_right?: false)
      expect(@eligibility).to be_locked
    end
  end
end
