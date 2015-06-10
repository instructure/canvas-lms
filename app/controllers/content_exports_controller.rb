#
# Copyright (C) 2011 Instructure, Inc.
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
  before_filter :require_permission, :except => :xml_schema
  before_filter { |c| c.active_tab = "settings" }

  def require_permission
    get_context
    @context ||= @current_user # if we're going through the dashboard
    return render_unauthorized_action unless @context.grants_all_rights?(@current_user, :read, :read_as_admin)
  end

  def index
    @exports = @context.content_exports_visible_to(@current_user).active.not_for_copy.order('created_at DESC')

    @current_export_id = nil
    if export = @context.content_exports_visible_to(@current_user).running.first
      @current_export_id = export.id
    end
  end

  def show
    if params[:id].present? && export = @context.content_exports_visible_to(@current_user).where(id: params[:id]).first
      render_export(export)
    else
      render :json => {:errors => {:base => t('errors.not_found', "Export does not exist")}}, :status => :not_found
    end
  end

  def create
    export = @context.content_exports_visible_to(@current_user).running.first
    unless export
      export = @context.content_exports.build
      export.user = @current_user
      export.workflow_state = 'created'

      if @context.is_a?(Course)
        if params[:export_type] == 'qti'
          export.export_type = ContentExport::QTI
          export.selected_content = params[:copy]
        else
          export.export_type = ContentExport::COMMON_CARTRIDGE
          export.selected_content = { :everything => true }
        end
      elsif @context.is_a?(User)
        export.export_type = ContentExport::USER_DATA
      end

      export.progress = 0
      if export.save
        export.export
        render_export(export)
      else
        render :json => {:error_message => t('errors.couldnt_create', "Couldn't create content export.")}
      end
    else
      # an export is already running, just return it
      render_export(export)
    end
  end

  def destroy
    if params[:id].present? && export = @context.content_exports_visible_to(@current_user).where(id: params[:id]).first
      export.destroy
      render :json => {:success=>'true'}
    else
      render :json => {:errors => {:base => t('errors.not_found', "Export does not exist")}}, :status => :not_found
    end
  end

  def xml_schema
    if filename = CC::Schema.for_version(params[:version])
      cancel_cache_buster
      send_file(filename, :type => 'text/xml', :disposition => 'inline')
    else
      render 'shared/errors/404_message', status: :not_found
    end
  end

  private

  def render_export(export)
    json = export.as_json(:only => [:id, :progress, :workflow_state],:methods => [:error_message])
    json['content_export']['download_url'] = verified_file_download_url(export.attachment, export) if export.attachment
    render :json => json
  end
end
