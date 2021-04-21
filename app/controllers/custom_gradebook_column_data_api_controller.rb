# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
# @subtopic Custom Gradebook Column Data
#
# @model ColumnDatum
#     {
#       "id": "ColumnDatum",
#       "description": "ColumnDatum objects contain the entry for a column for each user.",
#       "properties": {
#         "content": {
#           "example": "Nut allergy",
#           "type": "string"
#         },
#         "user_id": {
#           "example": 2,
#           "type": "integer"
#         }
#       }
#     }
#
class CustomGradebookColumnDataApiController < ApplicationController
  before_action :require_context, :require_user

  include Api::V1::CustomGradebookColumn
  include Api::V1::Progress

  # @API List entries for a column
  #
  # This does not list entries for students without associated data.
  #
  # @argument include_hidden [Boolean]
  #   If true, hidden columns will be included in the
  #   result. If false or absent, only visible columns
  #   will be returned.
  #
  # @returns [ColumnDatum]
  def index
    scope = value_to_boolean(params[:include_hidden]) ? :not_deleted : :active
    col = @context.custom_gradebook_columns.send(scope).find(params[:id])

    if authorized_action? col, @current_user, :read
      scope = col.custom_gradebook_column_data.where(user_id: allowed_user_ids)

      data = Api.paginate(scope, self,
                          api_v1_course_custom_gradebook_column_data_url(@context, col))

      render :json => data.map { |d|
        custom_gradebook_column_datum_json(d, @current_user, session)
      }
    end
  end

  # @API Update column data
  #
  # Set the content of a custom column
  #
  # @argument column_data[content] [Required, String]
  #   Column content.  Setting this to blank will delete the datum object.
  #
  # @returns ColumnDatum
  def update
    user = allowed_users.where(:id => params[:user_id]).first
    raise ActiveRecord::RecordNotFound unless user

    column = @context.custom_gradebook_columns.not_deleted.find(params[:id])
    datum = column.custom_gradebook_column_data.find_or_initialize_by(user_id: user.id)
    if authorized_action? datum, @current_user, :update
      CustomGradebookColumnDatum.unique_constraint_retry do |retry_count|
        if retry_count > 0
          # query for the datum again if this is a retry
          datum = column.custom_gradebook_column_data.find_or_initialize_by(user_id: user.id)
        end
        datum.attributes = params.require(:column_data).permit(:content)
        if datum.content.blank?
          datum.destroy
          render json: custom_gradebook_column_datum_json(datum, @current_user, session)
        elsif datum.save
          render json: custom_gradebook_column_datum_json(datum, @current_user, session)
        else
          render json: datum.errors
        end
      end
    end
  end

  # @API Bulk update column data
  #
  # Set the content of custom columns
  #
  # @argument column_data[] [Required, Array]
  #   Column content. Setting this to an empty string will delete the data object.
  #
  # @example_request
  #
  # {
  #   "column_data": [
  #     {
  #       "column_id": example_column_id,
  #       "user_id": example_student_id,
  #       "content": example_content
  #       },
  #       {
  #       "column_id": example_column_id,
  #       "user_id": example_student_id,
  #       "content: example_content
  #     }
  #   ]
  # }
  #
  # @returns Progress

  def bulk_update
    bulk_update_params = params.permit(column_data: [:user_id, :column_id, :content])
    column_data_as_array = bulk_update_params.to_h[:column_data]
    raise ActionController::BadRequest if column_data_as_array.blank?

    column_ids = column_data_as_array.map { |entry| entry.fetch(:column_id) }

    cc = @context.custom_gradebook_columns.find(column_ids)
    cc.each do |col|
      return render_unauthorized_action unless authorized_action? col, @current_user, :read
    end

    user_ids = column_data_as_array.map { |entry| entry.fetch(:user_id)&.to_i }
    return render_unauthorized_action if (user_ids - allowed_users.pluck(:id)).any?

    progress = CustomGradebookColumnDatum.queue_bulk_update_custom_columns(@context, column_data_as_array)
    render json: progress_json(progress, @current_user, session)
  end

  def allowed_users
    @context.students_visible_to(@current_user, include: %i{inactive completed})
  end
  private :allowed_users

  def allowed_user_ids
    allowed_users.pluck(:id)
  end
  private :allowed_user_ids
end
