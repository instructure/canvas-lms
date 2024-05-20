# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class JobsController < ApplicationController
  before_action :require_manage_jobs, only: [:batch_update]
  before_action :require_view_jobs, only: [:index, :show]
  before_action :set_site_admin_context, :set_navigation, only: [:index]
  POPULAR_TAG_COUNTS = 12
  LIMIT = 100

  def require_manage_jobs
    require_site_admin_with_permission(:manage_jobs)
  end

  def require_view_jobs
    require_site_admin_with_permission(:view_jobs)
  end

  def index
    @flavor = params[:flavor] || "current"

    GuardRail.activate(:secondary) do
      respond_to do |format|
        format.html do
          @running_jobs_refresh_seconds = 2.seconds
          @job_tags_refresh_seconds = 10.seconds
        end

        format.json do
          case params[:only]
          when "running"
            render json: { running: Delayed::Job.running_jobs.map { |j| j.as_json(include_root: false, except: [:handler, :last_error]) } }
          when "tags"
            render json: { tags: Delayed::Job.tag_counts(@flavor, POPULAR_TAG_COUNTS) }
          when "jobs"
            jobs = jobs(@flavor, params[:limit] || LIMIT, params[:offset].to_i)
            jobs[:jobs].map! { |j| j.as_json(include_root: false, except: [:handler, :last_error]) }
            render json: jobs
          end
        end
      end
    end
  end

  def show
    job = if params[:flavor] == "failed"
            Delayed::Job::Failed.find(params[:id])
          else
            Delayed::Job.find(params[:id])
          end
    render json: job.as_json(include_root: false)
  end

  def batch_update
    opts = {}

    if params[:job_ids].present?
      opts[:ids] = params[:job_ids]
      opts[:flavor] = params[:flavor] if params[:flavor] == "failed"
    elsif params[:flavor].present?
      opts[:flavor] = params[:flavor]
      opts[:query] = params[:q]
    end

    count = Delayed::Job.bulk_update(params[:update_action], opts)

    render json: { status: "OK", count: }
  end

  protected

  def jobs(flavor, limit, offset)
    case flavor
    when "id"
      jobs = []
      jobs << Delayed::Job.find_by(id: params[:q]) if params[:q].present?
      jobs = jobs.compact
      jobs_count = jobs.size
    when "future", "current", "failed"
      jobs = Delayed::Job.list_jobs(flavor, limit, offset)
      jobs_count = Delayed::Job.jobs_count(flavor)
    else
      query = params[:q].presence
      if query
        jobs = Delayed::Job.list_jobs(flavor, limit, offset, query)
        jobs_count = Delayed::Job.jobs_count(flavor, query)
      else
        jobs = []
        jobs_count = 0
      end
    end

    { jobs:, total: jobs_count }
  end

  def set_navigation
    set_active_tab "jobs"
    add_crumb t("#crumbs.jobs", "Jobs")
  end
end
