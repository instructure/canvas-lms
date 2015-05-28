
# Copyright (C) 2014 Instructure, Inc.
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
# Outstanding Quiz Submissions Manager
#
# API for accessing quiz submissions which we term "outstanding" in that they are
# unsubmitted, started, and overdue.
#
# These submissions can be found by #find_by_quiz, at the
# API level, and graded internally by #grade_by_course
# or at the API by #grade_by_ids
#
module Quizzes
  class OutstandingQuizSubmissionManager

    def initialize(quiz)
      @quiz = quiz
    end

    def self.grade_by_course(course)
      Quizzes::QuizSubmission.where('quizzes.context_id =?', course.id)
        .includes(:quiz)
        .needs_grading
        .each do |quiz_submission|
          Quizzes::SubmissionGrader.new(quiz_submission).grade_submission({
            finished_at: quiz_submission.finished_at_fallback
          })
        end
    end

    def grade_by_ids(quiz_submission_ids)
      quiz_submissions = @quiz.quiz_submissions.where(id: quiz_submission_ids)
      quiz_submissions.select(&:needs_grading?).each do |quiz_submission|
        Quizzes::SubmissionGrader.new(quiz_submission).grade_submission({
          finished_at: quiz_submission.finished_at_fallback
        })
      end
    end

    def find_by_quiz
      # Find these in batches, so as to reduce the memory load
      outstanding_qs = []
      outstanding_qs = Quizzes::QuizSubmission.where("quiz_id = ?", @quiz.id)
        .needs_grading
        .includes(:user)
      outstanding_qs
    end
  end
end
