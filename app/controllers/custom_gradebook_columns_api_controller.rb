#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Custom Gradebook Columns
#
# API for adding additional columns to the gradebook.  Custom gradebook
# columns will be displayed with the other frozen gradebook columns.
#
# @model CustomColumn
#     {
#       "id": "CustomColumn",
#       "description": "",
#       "properties": {
#         "title": {
#           "description": "header text",
#           "example": "Stuff",
#           "type": "string"
#         },
#         "position": {
#           "description": "column order",
#           "example": 1,
#           "type": "integer"
#         },
#         "hidden": {
#           "description": "won't be displayed if hidden is true",
#           "example": false,
#           "type": "boolean"
#         }
#       }
#     }
#
class CustomGradebookColumnsApiController < ApplicationController
  before_action :require_context, :require_user

  include Api::V1::CustomGradebookColumn

  # @API List custom gradebook columns
  #
  # List all custom gradebook columns for a course
  #
  # @argument include_hidden [Boolean]
  #   Include hidden parameters (defaults to false)
  #
  # @returns [CustomColumn]
  def index
    if authorized_action? @context.custom_gradebook_columns.build,
                          @current_user, :read
      scope = value_to_boolean(params[:include_hidden]) ?
        @context.custom_gradebook_columns.not_deleted :
        @context.custom_gradebook_columns.active
      columns = Api.paginate(scope, self,
                             api_v1_course_custom_gradebook_columns_url(@context))

      render :json => columns.map { |c|
        custom_gradebook_column_json(c, @current_user, session)
      }
    end
  end

  # @API Create a custom gradebook column
  #
  # Create a custom gradebook column
  #
  # @argument column[title] [Required, String]
  # @argument column[position] [Integer]
  #   The position of the column relative to other custom columns
  # @argument column[hidden] [Boolean]
  #   Hidden columns are not displayed in the gradebook
  # @argument column[teacher_notes] [Boolean]
  #   Set this if the column is created by a teacher.  The gradebook only
  #   supports one teacher_notes column.
  #
  # @returns CustomColumn
  def create
    column = @context.custom_gradebook_columns.build(column_params)
    update_column(column)
  end

  # @API Update a custom gradebook column
  #
  # Accepts the same parameters as custom gradebook column creation
  #
  # @returns CustomColumn
  def update
    column = @context.custom_gradebook_columns.not_deleted.find(params[:id])
    column.attributes = column_params
    update_column(column)
  end

  # @API Delete a custom gradebook column
  #
  # Permanently deletes a custom column and its associated data
  #
  # @returns CustomColumn
  def destroy
    column = @context.custom_gradebook_columns.not_deleted.find(params[:id])
    if authorized_action? column, @current_user, :manage
      column.destroy
      render :json => custom_gradebook_column_json(column,
                                                   @current_user, session)
    end
  end

  # @API Reorder custom columns
  #
  # Puts the given columns in the specified order
  #
  # @argument order[] [Required, Integer]
  #
  # <b>200 OK</b> is returned if successful
  def reorder
    @context.custom_gradebook_columns.build.update_order(params[:order])
    render :status => 200, :json => {}
  end

  private
  def update_column(column)
    if authorized_action? column, @current_user, :manage
      if column.save
        render :json => custom_gradebook_column_json(column,
                                                     @current_user, session)
      else
        render :json => column.errors, :status => :bad_request
      end
    end
  end

  def column_params
    params.require(:column).permit(:title, :position, :teacher_notes, :hidden)
  end
end
