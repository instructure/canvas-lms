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

class RubricAssessmentsController < ApplicationController
  before_action :require_context
  before_action :require_user

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
    # this param matters (find_asset_for_assessment)
    user_id = @assessment.present? ? @assessment.user_id : resolve_user_id
    raise ActiveRecord::RecordNotFound if user_id.blank?

    # Funky flow to avoid a double-render, re-work it if you like
    if @assessment && !authorized_action(@assessment, @current_user, :update)
      return
    else
      opts = {}
      if value_to_boolean(params[:provisional])
        opts[:provisional_grader] = @current_user
        opts[:final] = true if mark_provisional_grade_as_final?
      end

      @asset, @user = @association_object.find_asset_for_assessment(@association, user_id, opts)
      return render_unauthorized_action unless @association.user_can_assess_for?(assessor: @current_user, assessee: @user)

      @assessment = @association.assess(:assessor => @current_user, :user => @user, :artifact => @asset, :assessment => params[:rubric_assessment],
        :graded_anonymously => value_to_boolean(params[:graded_anonymously]))
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

  private
  def resolve_user_id
    user_id = params[:rubric_assessment][:user_id]
    if user_id
      user_id =~ Api::ID_REGEX ? user_id.to_i : nil
    elsif params[:rubric_assessment][:anonymous_id]
      Submission.find_by!(
        anonymous_id: params[:rubric_assessment][:anonymous_id],
        assignment_id: @association.association_id
      ).user_id
    end
  end

  def mark_provisional_grade_as_final?
    value_to_boolean(params[:final]) && @association_object.permits_moderation?(@current_user)
  end
end
