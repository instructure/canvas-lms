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
# The Pages API allows you to create, retrieve, update, and delete ages.
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
#       // roles allowed to edit the page; comma-separated list comprising a combination of
#       // 'teachers', 'students', and/or 'public'
#       // if not supplied, course defaults are used
#       editing_roles: "teachers,students",
#
#       // the User who last edited the page
#       // (this may not be present if the page was imported from another system)
#       last_edited_by: { 
#         id: 133,
#         display_name: "Rey del Pueblo",
#         avatar_image_url: "https://canvas.example.com/images/thumbnails/bm90aGluZyBoZXJl",
#         html_url: "https://canvas.example.com/courses/789/users/133"
#       },
#
#       // the page content, in HTML
#       // (present when requesting a single page; omitted when listing pages)
#       body: "<p>Page Content</p>",
#
#       // whether the page is published
#       published: true,
#
#       // whether this page is the front page for the wiki
#       front_page: false,
#
#       // Whether or not this is locked for the user.
#       locked_for_user: false,
#
#       // (Optional) Information for the user about the lock. Present when locked_for_user is true.
#       lock_info: {
#         // Asset string for the object causing the lock
#         asset_string: "wiki_page_1",
#
#         // (Optional) Context module causing the lock.
#         context_module: { ... }
#       },
#
#       // (Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.
#       lock_explanation: "This discussion is locked until September 1 at 12:00am"
#     }
class WikiPagesApiController < ApplicationController
  before_filter :require_context
  before_filter :get_wiki_page, :except => [:create, :index]
  before_filter :was_front_page, :except => [:index]

  include Api::V1::WikiPage

  # @API List pages
  #
  # List the wiki pages associated with a course or group
  #
  # @argument sort [optional] Sort results by this field: one of 'title', 'created_at', or 'updated_at'
  # @argument order [optional] The sorting order: 'asc' (default) or 'desc'
  # @argument search_term (optional) The partial title of the pages to match and return.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/123/pages?sort=title&order=asc
  #
  # @returns [Page]
  def index
    if authorized_action(@context.wiki, @current_user, :read)
      pages_route = polymorphic_url([:api_v1, @context, :wiki_pages])
      # omit body from selection, since it's not included in index results
      scope = @context.wiki.wiki_pages.select(WikiPage.column_names - ['body']).includes(:user)
      scope = @context.grants_right?(@current_user, session, :view_unpublished_items) ? scope.not_deleted : scope.active
      scope = scope.visible_to_students unless @context.grants_right?(@current_user, session, :view_hidden_items)

      scope = WikiPage.search_by_attribute(scope, :title, params[:search_term])

      order_clause = case params[:sort]
        when 'title'
          WikiPage.title_order_by_clause
        when 'created_at'
          'wiki_pages.created_at'
        when 'updated_at'
          'wiki_pages.updated_at'
        else
          'wiki_pages.id'
      end
      order_clause += ' DESC' if params[:order] == 'desc'
      scope = scope.order(order_clause)

      wiki_pages = Api.paginate(scope, self, pages_route)
      render :json => wiki_pages_json(wiki_pages, @current_user, session)
    end
  end

  # @API Show page
  #
  # Retrieve the content of a wiki page
  #
  # @argument url the unique identifier for a page.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/123/pages/my-page-url
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/123/front_page
  #
  # @returns Page
  def show
    if authorized_action(@page, @current_user, :read)
      @page.increment_view_count(@current_user, @context)
      log_asset_access(@page, "wiki", @wiki)
      render :json => wiki_page_json(@page, @current_user, session)
    end
  end

  # @API Create page
  #
  # Create a new wiki page
  #
  # @argument wiki_page[title] the title for the new page.
  # @argument wiki_page[body] the content for the new page.
  # @argument wiki_page[hide_from_students] [boolean] whether the page should be hidden from students.
  # @argument wiki_page[notify_of_update] [boolean] whether participants should be notified when this page changes.
  # @argument wiki_page[published] [optional] [boolean] whether the page is published (true) or draft state (false).
  # @argument wiki_page[front_page] [optional] [boolean] set an unhidden page as the front page (if true)
  #
  # @example_request
  #     curl -X POST -H 'Authorization: Bearer <token>' \ 
  #     https://<canvas>/api/v1/courses/123/pages?wiki_page[title]=New+page&wiki_page[body]=New+body+text
  #
  # @returns Page
  def create
    @page = @context.wiki.wiki_pages.build
    @wiki = @context.wiki
    if authorized_action(@page, @current_user, :create)
      # default new pages to be published and have the context's default roles (if the user is not a manager)
      unless is_authorized_action?(@wiki, @current_user, :manage)
        @page.workflow_state = 'active'
        @page.editing_roles = (@context.default_wiki_editing_roles rescue nil) || @page.default_roles
      end

      # normal update logic from here (will reject if the user attempts create with attributes they aren't allowed to modify)
      update_params = get_update_params(update_params)
      if !update_params.is_a?(Symbol) && @page.update_attributes(update_params) && process_front_page
        log_asset_access(@page, "wiki", @wiki, 'participate')
        render :json => wiki_page_json(@page, @current_user, session)
      else
        render :json => @page.errors.to_json, :status => update_params.is_a?(Symbol) ? update_params : :bad_request
      end
    end
  end
  
  # @API Update page
  #
  # Update the title or contents of a wiki page
  #
  # @argument url the unique identifier for a page.
  # @argument wiki_page[title] [optional] the new title for the page.
  #     NOTE: changing a page's title will change its url. The updated url will be returned in the result.
  # @argument wiki_page[body] [optional] the new content for the page.
  # @argument wiki_page[hide_from_students] [optional] boolean; whether the page should be hidden from students.
  # @argument wiki_page[notify_of_update] [optional] [boolean] notify participants that the wiki page has been changed.
  # @argument wiki_page[published] [optional] [boolean] whether the page is published (true) or draft state (false)
  # @argument wiki_page[front_page] [optional] [boolean] set an unhidden page as the front page (if true), or un-set it (if false)
  #
  # @example_request
  #     curl -X PUT -H 'Authorization: Bearer <token>' \ 
  #     https://<canvas>/api/v1/courses/123/pages/the-page-url?wiki_page[body]=Updated+body+text
  #
  # @example_request
  #     curl -X PUT -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/front_page?wiki_page[body]=Updated+body+text
  #
  # @returns Page
  def update
    if authorized_action(@page, @current_user, [:update, :update_content])
      update_params = get_update_params
      if !update_params.is_a?(Symbol) && @page.update_attributes(update_params) && process_front_page
        log_asset_access(@page, "wiki", @wiki, 'participate')
        @page.context_module_action(@current_user, @context, :contributed)
        render :json => wiki_page_json(@page, @current_user, session)
      else
        render :json => @page.errors.to_json, :status => update_params.is_a?(Symbol) ? update_params : :bad_request
      end
    end
  end

  # @API Delete page
  #
  # Delete a wiki page
  #
  # @argument url the unique identifier for a page.
  #
  # @example_request
  #     curl -X DELETE -H 'Authorization: Bearer <token>' \ 
  #     https://<canvas>/api/v1/courses/123/pages/the-page-url
  #
  # @example_request
  #     curl -X DELETE -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/front_page
  #
  # @returns Page
  def destroy
    if authorized_action(@page, @current_user, :delete)
      if !@was_front_page || is_authorized_action?(@wiki, @current_user, :update)
        @page.workflow_state = 'deleted'
        @page.save!
        process_front_page
        render :json => wiki_page_json(@page, @current_user, session)
      else
        @page.errors.add(:front_page, t(:cannot_update_front_page, 'You are not allowed to change the wiki front page'))
        render :json => @page.errors.to_json, :status => :unauthorized
      end
    end
  end
  
  protected
  
  def get_wiki_page
    @wiki = @context.wiki
    url = params[:url]
    if url.blank?
      if @wiki.has_front_page?
        url = @wiki.get_front_page_url
      else
        render :status => 404, :json => { :message => t(:no_wiki_front_page, "No front page has been set") }
        return false
      end
    end
    @page = @wiki.wiki_pages.not_deleted.find_by_url!(url)
  end

  def was_front_page
    @was_front_page = false
    @was_front_page = @page.is_front_page? if @page
  end
  
  def get_update_params(page_params=nil)
    # normalize parameters
    page_params = page_params || params[:wiki_page] || {}

    if page_params.has_key?(:published)
      workflow_state = value_to_boolean(page_params.delete(:published)) ? 'active' : 'unpublished'
    end

    if page_params.has_key?(:editing_roles)
      editing_roles = page_params[:editing_roles].split(',').map(&:strip)
      invalid_roles = editing_roles.reject{|role| %w(teachers students members public).include?(role)}
      unless invalid_roles.empty?
        @page.errors.add(:editing_roles, t(:invalid_editing_roles, 'The provided editing roles are invalid'))
        return :bad_request
      end

      page_params[:editing_roles] = editing_roles.join(',')
    end

    if page_params.has_key?(:front_page)
      @set_front_page = true
      @set_as_front_page = value_to_boolean(page_params.delete(:front_page))
    end
    change_front_page = @set_front_page && @was_front_page != @set_as_front_page

    # check user permissions
    errorCount = @page.errors.length
    if @wiki.grants_right?(@current_user, session, :manage)
      @page.workflow_state = workflow_state if workflow_state
    elsif @page.grants_right?(@current_user, session, :update)
      @page.errors.add(:published, t(:cannot_update_published, 'You are not allowed to update the published state of this wiki page')) if workflow_state && workflow_state != @page.workflow_state
    else
      @page.errors.add(:published, t(:cannot_update_published, 'You are not allowed to update the published state of this wiki page')) if workflow_state && workflow_state != @page.workflow_state
      @page.errors.add(:title, t(:cannot_update_title, 'You are not allowed to update the title of this wiki page')) if page_params.include?(:title) && page_params[:title] != @page.title
      @page.errors.add(:hide_from_students, t(:cannot_update_hide_from_students, 'You are not allowed to update the hidden from students flag of this wiki page')) if page_params.include?(:hide_from_students) && page_params[:hide_from_students] != @page.hide_from_students

      if editing_roles
        existing_editing_roles = (@page.editing_roles || '').split(',')
        editing_roles_changed = existing_editing_roles.reject{|role| editing_roles.include?(role)}.length > 0
        editing_roles_changed |= editing_roles.reject{|role| existing_editing_roles.include?(role)}.length > 0
        @page.errors.add(:editing_roles, t(:cannot_update_editing_roles, 'You are not allowed to update the editing roles of this wiki page')) if editing_roles_changed
      end

      if change_front_page && @wiki.grants_right?(@current_user, session, :update)
        @page.errors.add(:front_page, t(:cannot_update_front_page, 'You are not allowed to change the wiki front page'))
      end

      page_params.slice!(:body)
    end
    return :unauthorized if @page.errors.length > errorCount

    page_params[:user_id] = @current_user.id if @current_user
    page_params
  end

  def process_front_page
    if @set_front_page
      if @set_as_front_page && !@page.is_front_page?
        return @page.set_as_front_page!
      elsif !@set_as_front_page
        return @wiki.unset_front_page!
      end
    elsif @was_front_page
      if @page.deleted?
        return @wiki.unset_front_page!
      elsif !@page.is_front_page?
        # if url changes, keep as front page
        return @page.set_as_front_page!
      end
    end
    return true
  end
end
