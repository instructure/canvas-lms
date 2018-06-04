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

class OutcomeProficiencyApiController < ApplicationController
  include Api::V1::OutcomeProficiency
  before_action :get_context

  def create
    if authorized_action(@context, @current_user, :manage_outcomes)
      if @account.outcome_proficiency
        update_ratings(@account.outcome_proficiency)
      else
        update_ratings(OutcomeProficiency.new, @account)
      end
      render json: outcome_proficiency_json(@account.outcome_proficiency, @current_user, session)
    end
  end

  def show
    proficiency = @account.resolved_outcome_proficiency or raise ActiveRecord::RecordNotFound
    render json: outcome_proficiency_json(proficiency, @current_user, session)
  rescue ActiveRecord::RecordNotFound => e
    render json: { message: e.message }, status: :not_found
  end

  private

  def update_ratings(proficiency, account = nil)
    # update existing ratings & create any new ratings
    proficiency_params['ratings'].each_with_index do |val, idx|
      if idx <= proficiency.outcome_proficiency_ratings.count - 1
        proficiency.outcome_proficiency_ratings[idx].assign_attributes(val.to_hash.symbolize_keys)
      else
        proficiency.outcome_proficiency_ratings.build(val)
      end
    end
    # delete unused ratings
    proficiency.outcome_proficiency_ratings[proficiency_params['ratings'].length..-1].each(&:mark_for_destruction)
    proficiency.account = account if account
    proficiency.save!
    proficiency
  end

  def proficiency_params
    params.permit(ratings: [:description, :points, :mastery, :color])
  end
end
