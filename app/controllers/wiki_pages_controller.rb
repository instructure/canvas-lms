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

class WikiPagesController < ApplicationController
  before_filter :require_context
  before_filter :get_wiki_page, :except => [:index]
  add_crumb("Pages") { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_wiki_pages_url }
  before_filter { |c| c.active_tab = "pages" }
  
  def show
    if @page.deleted? && !@page.grants_right?(@current_user, session, :update) && @page.url != 'front-page'
      flash[:notice] = "The page \"#{@page.title}\" has been deleted"
      redirect_to named_context_url(@context, :context_wiki_page_url, 'front-page')
      return
    end
    if @context.try_rescue(:wiki_is_public) || is_authorized_action?(@page, @current_user, :read)
      add_crumb(@page.title)
      unless @page.new_record?
        @page.with_versioning(false) do |page|
          page.context_module_action(@current_user, @context, :read)
          view_count = (page.view_count || 0) + 1            
          ActiveRecord::Base.connection.execute("UPDATE wiki_pages SET view_count=#{view_count} WHERE id=#{page.id}")
        end
        log_asset_access(@page, "wiki", @namespace)
      end
      respond_to do |format|
        format.html {render :action => "show" }
        format.json {render :json => @page.to_json }
      end
    else
      render_unauthorized_action(@page)
    end
  end
  
  def index
    return unless tab_enabled?(@context.class::TAB_PAGES)
    redirect_to named_context_url(@context, :context_wiki_page_url, 'front-page')
  end
  
  def update
    if authorized_action(@page, @current_user, :update_content)
      unless @page.grants_right?(@current_user, session, :update)
        params[:wiki_page] = {:body => params[:wiki_page][:body], :title => params[:wiki_page][:title]}
      end
      @page.workflow_state = 'active' if @page.deleted?
      if @page.update_attributes(params[:wiki_page].merge(:user_id => @current_user.id))
        log_asset_access(@page, "wiki", @namespace, 'participate')
        @page.context_module_action(@current_user, @context, :contributed)
        flash[:notice] = 'Page was successfully updated.'
        respond_to do |format|
          format.html { return_to(params[:return_to], context_wiki_page_url(:edit => params[:action] == 'create')) }
          format.json { render :json => {:success_url => context_wiki_page_url(:edit => params[:action] == 'create')} }
        end
      else
        respond_to do |format|
          format.html { render :action => "show" }
          format.json { render :json => @page.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def create
    update
  end
  
  def destroy
    if authorized_action(@page, @current_user, :delete)
      if @page.url != "front-page"
        flash[:notice] = 'Page was successfully deleted.'
        @page.workflow_state = 'deleted'
        @page.save
        respond_to do |format|
          format.html { redirect_to(named_context_url(@context, :context_wiki_pages_url)) }
        end
      else #they dont have permissions to destroy this page
        respond_to do |format|
          format.html { 
            flash[:error] = 'You are not permitted to delete that page.'
            redirect_to(named_context_url(@context, :context_wiki_pages_url))
          }
        end
      end
    end
  end

  protected

  def context_wiki_page_url(opts={})
    page_name = @page.url
    namespace = WikiNamespace.find_by_wiki_id_and_context_id_and_context_type(@page.wiki_id, @context.id, @context.class.to_s)
    page_name = namespace.namespace_name + page_name if namespace && !namespace.default?
    res = named_context_url(@context, :context_wiki_page_url, page_name)
    if opts && opts[:edit]
      res += "#edit"
    end
   res
  end
end
