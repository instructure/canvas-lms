# frozen_string_literal: true

#
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

class HorizonController < ApplicationController
  include Api::V1::Progress

  before_action :require_user
  before_action :require_context

  def validate_course
    return unless authorized_action(@context, @current_user, :manage_courses_admin)

    errors = Courses::HorizonService.validate_course_contents(@context, method(:named_context_url))

    render json: { errors: }
  end

  def convert_course
    return unless authorized_action(@context, @current_user, :manage_courses_admin)

    errors = Courses::HorizonService.validate_course_contents(@context, method(:named_context_url))

    # return early if course is horizon compatible
    if errors.empty?
      @context.update!(horizon_course: true)
      return render json: { success: true }
    end

    # we will not convert quizzes, just return if there are still classic quizzes
    if errors[:quizzes].present?
      return render json: { errors: t("There are still classic quizzes in the course. Please convert them to new quizzes first.") }
    end

    progress = Progress.create!(context: @context, user: @current_user, tag: :convert_course_to_horizon)

    convert_params = {
      context: @context,
      errors:
    }

    progress.process_job(Courses::HorizonService, :convert_course_to_horizon, { run_at: Time.zone.now, priority: Delayed::HIGH_PRIORITY }, **convert_params)
    render json: progress_json(progress, @current_user, session)
  end

  def revert_course
    return unless authorized_action(@context, @current_user, :manage_courses_admin)

    @context.update!(horizon_course: false)
    render json: { success: true }
  end
end
