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

# @API Pages
#
# Pages are rich content associated with Courses and Groups in Canvas.
# The Pages API allows this content to be enumerated and retrieved.
#
# @object Page
#     {
#       // the unique locator for the page
#       url: "my-page-title",
#
#       // the title of the page
#       title: "My Page Title",
#
#       // the creation date for the page
#       created_at: "2012-08-06T16:46:33-06:00",
#
#       // the date the page was last updated
#       updated_at: "2012-08-08T14:25:20-06:00",
#
#       // whether this page is hidden from students
#       // (note: students will never see this true; pages hidden from them will be omitted from results)
#       hide_from_students: false,
#
#       // the page content, in HTML
#       // (present when requesting a single page; omitted when listing pages)
#       body: "<p>Page Content</p>"
#     }
class WikiPagesController < ApplicationController
  before_filter :require_context
  before_filter :get_wiki_page, :except => [:index, :api_index, :api_show]
  add_crumb(proc { t '#crumbs.wiki_pages', "Pages"}) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_wiki_pages_url }
  before_filter { |c| c.active_tab = "pages" }

  include Api::V1::WikiPage

  def show
    @editing = true if Canvas::Plugin.value_to_boolean(params[:edit])
    if @page.deleted? && !@page.grants_right?(@current_user, session, :update) && @page.url != 'front-page'
      flash[:notice] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
      redirect_to named_context_url(@context, :context_wiki_page_url, 'front-page')
      return
    end
    if @context.try_rescue(:wiki_is_public) || is_authorized_action?(@page, @current_user, :read)
      add_crumb(@page.title)
      update_view_count(@page)
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

  # @API List pages
  #
  # Lists the wiki pages associated with a course or group.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/123/pages
  #
  # @returns [Page]
  def api_index
    if authorized_action(@context.wiki.wiki_pages.new, @current_user, :read)
      pages_route = polymorphic_url([:api_v1, @context, :wiki_pages])
      scope = @context.wiki.wiki_pages.active.order_by_id
      view_hidden = is_authorized_action?(@context.wiki.wiki_pages.new(:hide_from_students => true), @current_user, :read)
      scope = scope.visible_to_students unless view_hidden
      wiki_pages = Api.paginate(scope, self, pages_route)
      render :json => wiki_pages_json(wiki_pages, @current_user, session)
    end
  end

  # @API Show page
  #
  # Retrieves the content of a wiki page.
  #
  # @argument url the unique identifier for a page.  Use 'front-page' to retrieve the front page of the wiki.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/123/pages/front-page
  #
  # @returns Page
  def api_show
    # not using get_wiki_page since this API is read-only for now
    @wiki = @context.wiki
    @page = @wiki.wiki_pages.active.find_by_url!(params[:url])
    if @context.try_rescue(:wiki_is_public) || authorized_action(@page, @current_user, :read)
      update_view_count(@page)
      render :json => wiki_page_json(@page, @current_user, session)
    end
  end

  def update
    if authorized_action(@page, @current_user, :update_content)
      unless @page.grants_right?(@current_user, session, :update)
        params[:wiki_page] = {:body => params[:wiki_page][:body], :title => params[:wiki_page][:title]}
      end
      @page.workflow_state = 'active' if @page.deleted?
      if @page.update_attributes(params[:wiki_page].merge(:user_id => @current_user.id))
        log_asset_access(@page, "wiki", @wiki, 'participate')
        generate_new_page_view
        @page.context_module_action(@current_user, @context, :contributed)
        flash[:notice] = t('notices.page_updated', 'Page was successfully updated.')
        respond_to do |format|
          format.html { return_to(params[:return_to], context_wiki_page_url(:edit => params[:action] == 'create')) }
          format.json {
            json = @page.as_json
            json[:success_url] = context_wiki_page_url(:edit => params[:action] == 'create')
            render :json => json
          }
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
        flash[:notice] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
        @page.workflow_state = 'deleted'
        @page.save
        respond_to do |format|
          format.html { redirect_to(named_context_url(@context, :context_wiki_pages_url)) }
        end
      else #they dont have permissions to destroy this page
        respond_to do |format|
          format.html { 
            flash[:error] = t('errors.permission_denied', 'You are not permitted to delete that page.')
            redirect_to(named_context_url(@context, :context_wiki_pages_url))
          }
        end
      end
    end
  end

  protected

  def context_wiki_page_url(opts={})
    page_name = @page.url
    res = named_context_url(@context, :context_wiki_page_url, page_name)
    if opts && opts[:edit]
      res += "#edit"
    end
   res
  end

  def update_view_count(page)
    unless page.new_record?
      page.with_versioning(false) do |p|
        p.context_module_action(@current_user, @context, :read)
        WikiPage.connection.execute("UPDATE wiki_pages SET view_count=COALESCE(view_count, 0) + 1 WHERE id=#{p.id}")
      end
      log_asset_access(page, "wiki", @wiki)
    end
  end
 
end
