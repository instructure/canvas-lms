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
        redirect_to polymorphic_url([@context, :wiki_page], id: @page_name || @page, titleize: params[:titleize], action: :edit)
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
      add_crumb(@page.title)
      log_asset_access(@page, 'wiki', @wiki)

      js_data = {}
      js_data[:wiki_page_menu_tools] = external_tools_display_hashes(:wiki_page_menu)
      if params[:module_item_id]
        js_data[:ModuleSequenceFooter_data] = item_sequence_base(Api.api_type_to_canvas_name('ModuleItem'), params[:module_item_id])
      end

      # This next bit is to set the module listing into the javascript
      # data so we can use it to build tables of contents without needing
      # additional ajax queries to get the available modules
      module_item_id = params[:module_item_id]

      # If the item ID isn't already on the url, we need to look it up from the tags
      # to avoid the TOC from breaking on some links (while working if you hit next then prev!)
      if !module_item_id
        module_item_id = ContentTag.where(
          :content_type => 'WikiPage',
          :content_id => @page.id,
          :context_type => 'Course',
          :context_id => @context.id)
        if !module_item_id.empty?
          module_item_id = module_item_id.first.id
        else
          module_item_id = nil
        end
      end

      if module_item_id
        done = false # Ruby doesn't have `break outer_loop;` so i'll use a flag
        # Gotta loop through them all and find the module that we are actually
        # currently in, so the javascript will have the right context for its
        # corresponding search
        @context.context_modules.each do |context_module|
          possible_items = context_module.content_tags_visible_to(@current_user)
          possible_items.each do |item|
            # if the searched module includes the current item, it is usable to us!
            # now, the script will use this data to generate a table of contents of
            # the surrounding items.
            if item.id.to_i == module_item_id.to_i
              js_data[:module_listing_data] = possible_items
              done = true
              break
            end
          end
          break if done
        end
      end

      js_env js_data

      wiki_page_jsenv(@context)
      @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user)
      @padless = true
      if !@context.feature_enabled?(:conditional_release) || enforce_assignment_visible(@page)
        add_crumb(@page.title)
        log_asset_access(@page, 'wiki', @wiki)
        wiki_page_jsenv(@context)
        @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user)
        @padless = true
      end
    end
  end

  def edit
    if @page.grants_any_right?(@current_user, session, :update, :update_content)
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
