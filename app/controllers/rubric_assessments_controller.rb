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
    @assessment = @association.rubric_assessments.where(id: params[:id]).first
    @association_object = @association.association_object

    # only check if there's no @assessment object, since that's the only time
    # this param matters (assessing_user_id and arg find_asset_for_assessment)
    user_id = params[:rubric_assessment][:user_id]
    if !@assessment && user_id !~ Api::ID_REGEX
      raise ActiveRecord::RecordNotFound
    end

    # Funky flow to avoid a double-render, re-work it if you like
    @association.assessing_user_id = user_id
    if @assessment && !authorized_action(@assessment, @current_user, :update)
      return
    elsif @assessment || authorized_action(@association, @current_user, :assess)
      @asset, @user = @association_object.find_asset_for_assessment(@association, @assessment ? @assessment.user_id : user_id,
        :provisional_grader => value_to_boolean(params[:provisional]) && @current_user)
      @assessment = @association.assess(:assessor => @current_user, :user => @user, :artifact => @asset, :assessment => params[:rubric_assessment])
      @asset.reload
      artifact_includes =
        case @asset
        when Submission
          { :artifact => Submission.json_serialization_full_parameters, :rubric_association => {} }
        when ModeratedGrading::ProvisionalGrade
          { :rubric_association => {} }
        else
          [:artifact, :rubric_association]
        end
      json = @assessment.as_json(:methods => [:ratings, :assessor_name, :related_group_submissions_and_assessments],
        :include => artifact_includes, :include_root => false)
      
      if @asset.is_a?(ModeratedGrading::ProvisionalGrade)
        json[:artifact] = @asset.submission.
          as_json(Submission.json_serialization_full_parameters(:include_root => false)).
          merge(@asset.grade_attributes)
      end

      render :json => json
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
