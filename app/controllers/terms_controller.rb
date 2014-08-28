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
  before_filter :require_context, :require_root_account_management
  def index
    @root_account = @context.root_account
    @context.default_enrollment_term
    @terms = @context.enrollment_terms.active.includes(:enrollment_dates_overrides).order("COALESCE(start_at, created_at) DESC").to_a
  end
  
  def create
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = @context.enrollment_terms.active.build(params[:enrollment_term])
    if @term.save
      @term.set_overrides(@context, overrides)
      render :json => @term.as_json(:include => :enrollment_dates_overrides)
    else
      render :json => @term.errors, :status => :bad_request
    end
  end
  
  def update
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = @context.enrollment_terms.active.find(params[:id])
    root_account = @context.root_account
    if sis_id = params[:enrollment_term].delete(:sis_source_id)
      if sis_id != @account.sis_source_id && root_account.grants_right?(@current_user, session, :manage_sis)
        if sis_id == ''
          @term.sis_source_id = nil
        else
          @term.sis_source_id = sis_id
        end
      end
    end
    if @term.update_attributes(params[:enrollment_term])
      @term.set_overrides(@context, overrides)
      render :json => @term.as_json(:include => :enrollment_dates_overrides)
    else
      render :json => @term.errors, :status => :bad_request
    end
  end
  
  def destroy
    @term = @context.enrollment_terms.find(params[:id])
    @term.destroy
    render :json => @term
  end
end
