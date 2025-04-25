# frozen_string_literal: true

#
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

require_relative "../../common"

module Modules2IndexPage
  #------------------------------ Selectors -----------------------------
  def student_modules_container_selector
    "[data-testid='modules-rewrite-student-container']"
  end

  def teacher_modules_container_selector
    "[data-testid='modules-rewrite-container']"
  end
  #------------------------------ Elements ------------------------------

  def student_modules_container
    f(student_modules_container_selector)
  end

  def teacher_modules_container
    f(teacher_modules_container_selector)
  end
  #------------------------------ Actions -------------------------------

  def set_rewrite_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite) : @course.root_account.disable_feature!(:modules_page_rewrite)
  end

  def modules2_teacher_setup
    course_with_teacher(active_all: true)
    course_modules_setup
  end

  def modules2_student_setup
    course_with_student(active_all: true)
    course_modules_setup
  end

  def course_modules_setup
    set_rewrite_flag
    @quiz = @course.assignments.create!(title: "quiz assignment", submission_types: "online_quiz")
    @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
    @assignment2 = @course.assignments.create!(title: "assignment 2",
                                               submission_types: "online_text_entry",
                                               due_at: 2.days.from_now,
                                               points_possible: 10)
    @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")

    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2")
    @module1.add_item({ id: @assignment.id, type: "assignment" })
    @module1.add_item({ id: @assignment2.id, type: "assignment" })
    @module2.add_item({ id: @assignment3.id, type: "assignment" })
    @module2.add_item({ id: @quiz.id, type: "quiz" })

    @course.reload
  end
end
