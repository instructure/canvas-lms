# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative 'spec_components_assignable_module'

module SpecComponents
  class Quiz
    include Assignable

    def initialize(opts)
      course = opts[:course]
      quiz_title = opts.fetch(:title, 'Test Quiz')
      due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 7))

      assignment = course.assignments.create(title: quiz_title)
      assignment.workflow_state = 'published'
      assignment.submission_types = 'online_quiz'
      assignment.due_at = due_at
      assignment.save

      quiz = Quizzes::Quiz.where(assignment_id: assignment).first
      quiz.generate_quiz_data
      quiz.publish!
      quiz.save!

      @component_quiz = quiz
      @id = @component_quiz.id
      @title = @component_quiz.title
    end

    def assign_to(opts)
      add_assignment_override(@component_quiz, opts)
    end

    def submit_as(user)
      submission = @component_quiz.generate_submission user
      submission.workflow_state = 'complete'
      submission.save!
    end

    private

      def add_assignment_override_for_student(opts)
        super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
      end

      def add_assignment_override_for_section(opts)
        super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
      end
  end
end
