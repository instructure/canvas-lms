# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::BackfillBodyWordCount do
  before do
    course_with_teacher(active_all: true)
    user_session(@teacher)

    @student = User.create!
    @course.enroll_student(@student, enrollment_state: "active")
    @assignment = @course.assignments.create!(submission_types: "online_text_entry", points_possible: 10)
    @assignment.submit_homework(@student, body: "two words")
    run_jobs # body_word_count is set in a delayed job
    @submission = @assignment.submissions.find_by(user: @student)
    @submission.update!(body_word_count: nil)
  end

  describe "submissions" do
    it "updates the body_word_count" do
      expect { DataFixup::BackfillBodyWordCount.run }.to change {
        @submission.reload.body_word_count
      }.from(nil).to(2)
    end

    it "ignores submissions that already have a body_word_count" do
      @submission.update_columns(body_word_count: 42)
      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.reload.body_word_count
      }.from(42)
    end

    it "ignores submissions updated before the cutoff" do
      Timecop.freeze(DataFixup::BackfillBodyWordCount::DATAFIX_CUTOFF - 1.day) do
        assignment = @course.assignments.create!(submission_types: "online_text_entry", points_possible: 10)
        assignment.submit_homework(@student, body: "two words")
        @submission = assignment.submissions.find_by(user: @student)
        @submission.update_columns(body_word_count: nil)
      end

      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.reload.body_word_count
      }.from(nil)
    end

    it "ignores submissions without a body" do
      new_student = User.create!
      @course.enroll_student(new_student, enrollment_state: "active")
      submission = @assignment.submissions.find_by(user: new_student)
      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        submission.reload.body_word_count
      }.from(nil)
    end
  end

  describe "versions" do
    it "does not create new versions" do
      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.versions.count
      }.from(1)
    end

    it "updates the body_word_count" do
      @assignment.submit_homework(@student, body: "has three words!")
      expect { DataFixup::BackfillBodyWordCount.run }.to change {
        @submission.reload.versions.reorder(:number).map { |v| v.model.body_word_count }
      }.from([nil, nil]).to([2, 3])
    end

    it "ignores versions that already have a body_word_count" do
      version = @submission.versions.first
      model = version.model
      model.body_word_count = 42
      version.update_columns(yaml: model.attributes.to_yaml)
      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.reload.versions.first.model.body_word_count
      }.from(42)
    end

    it "ignores versions created before the cutoff" do
      Timecop.freeze(DataFixup::BackfillBodyWordCount::DATAFIX_CUTOFF - 1.day) do
        assignment = @course.assignments.create!(submission_types: "online_text_entry", points_possible: 10)
        assignment.submit_homework(@student, body: "two words")
        @submission = assignment.submissions.find_by(user: @student)
      end

      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.reload.versions.first.model.body_word_count
      }.from(nil)
    end

    it "ignores versions without a body" do
      version = @submission.versions.first
      model = version.model
      model.body = nil
      version.update_columns(yaml: model.attributes.to_yaml)
      expect { DataFixup::BackfillBodyWordCount.run }.not_to change {
        @submission.reload.versions.first.model.body_word_count
      }.from(nil)
    end
  end
end
