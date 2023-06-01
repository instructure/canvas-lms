# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Quizzes::QuizRegrader
  class Regrader
    attr_reader :quiz, :quiz_version_number

    def initialize(options)
      @quiz_version_number = options.fetch(:version_number, nil)
      @quiz = find_quiz_version(options.fetch(:quiz))
      @submissions = options.fetch(:submissions, nil)
    end

    def regrade!
      regrade = quiz.current_regrade
      return true unless regrade && !question_regrades.empty?

      Quizzes::QuizRegradeRun.perform(regrade) do
        submissions.each do |submission|
          Quizzes::QuizRegrader::Submission.new(
            submission: submission.latest_submitted_attempt,
            question_regrades:
          ).regrade!
        end
      end
    end

    def self.regrade!(options)
      Quizzes::QuizRegrader::Regrader.new(options).regrade!
    end

    def submissions
      # Using a class level scope here because if a restored "model" from a quiz
      # version is passed (e.g. during the grade_submission method on SubmissionGrader
      # submissions), the association will always be empty.
      @submissions ||= Quizzes::QuizSubmission.where(quiz_id: quiz.id).select { |qs| qs.latest_submitted_attempt.present? }
    end

    private

    def find_quiz_version(quiz)
      return quiz unless quiz_version_number.present?

      Version.where(
        versionable_type: Quizzes::Quiz.class_names,
        versionable_id: quiz.id,
        number: quiz_version_number
      ).first.model
    end

    # quiz question regrades keyed by question id
    def question_regrades
      @question_regrades ||= @quiz.current_quiz_question_regrades.index_by(&:quiz_question_id)
    end
  end
end
