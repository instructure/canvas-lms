# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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
#
# A QuizSubmission has many submission attempts, and each attempt has many
# versions (subsequent versions are from regrades). Typically when we ask for
# attempts we will want the most recent version of each attampt (last_versions)
#

class Quizzes::QuizSubmissionHistory
  extend Forwardable
  def_delegators :attempts, :length, :size, :[], :each, :last
  include Enumerable

  def initialize(quiz_submission)
    @submission = quiz_submission
  end

  def attempts
    @attempts ||= build_attempts(@submission)
  end

  def last_versions
    attempts.map { |attempt| attempt.versions.last }
  end

  def version_models
    last_versions.map do |version|
      model = version.model
      (model&.attempt == @submission.attempt) ? @submission : model
    end
  end

  def model_for(attempt)
    if attempt == @submission.attempt
      @submission
    else
      version_models.detect { |qs| qs.attempt == attempt }
    end
  end

  def kept
    @kept ||= if @submission.score == @submission.kept_score
                @submission
              else
                version_models.detect { |v| v.score == @submission.kept_score }
              end
  end

  private

  def build_attempts(quiz_submission)
    attempts = quiz_submission_attempts(quiz_submission).map do |num, versions|
      Quizzes::QuizSubmissionAttempt.new(number: num, versions:)
    end
    attempts.sort_by(&:number)
  end

  def quiz_submission_attempts(quiz_submission)
    quiz_submission.versions.reorder("number").each_with_object({}) do |ver, hash|
      hash[ver.model.attempt] ||= []
      hash[ver.model.attempt] << ver
    end
  end
end
