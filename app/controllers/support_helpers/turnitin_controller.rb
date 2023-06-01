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
  class TurnitinController < ApplicationController
    include SupportHelpers::ControllerHelpers

    before_action :require_site_admin

    protect_from_forgery with: :exception

    def md5
      run_fixer(SupportHelpers::Tii::MD5Fixer)
    end

    def error2305
      run_fixer(SupportHelpers::Tii::Error2305Fixer)
    end

    def shard
      run_fixer(SupportHelpers::Tii::ShardFixer)
    end

    def assignment
      if params[:id]
        run_fixer(SupportHelpers::Tii::AssignmentFixer, params[:id].to_i)
      else
        render plain: "Missing assignment `id` parameter", status: :bad_request
      end
    end

    def pending
      run_fixer(SupportHelpers::Tii::StuckInPendingFixer)
    end

    def expired
      run_fixer(SupportHelpers::Tii::ExpiredAccountFixer)
    end

    def lti_attachment
      param_keys = %w[submission_id attachment_id]
      if params.keys.intersect?(param_keys)
        ids = param_keys.map do |key|
          error = { text: "Missing `#{key}` parameter", status: 400 }
          return render error unless params[key]

          params[key].to_i
        end
        run_fixer(SupportHelpers::Tii::LtiAttachmentFixer, *ids)
      else
        error = { text: "Missing attachment_id and submission_id parameters", status: 400 }
        render error and return
      end
    end
  end
end
