# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ContentExportsController < ApplicationController
  include K5Mode

  before_action :require_permission, except: :xml_schema
  before_action { |c| c.active_tab = "settings" }

  def require_permission
    get_context
    @context ||= @current_user # if we're going through the dashboard
    authorized_action(@context, @current_user, [:read, :read_as_admin], all_rights: true)
  end

  def index
    scope = @context.content_exports_visible_to(@current_user).without_epub
    @exports = scope.active.not_for_copy.order("content_exports.created_at DESC")
    @current_export_id = scope.running.first.try(:id)
    @warning_messages = @context.export_warnings if @context.is_a?(Course)
  end

  def show
    if params[:id].present? && (export = @context.content_exports_visible_to(@current_user).where(id: params[:id]).first)
      render_export(export)
    else
      render json: { errors: { base: t("errors.not_found", "Export does not exist") } }, status: :not_found
    end
  end

  def create
    export = @context.content_exports_visible_to(@current_user).running.first
    if export
      # an export is already running, just return it
      render_export(export)
    else
      export = @context.content_exports.build
      export.user = @current_user
      export.workflow_state = "created"

      case @context
      when Course
        if params[:export_type] == "qti"
          export.export_type = ContentExport::QTI
          export.selected_content = params[:copy].to_unsafe_h
        else
          export.export_type = ContentExport::COMMON_CARTRIDGE
          export.set_contains_new_quizzes_settings
          export.mark_waiting_for_external_tool if export.contains_new_quizzes?
          export.selected_content = { everything: true }
        end
      when User
        export.export_type = ContentExport::USER_DATA
      end

      export.progress = 0
      if export.save
        export.export unless export.waiting_for_external_tool?
        render_export(export)
      else
        render json: { error_message: t("errors.couldnt_create", "Couldn't create content export.") }
      end
    end
  end

  def destroy
    if params[:id].present? && (export = @context.content_exports_visible_to(@current_user).where(id: params[:id]).first)
      export.destroy
      render json: { success: "true" }
    else
      render json: { errors: { base: t("errors.not_found", "Export does not exist") } }, status: :not_found
    end
  end

  def xml_schema
    if (filename = CC::Schema.for_version(params[:version]))
      cancel_cache_buster
      send_file(filename, type: "text/xml", disposition: "inline")
    else
      render "shared/errors/404_message", status: :not_found, formats: [:html]
    end
  end

  private

  def render_export(export)
    json = export.as_json(only: %i[id progress workflow_state], methods: [:error_message])
    json["content_export"]["download_url"] = verified_file_download_url(export.attachment, export) if export.attachment && !export.expired?
    render json:
  end
end
