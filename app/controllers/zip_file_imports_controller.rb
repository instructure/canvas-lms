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

  def import_status
    if authorized_action(@context, @current_user, :manage_files)
      @status = SisBatch.find_by_account_id_and_batch_id(0, params[:batch_id])
      @status.data ||= {} if @status
      render :json => (@status.data rescue {}).to_json
    end
  end
  
  def create
    if authorized_action(@context, @current_user, :manage_files)
      params[:batch_id] ||= params[:zip_import_batch_id]
      zip_params = params.dup.merge(:context => @context).delete_if { |k,v| !%w(zip_file context folder_id batch_id).include?(k) }
      @zfi = ZipFileImport.new(zip_params)
      respond_to do |format|
        if @zfi.process!
          flash[:notice] = "Uploaded and unzipped #{@zfi.zip_file.original_filename} into #{@zfi.root_directory.full_name}."
          format.html { return_to(params[:return_to], named_context_url(@context, :context_url)) }
          format.json { render :json => @zfi.to_json }
        else
          @status = SisBatch.find_by_account_id_and_batch_id(0, params[:batch_id])
          if @status
            @status.data ||= {}
            @status.data[:errors] = @zfi.errors.full_messages
            @status.save
          end
          format.html do
            if params[:redirect_to] =~ /imports\/quizzes/
              render :template => 'content_imports/files'
            else
              render :action => "new"
            end
          end
          format.json { render :json => @zfi.errors.to_json }
        end
      end
    end
  end
end
