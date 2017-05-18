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

# @API Enrollment Terms
class TermsController < ApplicationController
  before_action :require_context, :require_root_account_management
  include Api::V1::EnrollmentTerm

  def index
    @root_account = @context.root_account
    @context.default_enrollment_term
    @terms = @context.enrollment_terms.active.
      preload(:enrollment_dates_overrides).
      order("COALESCE(start_at, created_at) DESC").to_a
    @course_counts_by_term = EnrollmentTerm.course_counts(@terms)
  end

  # @API Create enrollment term
  #
  # Create a new enrollment term for the specified account.
  #
  # @argument enrollment_term[name] [String]
  #   The name of the term.
  #
  # @argument enrollment_term[start_at] [DateTime]
  #   The day/time the term starts.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[end_at] [DateTime]
  #   The day/time the term ends.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[sis_term_id] [String]
  #   The unique SIS identifier for the term.
  #
  # @argument enrollment_term[overrides][enrollment_type][start_at] [DateTime]
  #   The day/time the term starts, overridden for the given enrollment type.
  #   *enrollment_type* can be one of StudentEnrollment, TeacherEnrollment, TaEnrollment, or DesignerEnrollment
  #
  # @argument enrollment_term[overrides][enrollment_type][end_at] [DateTime]
  #   The day/time the term ends, overridden for the given enrollment type.
  #   *enrollment_type* can be one of StudentEnrollment, TeacherEnrollment, TaEnrollment, or DesignerEnrollment
  #
  # @returns EnrollmentTerm
  #
  def create
    @term = @context.enrollment_terms.active.build
    save_and_render_response
  end

  # @API Update enrollment term
  #
  # Update an existing enrollment term for the specified account.
  #
  # @argument enrollment_term[name] [String]
  #   The name of the term.
  #
  # @argument enrollment_term[start_at] [DateTime]
  #   The day/time the term starts.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[end_at] [DateTime]
  #   The day/time the term ends.
  #   Accepts times in ISO 8601 format, e.g. 2015-01-10T18:48:00Z.
  #
  # @argument enrollment_term[sis_term_id] [String]
  #   The unique SIS identifier for the term.
  #
  # @argument enrollment_term[overrides][enrollment_type][start_at] [DateTime]
  #   The day/time the term starts, overridden for the given enrollment type.
  #   *enrollment_type* can be one of StudentEnrollment, TeacherEnrollment, TaEnrollment, or DesignerEnrollment
  #
  # @argument enrollment_term[overrides][enrollment_type][end_at] [DateTime]
  #   The day/time the term ends, overridden for the given enrollment type.
  #   *enrollment_type* can be one of StudentEnrollment, TeacherEnrollment, TaEnrollment, or DesignerEnrollment
  #
  # @returns EnrollmentTerm
  #
  def update
    @term = api_find(@context.enrollment_terms.active, params[:id])
    save_and_render_response
  end

  # @API Delete enrollment term
  #
  # Delete the specified enrollment term.
  #
  # @returns EnrollmentTerm
  #
  def destroy
    @term = api_find(@context.enrollment_terms, params[:id])
    @term.workflow_state = 'deleted'

    if @term.save
      if api_request?
        render :json => enrollment_term_json(@term, @current_user, session)
      else
        render :json => @term
      end
    else
      render :json => @term.errors, :status => :bad_request
    end
  end

  private
  def save_and_render_response
    params.require(:enrollment_term)
    overrides = params[:enrollment_term][:overrides]
    if overrides.present?
      unless (overrides.keys.map(&:classify) - %w(StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment)).empty?
        return render :json => {:message => 'Invalid enrollment type in overrides'}, :status => :bad_request
      end
    end
    sis_id = params[:enrollment_term][:sis_source_id] || params[:enrollment_term][:sis_term_id]
    if sis_id && !(sis_id.is_a?(String) || sis_id.is_a?(Numeric))
      return render :json => {:message => "Invalid SIS ID"}, :status => :bad_request
    end
    handle_sis_id_param(sis_id)

    term_params = params.require(:enrollment_term).permit(:name, :start_at, :end_at)
    if validate_dates(@term, term_params, overrides) && @term.update_attributes(term_params)
      @term.set_overrides(@context, overrides)
      render :json => serialized_term
    else
      render :json => @term.errors, :status => :bad_request
    end
  end

  def validate_dates(term, term_params, overrides)
    hashes = [term_params]
    hashes += overrides.values if overrides
    invalid_dates = hashes.any? do |hash|
      start_at = DateTime.parse(hash[:start_at]) rescue nil
      end_at = DateTime.parse(hash[:end_at]) rescue nil
      start_at && end_at && end_at < start_at
    end
    term.errors.add(:base, t("End dates cannot be before start dates")) if invalid_dates
    !invalid_dates
  end

  def handle_sis_id_param(sis_id)
    if !sis_id.nil? &&
        sis_id != @account.sis_source_id &&
        @context.root_account.grants_right?(@current_user, session, :manage_sis)
      @term.sis_source_id = sis_id.presence
    end
  end

  def serialized_term
    if api_request?
      enrollment_term_json(@term, @current_user, session, nil, ['overrides'])
    else
      @term.as_json(:include => :enrollment_dates_overrides)
    end
  end
end
