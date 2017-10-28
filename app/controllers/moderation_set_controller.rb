#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API Moderated Grading
# @subtopic Moderation Set
# @beta
#
# API for viewing and adding students to the list of people in moderation
# for an assignment
#
class ModerationSetController < ApplicationController
  include Api::V1::User

  before_action :load_assignment

  # @API List students selected for moderation
  #
  # Returns a paginated list of students selected for moderation
  #
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

  # @API Select students for moderation
  #
  # Returns an array of users that were selected for moderation
  #
  # @argument student_ids[] [Number]
  #   user ids for students to select for moderation
  #
  # @returns [User]
  def create
    if authorized_action(@context, @current_user, :moderate_grades)
      unless params[:student_ids].present?
        render json: [], status: :bad_request
        return
      end

      all_student_ids = params[:student_ids].map(&:to_i)
      all_students = visible_students.where(id: all_student_ids)

      incremental_create(all_student_ids)

      render json: all_students.map { |u| user_json(u, @current_user, session) }
    end
  end

  private

  def incremental_create(student_ids)
    current_selections = @assignment.moderated_grading_selections.pluck(:student_id)
    new_student_ids = student_ids - current_selections

    new_students = visible_students.where(id: new_student_ids).distinct

    new_students.each do |student|
      @assignment.moderated_grading_selections.create! student: student
    end
  end

  def visible_students
    @visible_students ||= @context.students_visible_to(@current_user, include: :inactive).distinct
  end

  def load_assignment
    @context = api_find(Course, params[:course_id])
    @assignment = @context.assignments.find(params[:assignment_id])
  end
end
