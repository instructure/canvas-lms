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

class WikiPageCommentsController < ApplicationController
  before_filter :require_context
  before_filter :get_wiki_page, :except => :latest_version_number
  add_crumb(proc { t '#crumbs.wiki_pages', "Pages"}, :except => [:latest_version_number]) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_wiki_pages_url }
  before_filter { |c| c.active_tab = "pages" }
  
  def create
    if authorized_action(@page, @current_user, :read)
      if @context.allow_wiki_comments || @context.grants_right?(@current_user, nil, :manage_wiki)
        @comment = @page.wiki_page_comments.build(params[:wiki_page_comment])
        @comment.user = @current_user
        @comment.context = @context
        @comment.user_name = @current_user ? @current_user.name : request.remote_ip
        if @comment.save
          render :json => @comment.to_json(:methods => :formatted_body, :permissions => {:user => @current_user, :session => session})
        else
          render :json => @comment.errors.to_json, :status => :bad_request
        end
      else
        authorized_action(nil, @current_user, :bad_permission)
      end
    end
  end
  
  def destroy
    @comment = @page.wiki_page_comments.find(params[:id])
    if authorized_action(@comment, @current_user, :delete)
      @comment.destroy
      render :json => @comment.to_json
    end
  end
  
  def index
    if authorized_action(@page, @current_user, :read)
      @comments = @page.wiki_page_comments.active.current_first.paginate(:page => params[:page], :per_page => 5)
      render :json => @comments.to_json(:methods => :formatted_body, :permissions => {:user => @current_user, :session => session})
    end
  end
end
