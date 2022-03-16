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
  before_action :require_view_jobs
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

  # @{not an}API List queued jobs grouped by tag
  #
  # @argument order [String,"count"|"tag"|"min_run_at"]
  #   Sort column. Default is "min_run_at"
  def queued_tags
    scope = Delayed::Job.where("run_at <= now() AND (locked_by IS NULL OR locked_by = ?)", ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY)
                        .select("count(*) AS count, tag, MIN(run_at) AS min_run_at")
                        .group(:tag)
                        .order(tags_order_clause("min_run_at ASC"))
    tag_info = Api.paginate(scope, self, api_v1_jobs_tags_queued_url)
    render json: tag_info.map { |info| { count: info.count, tag: info.tag, min_run_at: info.min_run_at } }
  end

  # @{not an}API List running jobs grouped by tag
  #
  # @argument order [String,"count"|"tag"|"first_locked_at"]
  #   Sort column. Default is "first_locked_at"
  def running_tags
    scope = Delayed::Job.running
                        .select("count(*) AS count, tag, MIN(locked_at) AS first_locked_at")
                        .group(:tag)
                        .order(tags_order_clause("first_locked_at ASC"))
    tag_info = Api.paginate(scope, self, api_v1_jobs_tags_running_url)
    render json: tag_info.map { |info| { count: info.count, tag: info.tag, first_locked_at: info.first_locked_at } }
  end

  # @{not an}API List future jobs grouped by tag
  #
  # @argument order [String,"count"|"tag"|"next_run_at"]
  #   Sort column. Default is "next_run_at"
  def future_tags
    scope = Delayed::Job.future
                        .select("count(*) AS count, tag, MIN(run_at) AS next_run_at")
                        .group(:tag)
                        .order(tags_order_clause("next_run_at ASC"))
    tag_info = Api.paginate(scope, self, api_v1_jobs_tags_future_url)
    render json: tag_info.map { |info| { count: info.count, tag: info.tag, next_run_at: info.next_run_at } }
  end

  # @{not an}API List failed jobs grouped by tag
  #
  # @argument order [String,"count"|"tag"|"last_failed_at"]
  #   Sort column. Default is "last_failed_at"
  def failed_tags
    scope = Delayed::Job::Failed
            .select("count(*) AS count, tag, MAX(failed_at) AS last_failed_at")
            .group(:tag)
            .order(tags_order_clause("last_failed_at DESC"))
    tag_info = Api.paginate(scope, self, api_v1_jobs_tags_failed_url)
    render json: tag_info.map { |info| { count: info.count, tag: info.tag, last_failed_at: info.last_failed_at } }
  end

  protected

  def tags_order_clause(default_order)
    case params[:order]
    when "tag"
      "tag ASC"
    when "count"
      "count DESC"
    else
      default_order
    end
  end

  def set_navigation
    set_active_tab "jobs_v2"
    add_crumb t("#crumbs.jobs_v2", "Jobs v2")
  end
end
