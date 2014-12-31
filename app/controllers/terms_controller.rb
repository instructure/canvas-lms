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

# @API Enrollment Terms
class TermsController < ApplicationController
  before_filter :require_context, :require_root_account_management
  include Api::V1::EnrollmentTerm

  def index
    @root_account = @context.root_account
    @context.default_enrollment_term
    @terms = @context.enrollment_terms.active.includes(:enrollment_dates_overrides).order("COALESCE(start_at, created_at) DESC").to_a
  end
  
  # @API Create enrollment term
  #
  # Create a new enrollment term for the specified account.
  #
  # @argument enrollment_term[name] [String]
  #   The name of the term.
  #
  # @argument enrollment_term[start_at] [Timestamp]
  #   The day/time the term starts.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[end_at] [Timestamp]
  #   The day/time the term ends.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[sis_term_id] [String]
  #   The unique SIS identifier for the term.
  #
  # @returns EnrollmentTerm
  #
  def create
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = @context.enrollment_terms.active.build(params[:enrollment_term])
    sis_id = params[:enrollment_term].delete(:sis_source_id) || params[:enrollment_term].delete(:sis_term_id)
    handle_sis_id_param(sis_id)
    if @term.save
      @term.set_overrides(@context, overrides)
      if api_request?
        render :json => enrollment_term_json(@term, @current_user, session)
      else
        render :json => @term.as_json(:include => :enrollment_dates_overrides)
      end
    else
      render :json => @term.errors, :status => :bad_request
    end
  end
  
  # @API Update enrollment term
  #
  # Update an existing enrollment term for the specified account.
  #
  # @argument enrollment_term[name] [String]
  #   The name of the term.
  #
  # @argument enrollment_term[start_at] [Timestamp]
  #   The day/time the term starts.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[end_at] [Timestamp]
  #   The day/time the term ends.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[sis_term_id] [String]
  #   The unique SIS identifier for the term.
  #
  # @returns EnrollmentTerm
  #
  def update
    overrides = params[:enrollment_term].delete(:overrides) rescue nil
    @term = api_find(@context.enrollment_terms.active, params[:id])
    sis_id = params[:enrollment_term].delete(:sis_source_id) || params[:enrollment_term].delete(:sis_term_id)
    handle_sis_id_param(sis_id)
    if @term.update_attributes(params[:enrollment_term])
      @term.set_overrides(@context, overrides)
      if api_request?
        render :json => enrollment_term_json(@term, @current_user, session)
      else
        render :json => @term.as_json(:include => :enrollment_dates_overrides)
      end
    else
      render :json => @term.errors, :status => :bad_request
    end
  end
  
  # @API Delete enrollment term
  #
  # Delete the specified enrollment term.
  #
  # @returns EnrollmentTerm
  #
  def destroy
    @term = api_find(@context.enrollment_terms, params[:id])
    @term.destroy
    if api_request?
      render :json => enrollment_term_json(@term, @current_user, session)
    else
      render :json => @term
    end
  end

  private
  def handle_sis_id_param(sis_id)
    if !sis_id.nil? &&
        sis_id != @account.sis_source_id &&
        @context.root_account.grants_right?(@current_user, session, :manage_sis)
      @term.sis_source_id = sis_id.presence
    end
  end
end
