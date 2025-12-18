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
#

# @API Canvas Career Experiences
#
# API for managing user career experience and role preferences in Canvas.
#
# @model ExperienceSummary
#     {
#       "id": "ExperienceSummary",
#       "properties": {
#         "current_app": {
#           "description": "The current active experience. One of: 'academic', 'career_learner', 'career_learning_provider'.",
#           "example": "career_learner",
#           "type": "string"
#         },
#         "available_apps": {
#           "description": "List of available experiences for the user. Can include: 'academic', 'career_learner', 'career_learning_provider'.",
#           "example": ["academic", "career_learner"],
#           "type": "array",
#           "items": {"type": "string"}
#         }
#       }
#     }
#
class CareerExperienceController < ApplicationController
  before_action :require_user

  # @API Check if Canvas Career is enabled
  #
  # Returns whether the root account has Canvas Career (Horizon) enabled
  # in at least one subaccount.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/career/enabled \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns {enabled: boolean}
  #
  # @example_response
  #   {"enabled": true}
  def enabled
    enabled = CanvasCareer::ExperienceResolver.career_affiliated_institution?(@domain_root_account)
    render json: { enabled: }
  end

  # @API Get current and available experiences
  #
  # Returns the current user's active experience and available experiences
  # they can switch to.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/career/experience_summary \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns ExperienceSummary
  def experience_summary
    resolver = CanvasCareer::ExperienceResolver.new(@current_user, nil, @domain_root_account, session)

    render json: {
      current_app: resolver.resolve,
      available_apps: resolver.available_apps,
    }
  end

  # @API Switch experience
  #
  # Switch the current user's active experience to the specified one.
  #
  # @argument experience [Required, String, "academic"|"career"]
  #   The experience to switch to.
  #
  # @example_request
  #   curl -X POST https://<canvas>/api/v1/career/switch_experience \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'experience=academic'
  #
  # @returns {experience: String} The newly set experience
  def switch_experience
    experience = params[:experience]
    unless CanvasCareer::Constants::Experience.valid?(experience)
      return render json: { error: "invalid_experience" }, status: :bad_request
    end

    preference_manager = CanvasCareer::UserPreferenceManager.new(session)
    preference_manager.save_preferred_experience(experience)

    respond_to do |format|
      format.html { redirect_to preference_manager.prefers_career? ? canvas_career_path : root_path }
      format.json { render json: { experience: }, status: :ok }
    end
  end

  # @API Switch role
  #
  # Switch the current user's role within the current experience.
  #
  # @argument role [Required, String, "learner"|"learning_provider"]
  #   The role to switch to.
  #
  # @example_request
  #   curl -X POST https://<canvas>/api/v1/career/switch_role \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'role=learner'
  #
  # @returns {role: String} The newly set role
  def switch_role
    role = params[:role]
    unless CanvasCareer::Constants::Role.valid?(role)
      return render json: { error: "invalid_role" }, status: :bad_request
    end

    CanvasCareer::UserPreferenceManager.new(session).save_preferred_role(role)

    respond_to do |format|
      format.html { redirect_to request.referer || root_path }
      format.json { render json: { role: }, status: :ok }
    end
  end
end
