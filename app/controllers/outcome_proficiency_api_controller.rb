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

# @API Proficiency Ratings
#
# API for customizing proficiency ratings
#
# @model ProficiencyRating
#     {
#       "id": "ProficiencyRating",
#       "description": "",
#       "properties": {
#         "description": {
#           "description": "The description of the rating",
#           "example": "Exceeds Mastery",
#           "type": "string"
#         },
#         "points": {
#           "description": "A non-negative number of points for the rating",
#           "example": 4,
#           "type": "number"
#         },
#         "mastery": {
#           "description": "Indicates the rating where mastery is first achieved",
#           "example": false,
#           "type": "boolean"
#         },
#         "color": {
#           "description": "The hex color code of the rating",
#           "example": "127A1B",
#           "type": "string"
#         }
#       }
#     }
#
# @model Proficiency
#     {
#       "id": "Proficiency",
#       "description": "",
#       "properties": {
#         "ratings": {
#           "description": "An array of proficiency ratings. See the ProficiencyRating specification above.",
#           "example": [],
#           "type": "array"
#         }
#       }
#     }
#
class OutcomeProficiencyApiController < ApplicationController
  include Api::V1::OutcomeProficiency
  before_action :get_context

  # @API Create/update proficiency ratings
  #
  # Create or update account-level proficiency ratings. These ratings will apply to all
  # sub-accounts, unless they have their own account-level proficiency ratings defined.
  #
  #
  # @argument ratings[][description] [String]
  #   The description of the rating level.
  #
  # @argument ratings[][points] [Integer]
  #   The non-negative number of points of the rating level. Points across ratings should be strictly decreasing in value.
  #
  # @argument ratings[][mastery] [Integer]
  #   Indicates the rating level where mastery is first achieved. Only one rating in a proficiency should be marked for mastery.
  #
  # @argument ratings[][color] [Integer]
  #   The color associated with the rating level. Should be a hex color code like '00FFFF'.
  #
  # @returns Proficiency
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/outcome_proficiency' \
  #        -X POST \
  #        -F 'ratings[][description]=Exceeds Mastery' \
  #        -F 'ratings[][points]=4' \
  #        -F 'ratings[][color]=127A1B' \
  #        -F 'ratings[][mastery]=false' \
  #        -F 'ratings[][description]=Mastery' \
  #        -F 'ratings[][points]=3' \
  #        -F 'ratings[][color]=00AC18' \
  #        -F 'ratings[][mastery]=true' \
  #        -F 'ratings[][description]=Near Mastery' \
  #        -F 'ratings[][points]=2' \
  #        -F 'ratings[][color]=FAB901' \
  #        -F 'ratings[][mastery]=false' \
  #        -F 'ratings[][description]=Below Mastery' \
  #        -F 'ratings[][points]=1' \
  #        -F 'ratings[][color]=FD5D10' \
  #        -F 'ratings[][mastery]=false' \
  #        -F 'ratings[][description]=Well Below Mastery' \
  #        -F 'ratings[][points]=0' \
  #        -F 'ratings[][color]=EE0612' \
  #        -F 'ratings[][mastery]=false' \
  #        -H "Authorization: Bearer <token>"
  #
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

  # @API Get proficiency ratings
  #
  # Get account-level proficiency ratings. If not defined for this account,
  # it will return proficiency ratings for the nearest super-account with ratings defined.
  # Will return 404 if none found.
  #
  #   Examples:
  #     curl https://<canvas>/api/v1/accounts/<account_id>/outcome_proficiency \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns Proficiency
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
