#
# Copyright (C) 2011 - 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <http://www.gnu.org/licenses/>.
#

# undocumented @API Moderated Grading API
#
# API for viewing and adding students to the list of people in moderation
# for an assignment
#


class ModerationSetController < ApplicationController
  include Api::V1::User

  before_filter :load_assignment

  # undocumented @API List students selected for moderation
  # @returns [User]
  def index
    if authorized_action(@context, @current_user, :moderate_grades)

      scope = @assignment.shard.activate {
         User.where(
          id: @assignment.moderated_grading_selections.select(:student_id)
        ).order(:id)
      }

      users = Api.paginate(scope, self, api_v1_moderated_students_url(@context, @assignment))
      render json: users_json(users, @current_user, session)
    end
  end

  # undocumented @API Select students for moderation
  #
  # Returns an array of users that were selected for moderation
  #
  # @argument student_ids[] [Number]
  #   user ids for students to select for moderation
  #
  # @returns [User]
  def create
    if authorized_action(@context, @current_user, :moderate_grades)
      current_selections = @assignment.moderated_grading_selections.
        pluck(:student_id)
      new_student_ids = params[:student_ids].map(&:to_i) - current_selections

      students = @context.students_visible_to(@current_user).
        where(id: new_student_ids).to_a
      students.each do |student|
        @assignment.moderated_grading_selections.create! student: student
      end

      render json: students.map { |u| user_json(u, @current_user, session) }
    end
  end

  private

  def load_assignment
    @context = api_find(Course, params[:course_id])
    @assignment = @context.assignments.find(params[:assignment_id])
  end
end
