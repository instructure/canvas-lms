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
  module ControllerHelpers

    private

    def require_site_admin
      require_site_admin_with_permission(:update)
    end

    def run_fixer(fixer_klass, *args)
      params[:after_time] &&= Time.zone.parse(params[:after_time])
      fixer = fixer_klass.new(@current_user.email, params[:after_time], *args)
      fixer.delay_if_production.monitor_and_fix

      render plain: "Enqueued #{fixer.fixer_name}..."
    end
  end
end
