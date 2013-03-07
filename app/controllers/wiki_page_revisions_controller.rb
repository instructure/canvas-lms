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

class WikiPageRevisionsController < ApplicationController
  before_filter :require_context, :except => :latest_version_number
  before_filter :get_wiki_page, :except => :latest_version_number
  add_crumb(proc { t '#crumbs.wiki_pages', "Pages"}, :except => [:latest_version_number]) { |c| c.send :named_context_url,  c.instance_variable_get("@context"), :context_wiki_pages_url }
  before_filter { |c| c.active_tab = "pages" }
  
  def index
    if authorized_action(@page, @current_user, :update_content)
      respond_to do |format|
        format.html {
          add_crumb(@page.title, named_context_url(@context, :context_wiki_page_url, @page))
          add_crumb(t("#crumbs.revisions", "Revisions"))
          log_asset_access(@page, "wiki", @wiki)
        }
        format.json { render :json => @page.version_history.to_json(:methods => :version_number) }
      end
    end
  end
  
  def latest_version_number
    # Technically this method leaks information.  We're avoiding doing
    # a permission check to keep this lookup fast, since its only purpose is
    # to make sure somebody hasn't edited the page from underneath somebody
    # else.  It does divulge the page id, and current version number, though.
    # If we're not ok with that, we can add a permission check.
    @version = params[:wiki_page_id].to_i.to_s == params[:wiki_page_id] &&
      Version.where(:versionable_type => 'WikiPage', :versionable_id => params[:wiki_page_id]).order('number DESC').first
    if !@version
      get_context
      get_wiki_page
      @version = @page.versions[0] rescue nil
    end
    @version_number = @version.number rescue 0
    @id = @version.versionable_id rescue nil
    render :json => {:wiki_page => {:id => @id, :version_number => @version_number} }
  end
  
  def show
    if authorized_action(@page, @current_user, :update_content)
      if params[:id] == "latest"
        @revision = @page.versions[0]
      else
        @revision = @page.versions.find(params[:id])
      end
      respond_to do |format|
        format.html {
          add_crumb(@page.title, named_context_url(@context, :context_wiki_page_url, @page))
          log_asset_access(@page, "wiki", @wiki)
        }
        @model = @revision.model rescue nil
        format.json { render :json => @model.to_json(:methods => :version_number) }
      end
    end
  end
  
  def update
    if authorized_action(@page, @current_user, :update)
      @revision = @page.versions.find(params[:id])
      except_fields = [:id] + WikiPage.new.attributes.keys - WikiPage.accessible_attributes.to_a
      @page.revert_to_version @revision, :except => except_fields
      flash[:notice] = t('notices.page_rolled_back', 'Page was successfully rolled-back to previous version.')
      redirect_to polymorphic_url([@context, @page])
    end
  end
end
