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

class EportfoliosController < ApplicationController
  include EportfolioPage
  before_action :require_user, only: [:index, :user_index]
  before_action :reject_student_view_student
  before_action :verified_user_check, only: %i[index user_index create]
  before_action :get_eportfolio, except: %i[index user_index create]

  def index
    user_index
  end

  def user_index
    @context = @current_user.profile
    return unless tab_enabled?(UserProfile::TAB_EPORTFOLIOS)

    rce_js_env
    set_active_tab "eportfolios"
    add_crumb(@current_user.short_name, user_profile_url(@current_user))
    add_crumb(t(:crumb, "ePortfolios"))
    @portfolios = @current_user.eportfolios.active.order(:updated_at).to_a
    render :user_index
  end

  def create
    if authorized_action(Eportfolio.new, @current_user, :create)
      @portfolio = @current_user.eportfolios.build(eportfolio_params)
      respond_to do |format|
        if @portfolio.save
          @portfolio.ensure_defaults
          flash[:notice] = t("notices.created", "ePortfolio successfully created")
          format.html { redirect_to eportfolio_url(@portfolio) }
          format.json { render json: @portfolio.as_json(permissions: { user: @current_user, session: }) }
        else
          format.html do
            rce_js_env
            render :new
          end
          format.json { render json: @portfolio.errors, status: :bad_request }
        end
      end
    end
  end

  def show
    if params[:verifier] == @portfolio.uuid
      session[:eportfolio_ids] ||= []
      session[:eportfolio_ids] << @portfolio.id
      session[:permissions_key] = SecureRandom.uuid
    end
    if authorized_action(@portfolio, @current_user, :read)
      rce_js_env
      @portfolio.ensure_defaults
      @category = @portfolio.eportfolio_categories.first
      @page = @category.eportfolio_entries.first
      @owner_view = @portfolio.user == @current_user && params[:view] != "preview"
      if @owner_view
        @used_submission_ids = []
        @portfolio.eportfolio_entries.each do |entry|
          entry.content_sections.each do |s|
            if s.is_a?(Hash) && s[:section_type] == "submission"
              @used_submission_ids << s[:submission_id].to_i
            end
          end
        end
      end
      @show_left_side = true
      eportfolio_page_attributes
      if @current_user
        # if profiles are enabled and I can message the portfolio's owner, link
        # to their profile
        @owner_url = user_profile_url(@portfolio.user) if @domain_root_account.enable_profiles? && @current_user.address_book.known_user(@portfolio.user)

        # otherwise, if I'm the portfolio's owner (implying I can message
        # myself, so therefore profiles just aren't enabled), link to my
        # profile
        @owner_url ||= profile_url if @current_user == @portfolio.user

        # otherwise, if  I can otherwise view the user, link directly to them
        @owner_url ||= user_url(@portfolio.user) if @portfolio.user.grants_right?(@current_user, :view_statistics)
      end

      if can_do(@portfolio, @current_user, :update)
        content_for_head helpers.auto_discovery_link_tag(:atom, feeds_eportfolio_path(@portfolio.id, :atom, verifier: @portfolio.uuid), { title: t("titles.feed", "Eportfolio Atom Feed") })
      elsif @portfolio.public
        content_for_head helpers.auto_discovery_link_tag(:atom, feeds_eportfolio_path(@portfolio.id, :atom), { title: t("titles.feed", "Eportfolio Atom Feed") })
      end
    end
  end

  def update
    update_params = if @portfolio.grants_right?(@current_user, session, :update)
                      eportfolio_params
                    elsif @portfolio.grants_right?(@current_user, :moderate)
                      eportfolio_moderation_params
                    end

    if update_params
      respond_to do |format|
        if @portfolio.update(update_params)
          @portfolio.ensure_defaults
          flash[:notice] = t("notices.updated", "ePortfolio successfully updated")
          format.html { redirect_to eportfolio_url(@portfolio) }
          format.json { render json: @portfolio.as_json(permissions: { user: @current_user, session: }) }
        else
          format.html do
            rce_js_env
            render :edit
          end
          format.json { render json: @portfolio.errors, status: :bad_request }
        end
      end
    else
      render_unauthorized_action
    end
  end

  def destroy
    if authorized_action(@portfolio, @current_user, :delete)
      respond_to do |format|
        if @portfolio.destroy
          flash[:notice] = t("notices.deleted", "ePortfolio successfully deleted")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render json: @portfolio }
        else
          format.html { render :delete }
          format.json { render json: @portfolio.errors, status: :bad_request }
        end
      end
    end
  end

  def reorder_categories
    if authorized_action(@portfolio, @current_user, :update)
      order = params[:order].split(",").map { |id| Shard.relative_id_for(id, Shard.current, @portfolio.shard) }
      @portfolio.eportfolio_categories.build.update_order(order)
      render json: @portfolio.eportfolio_categories.map { |c| [c.id, c.position] }, status: :ok
    end
  end

  def reorder_entries
    if authorized_action(@portfolio, @current_user, :update)
      order = params[:order].split(",").map { |id| Shard.relative_id_for(id, Shard.current, @portfolio.shard) }
      @category = @portfolio.eportfolio_categories.find(params[:eportfolio_category_id])
      @category.eportfolio_entries.build.update_order(order)
      render json: @portfolio.eportfolio_entries.map { |c| [c.id, c.position] }, status: :ok
    end
  end

  def export
    zip_filename = "eportfolio.zip"
    if authorized_action(@portfolio, @current_user, :update)
      @attachments = @portfolio.attachments.not_deleted
                               .where(display_name: zip_filename,
                                      workflow_state: %w[to_be_zipped zipping zipped unattached],
                                      user_id: @current_user)
      @attachment = @attachments.order(:created_at).last
      @attachments.where.not(id: @attachment).find_each(&:destroy_permanently_plus)

      if @attachment && stale_zip_file?
        @attachment.destroy_permanently_plus
        @attachment = nil
      end

      if @attachment
        respond_to do |format|
          if @attachment.zipped?
            if @attachment.stored_locally?
              cancel_cache_buster
              format.html { send_file(@attachment.full_filename, type: @attachment.content_type_with_encoding, disposition: "inline") }
              format.zip { send_file(@attachment.full_filename, type: @attachment.content_type_with_encoding, disposition: "inline") }
            else
              inline_url = authenticated_inline_url(@attachment)
              format.html { redirect_to inline_url }
              format.zip { redirect_to inline_url }
            end
            format.json { render json: @attachment.as_json(methods: :readable_size) }
          else
            flash[:notice] = t("notices.zipping", "File zipping still in process...")
            format.html { redirect_to eportfolio_url(@portfolio.id) }
            format.zip { redirect_to eportfolio_url(@portfolio.id) }
            format.json { render json: @attachment }
          end
        end
      else
        @attachment = @portfolio.attachments.build(display_name: zip_filename)
        @attachment.workflow_state = "to_be_zipped"
        @attachment.file_state = "0"
        @attachment.user = @current_user
        @attachment.save!
        ContentZipper.delay(priority: Delayed::LOW_PRIORITY).process_attachment(@attachment)
        render json: @attachment
      end
    end
  end

  def public_feed
    if @portfolio.public || params[:verifier] == @portfolio.uuid
      @entries = @portfolio.eportfolio_entries.order("eportfolio_entries.created_at DESC").to_a

      title = t(:title, "%{portfolio_name} Feed", portfolio_name: @portfolio.name)
      updated = @entries.first.updated_at rescue Time.now
      link = eportfolio_url(@portfolio.id)

      private_value = params[:verifier] == @portfolio.uuid

      respond_to do |format|
        format.atom { render plain: AtomFeedHelper.render_xml(title:, link:, updated:, entries: @entries, private: private_value) }
      end
    else
      authorized_action(nil, nil, :bad_permission)
    end
  end

  protected

  def eportfolio_params
    params.require(:eportfolio).permit(:name, :public)
  end

  def eportfolio_moderation_params
    params.require(:eportfolio).permit(:spam_status)
  end

  def get_eportfolio
    @portfolio = Eportfolio.active.find(params[:eportfolio_id] || params[:id])
  end

  def stale_zip_file?
    @attachment.created_at < 1.hour.ago ||
      @attachment.created_at < (@portfolio.eportfolio_entries.filter_map(&:updated_at).max || @attachment.created_at)
  end
end
