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

class PageCommentsController < ApplicationController
  def create
    @portfolio = Eportfolio.active.find(params[:eportfolio_id])
    @page = @portfolio.eportfolio_entries.find(params[:entry_id])
    if authorized_action(@page, @current_user, :comment)
      @comment = @page.page_comments.build(params.require(:page_comment).permit(:message))
      @comment.user = @current_user
      url = if @page.eportfolio_category.slug.blank?
              eportfolio_url(@portfolio)
            elsif @page.slug.blank?
              eportfolio_named_category_url(@portfolio, @page.eportfolio_category.slug)
            else
              eportfolio_named_category_entry_url(@portfolio, @page.eportfolio_category.slug, @page.slug)
            end
      respond_to do |format|
        if @comment.save
          format.html { redirect_to url }
          format.json { render :json => @comment }
        else
          flash[:error] = t('errors.create_failed', "Comment creation failed")
          format.html { redirect_to url }
          format.json { render :json => @comment.errors, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @portfolio = Eportfolio.active.find(params[:eportfolio_id])
    @page = @portfolio.eportfolio_entries.find(params[:entry_id])
    @comment = @page.page_comments.find(params[:id])
    if authorized_action(@portfolio, @current_user, :update)
      @comment.destroy
      render :json => @comment
    end
  end
end
