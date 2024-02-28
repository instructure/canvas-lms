# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  before_action :require_context
  before_action :get_wiki_page, except: [:front_page]
  before_action :set_front_page, only: [:front_page]
  before_action :set_pandapub_read_token
  before_action :set_js_rights
  before_action :set_js_wiki_data
  before_action :rce_js_env, only: [:edit, :index]

  include K5Mode

  add_crumb(proc { t "#crumbs.wiki_pages", "Pages" }) do |c|
    context = c.instance_variable_get(:@context)
    current_user = c.instance_variable_get(:@current_user)
    if context.grants_right?(current_user, :read)
      c.send :polymorphic_path, [context, :wiki_pages]
    end
  end
  before_action { |c| c.active_tab = "pages" }

  def js_rights
    [:wiki, :page]
  end

  def set_pandapub_read_token
    if @page&.grants_right?(@current_user, session, :read) && CanvasPandaPub.enabled?
      channel = "/private/wiki_page/#{@page.global_id}/update"
      js_env WIKI_PAGE_PANDAPUB: {
        CHANNEL: channel,
        TOKEN: CanvasPandaPub.generate_token(channel, true)
      }
    end
  end

  def set_front_page
    @wiki = @context.wiki
    @page = @wiki.front_page
  end

  def front_page
    return unless authorized_action(@context.wiki, @current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)

    if @page && !@page.new_record?
      wiki_pages_js_env(@context)
      @padless = true
      js_bundle :wiki_page_show
      css_bundle :wiki_page
      render template: "wiki_pages/show"
    else
      redirect_to polymorphic_url([@context, :wiki_pages])
    end
  end

  def index
    GuardRail.activate(:secondary) do
      if authorized_action(@context.wiki, @current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)
        log_asset_access(["pages", @context], "pages", "other")
        js_env(ConditionalRelease::Service.env_for(@context))
        wiki_pages_js_env(@context)
        set_tutorial_js_env
        @padless = true
      end
    end
  end

  def show
    GuardRail.activate(:secondary) do
      if @page.new_record?
        wiki_page = @context.wiki_pages.deleted_last.where(url: @page.url).first
        if @page.grants_any_right?(@current_user, session, :update, :update_content)
          flash[:info] = t("notices.create_non_existent_page", 'The page "%{title}" does not exist, but you can create it below', title: @page.title)
          InstStatsd::Statsd.increment("wikipage.show.page_does_not_exist.with_edit_rights") unless wiki_page&.deleted?
          encoded_name = @page_name && CGI.escape(@page_name).tr("+", " ")
          redirect_to polymorphic_url([@context, :wiki_page], id: encoded_name || @page, titleize: params[:titleize], action: :edit)
        else
          flash[:warning] = if wiki_page&.deleted?
                              t("notices.page_deleted", 'The page "%{title}" has been deleted.', title: @page.title)
                            else
                              InstStatsd::Statsd.increment("wikipage.show.page_does_not_exist.without_edit_rights")
                              t("notices.page_does_not_exist", 'The page "%{title}" does not exist.', title: @page.title)
                            end
          redirect_to polymorphic_url([@context, :wiki_pages])
        end
        return
      end

      if authorized_action(@page, @current_user, :read) &&
         (!@context.conditional_release? || enforce_assignment_visible(@page))
        if params[:id] != @page.url
          InstStatsd::Statsd.increment("wikipage.show.page_url_resolved")
          redirect_to polymorphic_url([@context, :wiki_page], id: @page, titleize: params[:titleize])
        end
        add_crumb(@page.title)
        log_asset_access(@page, "wiki", @wiki)
        wiki_pages_js_env(@context)
        set_master_course_js_env_data(@page, @context)
        @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user, @page)
        @padless = true
      end
      js_bundle :wiki_page_show
      css_bundle :wiki_page
    end
  end

  def edit
    if @page.grants_any_right?(@current_user, session, :update, :update_content) && !@page.editing_restricted?(:content)
      set_master_course_js_env_data(@page, @context)
      js_env(ConditionalRelease::Service.env_for(@context))
      wiki_pages_js_env(@context)
      if !ConditionalRelease::Service.enabled_in_context?(@context) ||
         enforce_assignment_visible(@page)
        add_crumb(@page.title)
        @padless = true
      end
    elsif authorized_action(@page, @current_user, :read)
      flash[:warning] = t("notices.cannot_edit", 'You are not allowed to edit the page "%{title}".', title: @page.title)
      redirect_to polymorphic_url([@context, @page])
    end
  end

  def revisions
    if @page.grants_right?(@current_user, session, :read_revisions)
      if !@context.conditional_release? || enforce_assignment_visible(@page)
        add_crumb(@page.title, polymorphic_url([@context, @page]))
        add_crumb(t("#crumbs.revisions", "Revisions"))

        @padless = true
      end
    elsif authorized_action(@page, @current_user, :read)
      flash[:warning] = t("notices.cannot_read_revisions", 'You are not allowed to review the historical revisions of "%{title}".', title: @page.title)
      redirect_to polymorphic_url([@context, @page])
    end
  end

  def show_redirect
    redirect_to polymorphic_url([@context, @page],
                                titleize: params[:titleize],
                                module_item_id: params[:module_item_id]),
                status: :moved_permanently
  end

  def revisions_redirect
    redirect_to polymorphic_url([@context, @page, :revisions]), status: :moved_permanently
  end

  private

  def wiki_pages_js_env(context)
    set_k5_mode # we need this to run now, even though we haven't hit the render hook yet
    @wiki_pages_env ||= {
      wiki_page_menu_tools: external_tools_display_hashes(:wiki_page_menu),
      wiki_index_menu_tools: external_tools_display_hashes(:wiki_index_menu),
      DISPLAY_SHOW_ALL_LINK: tab_enabled?(context.class::TAB_PAGES, no_render: true) && !@k5_details_view,
      CAN_SET_TODO_DATE: context.grants_any_right?(@current_user, session, :manage_content, :manage_course_content_edit),
      BLOCK_EDITOR: context.account.feature_enabled?(:block_editor)
    }
    if Account.site_admin.feature_enabled?(:permanent_page_links)
      title_availability_path = context.is_a?(Course) ? api_v1_course_page_title_availability_path : api_v1_group_page_title_availability_path
      @wiki_pages_env[:TITLE_AVAILABILITY_PATH] = title_availability_path
    end
    js_env(@wiki_pages_env)
    @wiki_pages_env
  end
end
