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

require_relative "../../helpers/gradebook_common"
require_relative "./gradebook_student_common"
require_relative "../setup/gradebook_setup"
require_relative "../pages/student_grades_page"

describe "Student Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  let(:assignments) do
    assignments = []
    (1..3).each do |i|
      assignment = @course.assignments.create!(
        title: "Assignment #{i}",
        points_possible: 20
      )
      assignments.push assignment
    end
    assignments
  end

  describe "Arrange By dropdown" do
    before :once do
      course_with_student(name: "Student", active_all: true)

      # create multiple assignments in different modules and assignment groups
      group0 = @course.assignment_groups.create!(name: "Physics Group")
      group1 = @course.assignment_groups.create!(name: "Chem Group")

      @assignment0 = @course.assignments.create!(
        name: "Physics Alpha Assign",
        due_at: Time.now.utc + 3.days,
        assignment_group: group0
      )

      @quiz = @course.quizzes.create!(
        title: "Chem Alpha Quiz",
        due_at: Time.now.utc + 5.days,
        assignment_group_id: group1.id
      )
      @quiz.publish!

      assignment = @course.assignments.create!(
        due_at: Time.now.utc + 5.days,
        assignment_group: group0
      )

      @discussion = @course.discussion_topics.create!(
        assignment:,
        title: "Physics Beta Discussion"
      )

      @assignment1 = @course.assignments.create!(
        name: "Chem Beta Assign",
        due_at: Time.now.utc + 6.days,
        assignment_group: group1
      )

      module0 = ContextModule.create!(name: "Beta Mod", context: @course)
      module1 = ContextModule.create!(name: "Alpha Mod", context: @course)

      module0.content_tags.create!(context: @course, content: @quiz, tag_type: "context_module")
      module0.content_tags.create!(context: @course, content: @assignment0, tag_type: "context_module")
      module1.content_tags.create!(context: @course, content: @assignment1, tag_type: "context_module")
      module1.content_tags.create!(context: @course, content: @discussion, tag_type: "context_module")
    end

    context "as a student" do
      it_behaves_like "Arrange By dropdown", :student
    end

    context "as a teacher" do
      it_behaves_like "Arrange By dropdown", :teacher
    end

    context "as an admin" do
      it_behaves_like "Arrange By dropdown", :admin
    end

    context "as a ta" do
      it_behaves_like "Arrange By dropdown", :ta
    end
  end
end
