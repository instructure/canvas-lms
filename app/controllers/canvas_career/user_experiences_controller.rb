# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module CanvasCareer
  class UserExperiencesController < ApplicationController
    before_action :require_feature_flag

    def create
      experience = UserExperience.where(user: @current_user, root_account: @domain_root_account).first_or_initialize
      if experience.deleted?
        experience.undestroy
      elsif experience.new_record?
        experience.save!
      end

      render json: { workflow_state: experience.workflow_state }, status: :created
    end

    def destroy
      experience = UserExperience.active.find_by(user: @current_user, root_account: @domain_root_account)
      return render json: { error: "user experience not found" }, status: :not_found unless experience

      experience.destroy
      render json: { workflow_state: experience.workflow_state }
    end

    private

    def require_feature_flag
      not_found unless CanvasCareer::ExperienceResolver.career_affiliated_institution?(@domain_root_account)
    end
  end
end
