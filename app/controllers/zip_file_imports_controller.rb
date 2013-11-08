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

class ZipFileImportsController < ApplicationController
  before_filter :require_context

  def new
    if authorized_action(@context, @current_user, :manage_files)
    end
  end

  def show
    @import = @context.zip_file_imports.find(params[:id])
    if authorized_action(@import, @current_user, :read)
      render :json => @import
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_files)
      @folder = @context.folders.active.find(params[:folder_id])

      @import = @context.zip_file_imports.create!(:folder => @folder)

      att = Attachment.new
      att.context = @import
      att.uploaded_data = params[:zip_file]
      att.display_name = t :zip_import_filename, "zip_import_%{id}.zip", :id => @import.id
      att.position = 0
      att.save

      @import.attachment = att
      @import.save
      @import.process # happens async

      render :json => @import
    end
  end
end
