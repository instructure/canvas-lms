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
  include Api::V1::WikiPage
  include KalturaHelper

  before_filter :require_context
  before_filter :get_wiki_page
  before_filter :set_js_rights, :only => [:pages_index, :show_page, :edit_page, :page_revisions]
  before_filter :set_js_wiki_data, :only => [:pages_index, :show_page, :edit_page, :page_revisions]
  add_crumb(proc { t '#crumbs.wiki_pages', "Pages"}) do |c|
    url = nil
    context = c.instance_variable_get('@context')
    current_user = c.instance_variable_get('@current_user')
    if context.grants_right?(current_user, :read)
      if context.feature_enabled?(:draft_state)
        url = c.send :polymorphic_path, [context, :pages]
      else
        url = c.send :named_context_url, c.instance_variable_get("@context"), :context_wiki_pages_url
      end
    end
    url
  end
  before_filter { |c| c.active_tab = "pages" }

  def js_rights
    [:wiki, :page]
  end

  def show
    if @context.feature_enabled?(:draft_state)
      redirect_to polymorphic_url([@context, :named_page], :wiki_page_id => @page)
      return
    end
    @editing = true if Canvas::Plugin.value_to_boolean(params[:edit])
    hash = { :CONTEXT_ACTION_SOURCE => :wiki,
             :WIKI_PAGE_EDITING => @editing}
    append_sis_data(hash)
    js_env(hash)

    unless is_authorized_action?(@page, @current_user, [:update, :update_content]) || @page.is_front_page?
      wiki_page = @wiki.wiki_pages.deleted_last.find_by_url(@page.url) if @page.new_record?
      if wiki_page && wiki_page.deleted?
        flash[:warning] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
        return redirect_to named_context_url(@context, :context_wiki_page_url, @wiki.get_front_page_url)
      end
    end

    if is_authorized_action?(@page, @current_user, :read)
      add_crumb(@page.title)
      @page.increment_view_count(@current_user, @context)
      log_asset_access(@page, "wiki", @wiki)
      respond_to do |format|
        format.html {render :action => "show" }
        format.json {render :json => @page }
      end
    else
      render_unauthorized_action
    end
  end

  def index
    return unless tab_enabled?(@context.class::TAB_PAGES)

    if @context.feature_enabled?(:draft_state)
      front_page
    else
      redirect_to named_context_url(@context, :context_wiki_page_url, @context.wiki.get_front_page_url || Wiki::DEFAULT_FRONT_PAGE_URL)
    end
  end

  def update
    if authorized_action(@page, @current_user, :update_content)
      unless @page.grants_right?(@current_user, session, :update)
        params[:wiki_page] = {:body => params[:wiki_page][:body]}
      end
      perform_update
    end
  end

  def create
    if authorized_action(@page, @current_user, :create)
      perform_update
      unless @wiki.grants_right?(@current_user, session, :manage)
        @page.workflow_state = 'active'
        @page.editing_roles = (@context.default_wiki_editing_roles rescue nil) || @page.default_roles
        @page.save!
      end
    end
  end

  def perform_update
    if params[:wiki_page].include?(:hide_from_students)
      hide_from_students = Canvas::Plugin::value_to_boolean(params[:wiki_page].delete(:hide_from_students))
      if hide_from_students
        @page.workflow_state = 'unpublished'
      else
        @page.workflow_state = 'published'
      end
    end

    if @page.update_attributes(params[:wiki_page].merge(:user_id => @current_user.id))
      unless @page.context.feature_enabled?(:draft_state)
        @page.set_as_front_page! if @page.is_front_page?
      end

      log_asset_access(@page, "wiki", @wiki, 'participate')
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
        format.json { render :json => @page.errors, :status => :bad_request }
      end
    end
  end

  def destroy
    if authorized_action(@page, @current_user, :delete)
      if !@page.is_front_page?
        flash[:notice] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
        @page.workflow_state = 'deleted'
        @page.save
        respond_to do |format|
          format.html { redirect_to(named_context_url(@context, :context_wiki_pages_url)) }
        end
      else #they dont have permissions to destroy this page
        respond_to do |format|
          format.html { 
            flash[:error] = t('errors.cannot_delete_front_page', 'You cannot delete the front page.')
            redirect_to(named_context_url(@context, :context_wiki_pages_url))
          }
        end
      end
    end
  end

  def front_page
    return unless tab_enabled?(@context.class::TAB_PAGES)

    front_page = @context.wiki.front_page if @context.wiki.has_front_page?
    if front_page && !front_page.new_record?
      redirect_to polymorphic_url([@context, :named_page], :wiki_page_id => @context.wiki.front_page)
    else
      redirect_to polymorphic_url([@context, :pages])
    end
  end

  def pages_index
    if !@context.feature_enabled?(:draft_state)
      redirect_to polymorphic_url([@context, :wiki_pages])
      return
    end

    if authorized_action(@context.wiki, @current_user, :read)
      @padless = true
    end
  end

  def show_page
    if !@context.feature_enabled?(:draft_state)
      redirect_to polymorphic_url([@context, :named_wiki_page], :id => @page)
      return
    end

    if @page.new_record?
      if is_authorized_action?(@page, @current_user, [:update, :update_content])
        flash[:info] = t('notices.create_non_existent_page', 'The page "%{title}" does not exist, but you can create it below', :title => @page.title)
        redirect_to polymorphic_url([@context, :edit_named_page], :wiki_page_id => @page)
        return
      else
        wiki_page = @wiki.wiki_pages.deleted_last.find_by_url(@page.url)
        if wiki_page && wiki_page.deleted?
          flash[:warning] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
        else
          flash[:warning] = t('notices.page_does_not_exist', 'The page "%{title}" does not exist.', :title => @page.title)
        end
        return front_page # delegate to front_page logic
      end
    end

    if authorized_action(@page, @current_user, :read)
      add_crumb(@page.title)
      @page.increment_view_count(@current_user, @context)
      log_asset_access(@page, 'wiki', @wiki)

      @padless = true
      render
    end
  end

  def edit_page
    if !@context.feature_enabled?(:draft_state)
      redirect_to polymorphic_url([@context, :named_wiki_page], :id => @page) + '#edit'
      return
    end

    if is_authorized_action?(@page, @current_user, [:update, :update_content])
      add_crumb(@page.title)

      @padless = true
      render
    else
      if authorized_action(@page, @current_user, :read)
        flash[:warning] = t('notices.cannot_edit', 'You are not allowed to edit the page "%{title}".', :title => @page.title)
        redirect_to polymorphic_url([@context, :named_page], :wiki_page_id => @page)
      end
    end
  end

  def page_revisions
    if !@context.feature_enabled?(:draft_state)
      redirect_to polymorphic_url([@context, @page, :wiki_page_revisions])
      return
    end

    if is_authorized_action?(@page, @current_user, :read_revisions)
      add_crumb(@page.title, polymorphic_url([@context, :named_page], :wiki_page_id => @page))
      add_crumb(t("#crumbs.revisions", "Revisions"))

      @padless = true
      render
    else
      if authorized_action(@page, @current_user, :read)
        flash[:warning] = t('notices.cannot_read_revisions', 'You are not allowed to review the historical revisions of "%{title}".', :title => @page.title)
        redirect_to polymorphic_url([@context, :named_page], :wiki_page_id => @page)
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

end
