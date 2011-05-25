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
  before_filter :require_context, :except => :xml_schema
  before_filter { |c| c.active_tab = "settings" }
  
  def index
    if authorized_action(@context, @current_user, :manage)
      @exports = @context.content_exports.active
      @current_export_id = nil
      if export = @context.content_exports.running.first
        @current_export_id = export.id
      end
    end
  end
  
  def show
    if authorized_action(@context, @current_user, :manage)
      if params[:id].present? && export = @context.content_exports.find_by_id(params[:id])
        render_export(export)
      else
        render :json => {:errors => {:base => "Export does not exist"}}.to_json, :status => :bad_request
      end
    end
  end
  
  def create
    if authorized_action(@context, @current_user, :manage)
      if @context.content_exports.running.count == 0
        export = ContentExport.new
        export.course = @context
        export.user = @current_user
        export.workflow_state = 'created'
        export.export_type = 'common_cartridge'
        export.progress = 0
        if export.save
          export.export_course
          render_export(export)
        else
          render :json => {:error_message => "Couldn't create course export."}.to_json
        end
      else
        # an export is already running, just return it
        export = @context.content_exports.running.first
        render_export(export)
      end
    end
  end
  
  def destroy
    if authorized_action(@context, @current_user, :manage)
      if params[:id].present? && export = @context.content_exports.find_by_id(params[:id])
        export.destroy
        render :json => {:success=>'true'}.to_json
      else
        render :json => {:errors => {:base => "Export does not exist"}}.to_json, :status => :bad_request
      end
    end
  end
  
  def xml_schema
    file = nil
    if params[:version]
      file = Rails.root + "lib/cc/xsd/#{params[:version]}.xsd"
    end
    
    if File.exists?(file)
      cancel_cache_buster
      send_file(file, :type => 'text/xml', :disposition => 'inline')
    else
      render :template => 'shared/errors/404_message', :status => :bad_request
    end
  end
  
  private
  
  def render_export(export)
    render :json => export.to_json(:only => [:id, :progress, :workflow_state],:methods => [:download_url, :error_message])
  end
end