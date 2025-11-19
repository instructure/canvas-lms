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

module HorizonMode
  def load_canvas_career
    return if force_academic? || api_request?
    return if params[:invitation].present?
    return unless @current_user

    app = CanvasCareer::ExperienceResolver.new(@current_user, @context, @domain_root_account, session).resolve
    if CanvasCareer::Constants::CAREER_APPS.include?(app)
      redirect_to "#{canvas_career_path}#{request.fullpath}"
    end
  end

  private

  def force_academic?
    Canvas::Plugin.value_to_boolean(params[:force_classic])
  end

  def add_career_params
    yield

    return unless should_add_horizon_params?

    location = response.location
    return unless location

    response.location = add_horizon_params_to_url(location)
  end

  def redirect_to(options = {}, response_options = {})
    if should_add_horizon_params?
      if options.is_a?(String) && !options.include?("/career/")
        options = add_horizon_params_to_url(options)
      elsif options.is_a?(Hash) && !options.key?(:force_classic)
        options = options.merge(horizon_params)
      end
    end

    super
  end

  def should_add_horizon_params?
    return false unless @context
    return false if entering_student_view? || in_student_view?

    if @context.is_a?(Account)
      @context.horizon_account?
    elsif @context.is_a?(Course)
      @context.horizon_course?
    else
      false
    end
  end

  def add_horizon_params_to_url(url)
    uri = URI(url)
    query = Rack::Utils.parse_query(uri.query).merge(CanvasCareer::Constants::QueryParams::ACADEMIC_CONTENT_ONLY_CAREER_THEME.stringify_keys)
    uri.query = query.to_query
    uri.to_s
  end

  def horizon_params
    { content_only: "true", instui_theme: "career", force_classic: "true" }.symbolize_keys
  end

  def entering_student_view?
    (controller_name == "courses" && action_name == "student_view") ||
      (request.path.include?("/student_view") && request.method == "POST")
  end

  def in_student_view?
    @current_user&.fake_student?
  end

  def remove_horizon_params(url)
    return url unless url&.include?("instui_theme=career") && url.include?("force_classic=true")

    uri = URI.parse(url)
    query_params = Rack::Utils.parse_query(uri.query || "")
    query_params.delete("instui_theme")
    query_params.delete("force_classic")
    query_params.delete("content_only")
    uri.query = query_params.empty? ? nil : query_params.to_query
    uri.to_s
  end
end
