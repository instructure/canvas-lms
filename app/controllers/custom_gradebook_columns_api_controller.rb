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
# @object Custom Column
#    {
#      // header text
#      "title": "Stuff",
#
#      // column order
#      "position": 1
#    }
class CustomGradebookColumnsApiController < ApplicationController
  before_filter :require_context, :require_user

  include Api::V1::CustomGradebookColumn

  # @API List custom gradebook columns
  #
  # List all custom gradebook columns for a course
  #
  # @returns [Custom Column]
  def index
    if authorized_action? @context.custom_gradebook_columns.build,
                          @current_user, :read
      columns = Api.paginate(@context.custom_gradebook_columns.active, self,
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
  # @argument column[title] [String]
  # @argument column[position] [Int]
  #   The position of the column relative to other custom columns
  #
  # @returns Custom Column
  def create
    column = @context.custom_gradebook_columns.build(params[:column])
    update_column(column)
  end

  # @API Update a custom gradebook column
  #
  # Accepts the same parameters as custom gradebook column creation
  #
  # @returns Custom Column
  def update
    column = @context.custom_gradebook_columns.active.find(params[:id])
    column.attributes = params[:column]
    update_column(column)
  end

  # @API Delete a custom gradebook column
  #
  # Permanently deletes a custom column and its associated data
  #
  # @returns Custom Column
  def destroy
    column = @context.custom_gradebook_columns.active.find(params[:id])
    if authorized_action? column, @current_user, :manage
      column.destroy
      render :json => custom_gradebook_column_json(column,
                                                   @current_user, session)
    end
  end

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
  private :update_column
end
