#
# Copyright (C) 2018 - present Instructure, Inc.
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

class SubmissionsBaseController < ApplicationController
  include Api::V1::Rubric

  def show
    @visible_rubric_assessments = @submission.visible_rubric_assessments_for(@current_user)
    @assessment_request = @submission.assessment_requests.where(assessor_id: @current_user).first

    if @submission&.user_id == @current_user.id
      @submission&.mark_read(@current_user)
    end

    respond_to do |format|
      @submission.limit_comments(@current_user, session)
      format.html do
        rubric_association = @assignment&.rubric_association
        rubric_association_json = rubric_association&.as_json
        rubric = rubric_association&.rubric
        js_env({
          nonScoringRubrics: @domain_root_account.feature_enabled?(:non_scoring_rubrics),
          rubric: rubric ? rubric_json(rubric, @current_user, session, style: 'full') : nil,
          rubricAssociation: rubric_association_json ? rubric_association_json['rubric_association'] : nil
        })
         render 'submissions/show'
      end
      format.json do
        @submission.limit_comments(@current_user, session)
        render :json => @submission.as_json(
          Submission.json_serialization_full_parameters(
            except: %i(quiz_submission submission_history)
          ).merge(permissions: {
            user: @current_user,
            session: session,
            include_permissions: false
          })
        )
      end
    end
  end
end
