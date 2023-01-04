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

class EportfolioCategoriesController < ApplicationController
  include EportfolioPage
  before_action :rce_js_env
  before_action :get_eportfolio

  def index
    redirect_to eportfolio_url(@portfolio)
  end

  def create
    if authorized_action(@portfolio, @current_user, :update)
      @category = @portfolio.eportfolio_categories.build(eportfolio_category_params)
      respond_to do |format|
        if @category.save
          @portfolio.eportfolio_entries.create(eportfolio_category: @category, name: t(:default_name, "New Page"), allow_comments: true, show_comments: true)
          format.html { redirect_to eportfolio_category_url(@portfolio, @category) }
          format.json { render json: @category }
        else
          format.json { render json: @category.errors }
        end
      end
    end
  end

  def update
    if authorized_action(@portfolio, @current_user, :update)
      @category = @portfolio.eportfolio_categories.find(params[:id])
      respond_to do |format|
        if @category.update(eportfolio_category_params)
          format.html { redirect_to eportfolio_category_url(@portfolio, @category) }
          format.json { render json: @category }
        else
          format.json { render json: @category.errors }
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
      if params[:id]
        @category = @portfolio.eportfolio_categories.find(params[:id])
      elsif params[:category_name]
        @category = @portfolio.eportfolio_categories.where(slug: params[:category_name]).first!
      end
      @page = @category.eportfolio_entries.first
      if @portfolio.grants_right?(@current_user, session, :update)
        @page ||= @portfolio.eportfolio_entries.create(
          eportfolio_category: @category,
          allow_comments: true,
          show_comments: true,
          name: t(:default_name, "New Page")
        )
      end
      raise ActiveRecord::RecordNotFound unless @page

      eportfolio_page_attributes

      render "eportfolios/show", stream: can_stream_template?
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = t("errors.missing_page", "Couldn't find that page")
    redirect_to eportfolio_url(@portfolio.id)
  end

  def destroy
    if authorized_action(@portfolio, @current_user, :update)
      @category = @portfolio.eportfolio_categories.find(params[:id])
      respond_to do |format|
        if @category.destroy
          format.html { redirect_to eportfolio_url(@portfolio) }
          format.json { render json: @category }
        end
      end
    end
  end

  protected

  def eportfolio_category_params
    params.require(:eportfolio_category).permit(:name)
  end

  def get_eportfolio
    @portfolio = Eportfolio.active.find(params[:eportfolio_id])
  end
end
