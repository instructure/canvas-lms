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

class RubricAssessmentsController < ApplicationController
  before_filter :require_context
  
  def index
    @association = @context.rubric_associations.find(params[:rubric_association_id]) #Rubric.find(params[:rubric_id])
    @assessments = @association.rubric_assessments
    if authorized_action(@context, @current_user, :read)
      @headers = false
      render :action => "index"
    end
  end
  
  def show
    @association = @context.rubric_associations.find(params[:rubric_association_id]) #Rubric.find(params[:rubric_id])
    @assessment = @association.rubric_assessments.find(params[:id]) rescue nil
    @assessment_request = @association.assessment_requests.find_by_uuid(params[:id])
    if @assessment_request && @association.purpose == "grading" && @association.association_type == 'Assignment'
      redirect_to named_context_url(@context, :context_assignment_submission_url, @association.association_id, @assessment_request.user_id)
      return
    end
    if @assessment_request || authorized_action(@context, @current_user, :read)    
      unless @assessment
        raise "Assessment Request required" unless @assessment_request
        @assessment = @assessment_request.rubric_assessment
        @user = @assessment_request.asset.user rescue nil
        @assessment ||= @association.assess(:assessor => (@current_user || @assessment_request.user), :user => @user, :artifact => @assessment_request.asset, :assessment => {:assessment_type => 'invited_assessment'})
        session[:rubric_assessment_ids] = ((session[:rubric_assessment_ids] || []) + [@assessment.id]).uniq
        @assessment_request.attributes = {:rubric_assessment => @assessment, :user => @assessment.assessor}
        @assessment_request.complete
        @assessing = true
      end
      @assessments = [@assessment]
      if @assessment.artifact && @assessment.artifact.is_a?(Submission)
        redirect_to named_context_url(@assessment.artifact.context, :context_assignment_submission_url, @assessment.artifact.assignment_id, @assessment.artifact.user_id)
      else
        @headers = false
        render :action => "index"
      end
    end
  end
  
  def create
    update
  end

  def remind
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @rubric = @association.rubric
    @request = @association.assessment_requests.find(params[:assessment_request_id])
    if authorized_action(@association, @current_user, :manage)
      @request.send_reminder!
      render :json => @request
    end
  end
  
  def update
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @assessment = @association.rubric_assessments.find_by_id(params[:id])
    @association_object = @association.association

    # only check if there's no @assessment object, since that's the only time
    # this param matters (assessing_user_id and arg find_asset_for_assessment)
    user_id = params[:rubric_assessment][:user_id]
    if !@assessment && user_id !~ /\A\d+\Z/
      raise ActiveRecord::RecordNotFound
    end

    # Funky flow to avoid a double-render, re-work it if you like
    @association.assessing_user_id = user_id
    if @assessment && !authorized_action(@assessment, @current_user, :update)
      return
    elsif @assessment || authorized_action(@association, @current_user, :assess)
      @asset, @user = @association_object.find_asset_for_assessment(@association, @assessment ? @assessment.user_id : user_id)
      @assessment = @association.assess(:assessor => @current_user, :user => @user, :artifact => @asset, :assessment => params[:rubric_assessment])
      @asset.reload
      artifact_includes = @asset.is_a?(Submission) ? {
        :artifact => Submission.json_serialization_full_parameters,
        :rubric_association => {}
      } : [:artifact, :rubric_association]
      render :json => @assessment.as_json(:methods => [:ratings, :assessor_name, :related_group_submissions_and_assessments], :include => artifact_includes, :include_root => false)
    end
  end
  
  def destroy
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @rubric = @association.rubric
    @assessment = @rubric.rubric_assessments.find(params[:id])
    if authorized_action(@assessment, @current_user, :delete)
      if @assessment.destroy
        render :json => @assessment
      else
        render :json => @assessment.errors, :status => :bad_request
      end
    end
  end
end
