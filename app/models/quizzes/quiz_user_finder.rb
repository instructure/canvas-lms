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
module Quizzes
  class QuizUserFinder
    extend Forwardable
    attr_reader :quiz, :user

    def_delegators :@quiz, :context, :quiz_submissions, :differentiated_assignments_applies?

    def initialize(quiz, user)
      @quiz = quiz
      @user = user
    end

    def submitted_students
      all_students_with_visibility.where(id: non_preview_user_ids)
    end

    def unsubmitted_students
      all_students_with_visibility.where('users.id NOT IN (?)', non_preview_user_ids)
    end

    def all_students
      context.students_visible_to(user, include: :inactive).order_by_sortable_name.group('users.id')
    end

    def all_students_with_visibility
      if differentiated_assignments_applies?
        all_students.able_to_see_quiz_in_course_with_da(@quiz.id, context.id)
      else
        all_students
      end
    end

    def non_preview_quiz_submissions
      # This could optionally check for temporary_user_code<>NULL, but
      # that's not indexed and we're checking user_id anyway in the queries above.
      quiz_submissions.where('quiz_submissions.user_id IS NOT NULL')
    end

    private
    def non_preview_user_ids
      non_preview_quiz_submissions.not_settings_only.select(:user_id)
    end
  end
end
