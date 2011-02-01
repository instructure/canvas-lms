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

class TermsController < ApplicationController
  before_filter :require_context, :require_account_management
  def index
    @context.default_enrollment_term
    @terms = @context.enrollment_terms.active.sort_by{|t| t.start_at || t.created_at }.reverse
  end
  
  def create
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = @context.enrollment_terms.active.build(params[:enrollment_term])
    if @term.save
      @term.set_overrides(@context, overrides)
      render :json => @term.to_json(:include => :enrollment_dates_overrides)
    else
      render :json => @term.errors.to_json, :status => :bad_request
    end
  end
  
  def update
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = @context.enrollment_terms.active.find(params[:id])
    if @term.update_attributes(params[:enrollment_term])
      @term.set_overrides(@context, overrides)
      render :json => @term.to_json(:include => :enrollment_dates_overrides)
    else
      render :json => @term.errors.to_json, :status => :bad_request
    end
  end
  
  def destroy
    @term = @context.enrollment_terms.find(params[:id])
    @term.destroy
    render :json => @term.to_json
  end

  protected

  def require_account_management
    if @context.root_account != nil || !@context.is_a?(Account)
      redirect_to named_context_url(@context, :context_url)
      return false
    else
      return false unless authorized_action(@context, @current_user, :manage)
    end
  end
end
