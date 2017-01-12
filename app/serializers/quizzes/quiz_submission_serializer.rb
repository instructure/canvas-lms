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
module Quizzes
  class QuizSubmissionSerializer < Canvas::APISerializer
    include Api::V1::QuizSubmission

    root :quiz_submission

    attributes :id

    def_delegators :@controller,
      :course_quiz_quiz_submission_url, :course_quiz_history_url

    def serializable_object(options={})
      return super unless object
      hash = quiz_submission_json(object, object.quiz, current_user, session, context)
      hash[:id] = hash[:id].to_s unless hash[:id].nil?
      @wrap_in_array ? [hash] : hash
    end
  end
end
