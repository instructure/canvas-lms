# frozen_string_literal: true

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

module Interfaces::QuizzesConnectionInterface
  include Interfaces::BaseInterface

  class QuizFilterInputType < Types::BaseInputObject
    graphql_name "QuizFilter"
    argument :user_id, ID, <<~MD, required: false
      only return quizzes for the given user. Defaults to
      the current user.
    MD
    argument :search_term, String, <<~MD, required: false
      only return quizzes whose title matches this search term
    MD
  end

  def quizzes_scope(course, search_term = nil, user_id = nil)
    scoped_user = user_id.nil? ? current_user : User.find_by(id: user_id)

    return [] if user_id.present? && scoped_user.nil?

    # Check if current user has permission to view quizzes as the scoped user
    unless current_user.can_current_user_view_as_user(course, scoped_user)
      # Current user lacks permissions to view as the scoped user
      raise GraphQL::ExecutionError, "You do not have permission to view this course."
    end

    quizzes = course.quizzes.active.include_assignment
    lti_quizzes = if NewQuizzesFeaturesHelper.new_quizzes_enabled?(course)
                    course.active_assignments.type_quiz_lti
                  else
                    Assignment.none
                  end

    if search_term.present?
      quizzes = quizzes.where(Quizzes::Quiz.wildcard(:title, search_term))
      lti_quizzes = lti_quizzes.where(Assignment.wildcard(:title, search_term))
    end

    if !course.grants_right?(scoped_user, :read_as_admin) && scoped_user.is_a?(User)
      quizzes = DifferentiableAssignment.scope_filter(quizzes, scoped_user, course)
      lti_quizzes = DifferentiableAssignment.scope_filter(lti_quizzes, scoped_user, course)
    end

    quizzes = quizzes.to_a
    quizzes.concat(lti_quizzes.to_a) if NewQuizzesFeaturesHelper.new_quizzes_enabled?(course)

    quizzes
  end

  field :quizzes_connection,
        ::Types::QuizType.connection_type,
        <<~MD,
          returns a list of quizzes.
        MD
        null: true do
    argument :filter, QuizFilterInputType, required: false
  end

  def quizzes_connection(course:, filter: {})
    apply_quiz_order(quizzes_scope(course, filter[:search_term], filter[:user_id]))
  end

  def apply_quiz_order(quizzes)
    quizzes.sort_by(&:id)
  end
  private :apply_quiz_order
end
