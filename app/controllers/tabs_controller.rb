#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Tabs
# @model Tab
#     {
#       "id": "Tab",
#       "description": "",
#       "properties": {
#         "html_url": {
#           "example": "/courses/1/external_tools/4",
#           "type": "string"
#         },
#         "id": {
#           "example": "context_external_tool_4",
#           "type": "string"
#         },
#         "label": {
#           "example": "WordPress",
#           "type": "string"
#         },
#         "type": {
#           "example": "external",
#           "type": "string"
#         },
#         "hidden": {
#           "description": "only included if true",
#           "example": true,
#           "type": "boolean"
#         },
#         "visibility": {
#           "description": "possible values are: public, members, admins, and none",
#           "example": "public",
#           "type": "string"
#         },
#         "position": {
#           "description": "1 based",
#           "example": 2,
#           "type": "integer"
#         }
#       }
#     }
#
class TabsController < ApplicationController
  include Api::V1::Tab

  before_filter :require_context

  # @API List available tabs for a course or group
  #
  # Returns a list of navigation tabs available in the current context.
  #
  # @argument include[] [String, "external"]
  #   Optionally include external tool tabs in the returned list of tabs
  #   (Only has effect for courses, not groups)
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/<course_id>/tabs\?include\="external"
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/groups/<group_id>/tabs"
  #
  # @example_response
  #     [
  #       {
  #         "html_url": "/courses/1",
  #         "id": "home",
  #         "label": "Home",
  #         "position": 1,
  #         "visibility": "public",
  #         "type": "internal"
  #       },
  #       {
  #         "html_url": "/courses/1/external_tools/4",
  #         "id": "context_external_tool_4",
  #         "label": "WordPress",
  #         "hidden": true,
  #         "visibility": "public",
  #         "position": 2,
  #         "type": "external"
  #       },
  #       {
  #         "html_url": "/courses/1/grades",
  #         "id": "grades",
  #         "label": "Grades",
  #         "position": 3,
  #         "hidden": true
  #         "visibility": amdin
  #         "type": "internal"
  #       }
  #     ]
  def index
    if authorized_action(@context, @current_user, :read)
      json = tabs_available_json(context_tabs, @current_user, session)
      render :json => json.select { |tab| tab[:type] == 'external' ? Array(params[:include]).include?('external') : true }
    end
  end

  # @API Update a tab for a course
  #
  # Home and Settings tabs are not manageable, and can't be hidden or moved
  #
  # Returns a tab object
  #
  # @argument position [Integer] The new position of the tab, 1-based
  #
  # @argument hidden [Boolean]
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/tabs/tab_id \
  #       -X PUT \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'hidden=true' \
  #       -d 'position=2' // 1 based
  #
  # @returns Tab
  def update
    return unless  authorized_action(@context, @current_user, :manage_content) && @context.is_a?(Course)
    css_class = params['tab_id']
    new_pos = params['position'].to_i if params['position']
    tabs = context_tabs
    tab = (tabs.find { |t| t.with_indifferent_access[:css_class] == css_class }).with_indifferent_access
    tab_config = @context.tab_configuration
    tab_config = tabs.map { |t| {'id' => t.with_indifferent_access['id']} } if tab_config.blank?
    if [@context.class::TAB_HOME, @context.class::TAB_SETTINGS].include?(tab[:id])
      render json: {error: t(:tab_unmanagable_error, "%{css_class} is not manageable", css_class: css_class)}, status: :bad_request
    elsif new_pos && (new_pos <= 1 || new_pos >= tab_config.count + 1)
      render json: {error: t(:tab_location_error, 'That tab location is invalid')}, status: :bad_request
    else
      pos = tab_config.index { |t| t['id'] == tab['id'] }

      if value_to_boolean(params['hidden'])
        tab[:hidden] = true
        tab_config[pos]['hidden'] = true
      elsif params.key?('hidden')
        [tab_config[pos], tab].each { |t| t.delete('hidden') }
      end

      if new_pos
        tab_config.insert(new_pos - 1, tab_config.delete_at(pos))
        tab[:position] = new_pos
      end

      @context.tab_configuration = tab_config
      @context.save!
      render json: tab_json(tab, @current_user, session)
    end
  end

  def context_tabs
    tabs = @context.tabs_available(@current_user, :include_external => true, :api => true).select do |tab|
      if (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
        tab[:href] && tab[:label] && Collaboration.any_collaborations_configured?
      elsif (tab[:id] == @context.class::TAB_CONFERENCES rescue false)
        tab[:href] && tab[:label] && feature_enabled?(:web_conferences)
      else
        tab[:href] && tab[:label]
      end
    end
    tab_positions(tabs)
  end

  def tab_positions(tabs)
    tab_config = self.respond_to?(:tab_configuration) && self.tab_configuration.present? && self.tab_configuration
    tabs.each_with_index.map do |tab, i|
      if tab_config
        position = @context.class::TAB_SETTINGS == tab['id'] ? tabs.size : tab_configuration.index { |t| t['id'] == tab['id'] } + 1
      else
        position = i + 1
      end
      tab[:position] = position
    end
    tabs
  end

end
