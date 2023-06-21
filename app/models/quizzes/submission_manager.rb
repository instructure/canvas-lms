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

module Quizzes
  class SubmissionManager
    def initialize(quiz)
      @quiz = quiz
    end

    def find_or_create_submission(user, temporary = false, state = nil)
      s = nil
      state ||= "untaken"
      @quiz.shard.activate do
        Quizzes::QuizSubmission.unique_constraint_retry do
          query_hash = if !user.is_a?(::User)
                         { temporary_user_code: user.to_s }
                       elsif temporary
                         { temporary_user_code: "user_#{user.id}" }
                       else
                         { user_id: user.id }
                       end

          s = @quiz.quiz_submissions.where(query_hash).first
          s ||= @quiz.quiz_submissions.build(generate_build_hash(query_hash, user))

          s.workflow_state ||= state
          s.save! if s.changed?
        end
      end
      s
    end

    private

    # this is needed because Rails 2 expects a User object instead of an id
    def generate_build_hash(query_hash, user)
      return query_hash unless query_hash[:user_id]

      { user: }
    end
  end
end
