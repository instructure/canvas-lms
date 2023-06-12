# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
class QuizzesNext::QuizzesApiController < ApplicationController
  include Api::V1::Quiz
  include Api::V1::QuizzesNext::Quiz

  before_action :require_context

  # @API List quizzes in a course
  #
  # Returns the paginated list of Quizzes in this course.
  #
  # @argument search_term [String]
  #   The partial title of the quizzes to match and return.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/all_quizzes \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Quiz]
  def index
    if authorized_action(@context, @current_user, :read) && tab_enabled?(@context.class::TAB_QUIZZES)
      log_api_asset_access(["quizzes.next", @context], "quizzes", "other")
      cache_key = [
        "quizzes.next",
        @context.id,
        all_quizzes.count,
        @current_user,
        latest_updated_at,
        accepts_jsonapi?,
        params[:search_term],
        params[:page],
        params[:per_page]
      ].cache_key

      value = Rails.cache.fetch(cache_key) do
        api_route = api_v1_course_all_quizzes_url(@context)
        @quizzes = Api.paginate(all_quizzes, self, api_route)

        {
          json: quizzes_next_json(@quizzes, @context, @current_user, session),
          link: response.headers["Link"].to_s
        }
      end

      response.headers["Link"] = value[:link] if value[:link]

      render json: value[:json]
    end
  end

  private

  def all_quizzes
    @_all_quizzes ||= begin
      scope = Quizzes::Quiz.search_by_attribute(@context.quizzes.active, :title, params[:search_term])
      old_quizzes = Quizzes::ScopedToUser.new(@context, @current_user, scope).scope

      scope = Assignments::ScopedToUser.new(@context, @current_user).scope
      new_quizzes = Assignment.search_by_attribute(scope, :title, params[:search_term])
      new_quizzes = new_quizzes.type_quiz_lti

      old_quizzes + new_quizzes
    end
  end

  def latest_updated_at
    return @_latest_updated_at if defined?(@_latest_updated_at)

    quiz_updated = @context.quizzes.active.reorder("updated_at DESC").limit(1).pluck(:updated_at).first
    assignment_updated = @context.assignments.active.reorder("updated_at DESC").limit(1).pluck(:updated_at).first
    @_latest_updated_at = [quiz_updated, assignment_updated].compact.max
  end
end
