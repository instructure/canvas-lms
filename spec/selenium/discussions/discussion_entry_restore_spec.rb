# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../common"

describe "Restore Discussion Entry" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    before :once do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:restore_discussion_entry)
    end

    it "able to restore a deleted discussion entry" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher)
      entry = topic.discussion_entries.create!(message: "Test Entry", user: @teacher)
      entry.destroy

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      expect(f("body")).to contain_jqcss("[data-testid='threading-toolbar-restore']")

      f("button[data-testid='threading-toolbar-restore']").click

      expect(f("body")).to contain_jqcss("[data-testid='restore-entry-modal']")
      f("button[data-testid='restore-entry-submit']").click

      expect(f("[data-testid='discussion-root-entry-container']").text).to include("Test Entry")
    end

    it "able to restore a student's deleted discussion entry" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher)
      student = student_in_course(course: @course, name: "Student", active_all: true).user
      entry = topic.discussion_entries.create!(message: "Student Entry", user: student)
      entry.destroy

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      expect(f("body")).to contain_jqcss("[data-testid='threading-toolbar-restore']")

      f("button[data-testid='threading-toolbar-restore']").click

      expect(f("body")).to contain_jqcss("[data-testid='restore-entry-modal']")
      f("button[data-testid='restore-entry-submit']").click

      expect(f("[data-testid='discussion-root-entry-container']").text).to include("Student Entry")
    end

    it "able to restore a sub entry" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher, expanded: true)
      entry = topic.discussion_entries.create!(message: "Parent Entry", user: @teacher)
      sub_entry = topic.discussion_entries.create!(message: "Sub Entry", user: @teacher, parent_id: entry.id)
      sub_entry.destroy

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).to contain_jqcss("[data-testid='threading-toolbar-restore']")

      f("button[data-testid='threading-toolbar-restore']").click

      expect(f("body")).to contain_jqcss("[data-testid='restore-entry-modal']")
      f("button[data-testid='restore-entry-submit']").click

      expect(f("[data-testid='discussion-root-entry-container']").text).to include("Sub Entry")
    end
  end

  context "as a student" do
    before :once do
      course_with_teacher(active_all: true)
      @student = student_in_course(course: @course, name: "Student", active_all: true).user
      @course.enable_feature!(:restore_discussion_entry)
    end

    it "can restore a deleted discussion entry" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher)
      entry = topic.discussion_entries.create!(message: "Test Student Entry", user: @student)
      entry.editor = @student
      entry.destroy

      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).to contain_jqcss("[data-testid='threading-toolbar-restore']")
      f("button[data-testid='threading-toolbar-restore']").click

      expect(f("body")).to contain_jqcss("[data-testid='restore-entry-modal']")
      f("button[data-testid='restore-entry-submit']").click

      expect(f("[data-testid='discussion-root-entry-container']").text).to include("Test Student Entry")
    end

    it "cannot restore other peoples deleted discussion entries" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher)
      other_student = student_in_course(course: @course, name: "Other Student", active_all: true).user
      teacher_entry = topic.discussion_entries.create!(message: "Teacher Entry", user: @teacher)
      teacher_entry.destroy
      entry = topic.discussion_entries.create!(message: "Other Student Entry", user: other_student)
      entry.destroy

      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).not_to contain_jqcss("[data-testid='threading-toolbar-restore']")
    end

    it "cannot restore an entry which was deleted by a teacher" do
      topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message", user: @teacher)
      entry = topic.discussion_entries.create!(message: "Test Entry", user: @student)
      entry.editor = @teacher
      entry.destroy

      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).not_to contain_jqcss("[data-testid='threading-toolbar-restore']")
    end
  end
end
