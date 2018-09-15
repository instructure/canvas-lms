#
# Copyright (C) 2017 - present Instructure, Inc.
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

# @API Planner override
#
# API for creating, accessing and updating planner override. PlannerOverrides are used
# to control the visibility of objects displayed on the Planner.
#
# @model PlannerOverride
#     {
#       "id": "PlannerOverride",
#       "description": "User-controlled setting for whether an item should be displayed on the planner or not",
#       "properties": {
#         "id": {
#           "description": "The ID of the planner override",
#           "example": 234,
#           "type": "integer"
#         },
#         "plannable_type": {
#           "description": "The type of the associated object for the planner override",
#           "example": "Assignment",
#           "type": "string"
#         },
#         "plannable_id": {
#           "description": "The id of the associated object for the planner override",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "The id of the associated user for the planner override",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current published state of the item, synced with the associated object",
#           "example": "published",
#           "type": "string"
#         },
#         "marked_complete": {
#           "description": "Controls whether or not the associated plannable item is marked complete on the planner",
#           "example": false,
#           "type": "boolean"
#         },
#         "dismissed": {
#           "description": "Controls whether or not the associated plannable item shows up in the opportunities list",
#           "example": false,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "The datetime of when the planner override was created",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The datetime of when the planner override was updated",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "deleted_at": {
#           "description": "The datetime of when the planner override was deleted, if applicable",
#           "example": "2017-05-15T12:12:00Z",
#           "type": "datetime"
#         }
#       }
#     }
#
class PlannerOverridesController < ApplicationController
  include Api::V1::PlannerOverride
  include PlannerHelper

  before_action :require_user
  before_action :require_planner_enabled

  # @API List planner overrides
  # @beta
  #
  # Retrieve a planner override for the current user
  #
  # @returns [PlannerOverride]
  def index
    planner_overrides = Api.paginate(PlannerOverride.for_user(@current_user).active, self, api_v1_planner_overrides_url)
    render :json => planner_overrides.map { |po| planner_override_json(po, @current_user, session) }
  end

  # @API Show a planner override
  # @beta
  #
  # Retrieve a planner override for the current user
  #
  # @returns PlannerOverride
  def show
    planner_override = PlannerOverride.find(params[:id])
    render json: planner_override_json(planner_override, @current_user, session)
  end

  # @API Update a planner override
  # @beta
  #
  # Update a planner override's visibilty for the current user
  #
  # @argument marked_complete
  #   determines whether the planner item is marked as completed
  #
  # @argument dismissed
  #   determines whether the planner item shows in the opportunities list
  #
  # @returns PlannerOverride
  def update
    planner_override = PlannerOverride.find(params[:id])
    planner_override.marked_complete = value_to_boolean(params[:marked_complete])
    planner_override.dismissed = value_to_boolean(params[:dismissed])
    sync_module_requirement_done(planner_override.plannable, @current_user, value_to_boolean(params[:marked_complete]))

    if planner_override.save
      Rails.cache.delete(planner_meta_cache_key)
      render json: planner_override_json(planner_override, @current_user, session), status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  # @API Create a planner override
  # @beta
  #
  # Create a planner override for the current user
  #
  # @argument plannable_type [String, "announcement"|"assignment"|"discussion_topic"|"quiz"|"wiki_page"|"planner_note"]
  #   Type of the item that you are overriding in the planner
  #
  # @argument plannable_id [Integer]
  #   ID of the item that you are overriding in the planner
  #
  # @argument marked_complete [Boolean]
  #   If this is true, the item will show in the planner as completed
  #
  # @argument dismissed [Boolean]
  #   If this is true, the item will not show in the opportunities list
  #
  #
  # @returns PlannerOverride
  def create
    plannable_type = PLANNABLE_TYPES[params[:plannable_type]]
    plannable = plannable_type.constantize.find(params[:plannable_id])
    planner_override = PlannerOverride.new(plannable: plannable, marked_complete: value_to_boolean(params[:marked_complete]),
      user: @current_user, dismissed: value_to_boolean(params[:dismissed]))
    sync_module_requirement_done(plannable, @current_user, value_to_boolean(params[:marked_complete]))

    if planner_override.save
      Rails.cache.delete(planner_meta_cache_key)
      render json: planner_override_json(planner_override, @current_user, session), status: :created
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  # @API Delete a planner override
  # @beta
  #
  # Delete a planner override for the current user
  #
  # @returns PlannerOverride
  def destroy
    planner_override = PlannerOverride.find(params[:id])

    if planner_override.destroy
      Rails.cache.delete(planner_meta_cache_key)
      render json: planner_override_json(planner_override, @current_user, session), status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end
end
