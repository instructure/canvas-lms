#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Outcomes
#
# API for accessing learning outcome information.
class OutcomesApiController < ApplicationController
  include Api::V1::Outcome

  before_filter :require_user
  before_filter :get_outcome

  # @API Retrieve an outcome's details.
  def show
    if authorized_action(@outcome, @current_user, :read)
      render :json => outcome_json(@outcome, @current_user, session)
    end
  end

  # @API Update an outcome.
  def update
    if authorized_action(@outcome, @current_user, :update)
      @outcome.update_attributes(params.slice(:title, :description))
      if params[:mastery_points] || params[:ratings]
        criterion = @outcome.data && @outcome.data[:rubric_criterion]
        criterion ||= {}
        if params[:mastery_points]
          criterion[:mastery_points] = params[:mastery_points]
        else
          criterion.delete(:mastery_points)
        end
        if params[:ratings]
          criterion[:ratings] = params[:ratings]
        end
        @outcome.rubric_criterion = criterion
      end
      if @outcome.save
        render :json => outcome_json(@outcome, @current_user, session)
      else
        render :json => @outcome.errors, :status => :bad_request
      end
    end
  end

  protected

  def get_outcome
    @outcome = LearningOutcome.active.find(params[:id])
  end
end
