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
  include SubmittableHelper

  before_filter :require_context
  before_filter :get_wiki_page, :except => [:front_page]
  before_filter :set_front_page, :only => [:front_page]
  before_filter :set_pandapub_read_token
  before_filter :set_js_rights
  before_filter :set_js_wiki_data
  before_filter :rich_content_service_config, only: [:edit, :index]

  add_crumb(proc { t '#crumbs.wiki_pages', "Pages"}) do |c|
    context = c.instance_variable_get('@context')
    current_user = c.instance_variable_get('@current_user')
    if context.grants_right?(current_user, :read)
      c.send :polymorphic_path, [context, :wiki_pages]
    end
  end
  before_filter { |c| c.active_tab = "pages" }

  def js_rights
    [:wiki, :page]
  end

  def set_pandapub_read_token
    if @page && @page.grants_right?(@current_user, session, :read)
      if CanvasPandaPub.enabled?
        channel = "/private/wiki_page/#{@page.global_id}/update"
        js_env :WIKI_PAGE_PANDAPUB => {
          :CHANNEL => channel,
          :TOKEN => CanvasPandaPub.generate_token(channel, true)
        }
      end
    end
  end

  def set_front_page
    @wiki = @context.wiki
    @page = @wiki.front_page
  end

  def front_page
    return unless authorized_action(@context.wiki, @current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)

    if @page && !@page.new_record?
      wiki_page_jsenv(@context)
      @padless = true
      render template: 'wiki_pages/show'
    else
      redirect_to polymorphic_url([@context, :wiki_pages])
    end
  end

  def index
    if authorized_action(@context.wiki, @current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)
      log_asset_access([ "pages", @context ], "pages", "other")
      js_env ConditionalRelease::Service.env_for @context
      js_env :wiki_page_menu_tools => external_tools_display_hashes(:wiki_page_menu)
      @padless = true
    end
  end

  def show
    if @page.new_record?
      if @page.grants_any_right?(@current_user, session, :update, :update_content)
        flash[:info] = t('notices.create_non_existent_page', 'The page "%{title}" does not exist, but you can create it below', :title => @page.title)
        encoded_name = @page_name && CGI.escape(@page_name).gsub("+", " ")
        redirect_to polymorphic_url([@context, :wiki_page], id: encoded_name || @page, titleize: params[:titleize], action: :edit)
      else
        wiki_page = @wiki.wiki_pages.deleted_last.where(url: @page.url).first
        if wiki_page && wiki_page.deleted?
          flash[:warning] = t('notices.page_deleted', 'The page "%{title}" has been deleted.', :title => @page.title)
        else
          flash[:warning] = t('notices.page_does_not_exist', 'The page "%{title}" does not exist.', :title => @page.title)
        end
        redirect_to polymorphic_url([@context, :wiki_pages])
      end
      return
    end

    if authorized_action(@page, @current_user, :read)
      if !@context.feature_enabled?(:conditional_release) || enforce_assignment_visible(@page)
        add_crumb(@page.title)
        log_asset_access(@page, 'wiki', @wiki)
        wiki_page_jsenv(@context)
        @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user, @page)
        @padless = true
      end
    end
  end

  def edit
    if @page.grants_any_right?(@current_user, session, :update, :update_content)
      return render_unauthorized_action if editing_restricted?(@page)

      js_env ConditionalRelease::Service.env_for @context
      if !ConditionalRelease::Service.enabled_in_context?(@context) ||
        enforce_assignment_visible(@page)
        add_crumb(@page.title)
        @padless = true
      end
    else
      if authorized_action(@page, @current_user, :read)
        flash[:warning] = t('notices.cannot_edit', 'You are not allowed to edit the page "%{title}".', :title => @page.title)
        redirect_to polymorphic_url([@context, @page])
      end
    end
  end

  def revisions
    if @page.grants_right?(@current_user, session, :read_revisions)
      if !@context.feature_enabled?(:conditional_release) || enforce_assignment_visible(@page)
        add_crumb(@page.title, polymorphic_url([@context, @page]))
        add_crumb(t("#crumbs.revisions", "Revisions"))

        @padless = true
      end
    else
      if authorized_action(@page, @current_user, :read)
        flash[:warning] = t('notices.cannot_read_revisions', 'You are not allowed to review the historical revisions of "%{title}".', :title => @page.title)
        redirect_to polymorphic_url([@context, @page])
      end
    end
  end

  def show_redirect
    redirect_to polymorphic_url([@context, @page], :titleize => params[:titleize],
                                :module_item_id => params[:module_item_id]), status: :moved_permanently
  end

  def revisions_redirect
    redirect_to polymorphic_url([@context, @page, :revisions]), status: :moved_permanently
  end

  private
  def rich_content_service_config
    rce_js_env(:sidebar)
  end

  def wiki_page_jsenv(context)
    js_env :wiki_page_menu_tools => external_tools_display_hashes(:wiki_page_menu)
    js_env :DISPLAY_SHOW_ALL_LINK => tab_enabled?(context.class::TAB_PAGES, {no_render: true})
  end
end
