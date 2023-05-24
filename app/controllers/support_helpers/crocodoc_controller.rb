# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module SupportHelpers
  class CrocodocController < ApplicationController
    include SupportHelpers::ControllerHelpers

    before_action :require_site_admin

    protect_from_forgery with: :exception

    def shard
      run_fixer(SupportHelpers::Crocodoc::ShardFixer)
    end

    def submission
      if params[:assignment_id] && params[:user_id]
        run_fixer(SupportHelpers::Crocodoc::SubmissionFixer,
                  params[:assignment_id].to_i,
                  params[:user_id].to_i)
      else
        render plain: "Missing either assignment and/or user id parameters", status: :bad_request
      end
    end
  end
end
