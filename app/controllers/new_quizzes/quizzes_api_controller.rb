# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module NewQuizzes
  # @API New Quizzes
  # API for accessing and building New Quizzes.
  #
  # **Note: This API is under active development and the endpoints listed here will
  # not function until the API is enabled.**
  class QuizzesApiController < ApplicationController
    before_action :require_feature_flag

    # @API Get a new quiz
    # Get details about a single new quiz
    def show
      render json: {}
    end

    private

    def require_feature_flag
      not_found unless Account.site_admin.feature_enabled?(:new_quiz_public_api)
    end
  end
end
