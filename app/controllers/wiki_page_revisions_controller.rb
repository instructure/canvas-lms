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
  add_crumb("Pages", :except => [:latest_version_number]) { |c| c.send :course_wiki_pages_path, c.instance_variable_get("@context") }
  before_filter { |c| c.active_tab = "pages" }
  
  def index
    if authorized_action(@context, @current_user, :read)
      respond_to do |format|
        format.html {
          add_crumb(@page.title, course_wiki_page_url( @context.id, @page))
          add_crumb("Revisions")
          log_asset_access(@page, "wiki", @namespace)
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
    @version = Version.find(:first, :conditions => {:versionable_type => 'WikiPage', :versionable_id => params[:wiki_page_id]}, :order => 'number DESC')
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
    if authorized_action(@page, @current_user, :read)
      if params[:id] == "latest"
        @revision = @page.versions[0]
      else
        @revision = @page.versions.find(params[:id])
      end
      respond_to do |format|
        format.html {
          add_crumb(@page.title, course_wiki_page_url( @context.id, @page))
          log_asset_access(@page, "wiki", @namespace)
        }
        @model = @revision.model rescue nil
        format.json { render :json => @model.to_json(:methods => :version_number) }
      end
    end
  end
  
  def update
    if authorized_action(@page, @current_user, :update)
      @revision = @page.versions.find(params[:id])
      @page.revert_to_version @revision
      flash[:notice] = 'Page was successfully rolled-back to previous version.'
      redirect_to course_wiki_page_url( @context.id, @page)
    end
  end
end
