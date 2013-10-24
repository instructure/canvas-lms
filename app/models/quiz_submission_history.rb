# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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
class QuizSubmissionHistory
  extend Forwardable
  def_delegators :@attempts, :length, :size, :[], :each, :last
  include Enumerable

  def initialize(quiz_submission)
    @attempts = build_attempts(quiz_submission)
  end

  def last_versions
    @attempts.map {|attempt| attempt.versions.last }
  end

  def version_models
    last_versions.map {|version| version.model }
  end


  private

  def build_attempts(quiz_submission)
    attempts = quiz_submission_attempts(quiz_submission).map do |num, versions|
      QuizSubmissionAttempt.new(:number => num, :versions => versions)
    end
    attempts.sort_by {|a| a.number }
  end

  def quiz_submission_attempts(quiz_submission)
    quiz_submission.versions.reorder("number").each_with_object({}) do |ver, hash|
      hash[ver.model.attempt] ||= []
      hash[ver.model.attempt] << ver
    end
  end
end