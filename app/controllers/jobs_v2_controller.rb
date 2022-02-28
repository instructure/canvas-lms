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

class JobsV2Controller < ApplicationController
  before_action :require_view_jobs, only: [:index]
  before_action :set_site_admin_context, :set_navigation, only: [:index]

  def require_view_jobs
    require_site_admin_with_permission(:view_jobs)
  end

  def index
    respond_to do |format|
      format.html do
        @page_title = t("Jobs Control Panel v2")

        js_bundle :jobs_v2

        render html: "", layout: true
      end
    end
  end

  protected

  def set_navigation
    set_active_tab "jobs_v2"
    add_crumb t("#crumbs.jobs_v2", "Jobs v2")
  end
end
