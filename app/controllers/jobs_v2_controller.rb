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
  BUCKETS = %w[queued running future failed].freeze
  SEARCH_LIMIT = 100

  before_action :require_view_jobs
  before_action :require_bucket, only: %i[grouped_info list search]
  before_action :require_group, only: %i[grouped_info search]
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

  # @{not an}API List jobs grouped by tag, strand, or singleton
  #
  # @argument group [String,"tag"|"strand"|"singleton"]
  #   How to group jobs. Default is "tag".
  #
  # @argument bucket [Required,String,"queued"|"running"|"future"|"failed"]
  #   Which jobs to consider. the +info+ column returned will vary depending on which bucket
  #   you're looking at:
  #   - queued: maximum time a job with this tag/strand has been queued, in seconds
  #   - running: maximum time a job with this tag/strand has been running, in seconds
  #   - future: timestamp for the next scheduled run of a job with this tag/strand
  #   - failed: timestamp when the last failure of a job with this tag/strand occurred
  #
  # @argument order [String,"count"|"tag"|"strand"|"group"|"info"]
  #   Sort column. Default is "info". See the +bucket+ argument for a description of this field.
  #   If set to "group", order by the +group+ argument (e.g. "tag" or "strand").
  def grouped_info
    scope = jobs_scope
            .select("count(*) AS count, #{@group}, #{grouped_info_select}")
            .where.not(@group => nil)
            .group(@group)
            .order(grouped_order_clause(@group))

    tag_info = Api.paginate(scope, self, api_v1_jobs_grouped_info_url)
    now = Delayed::Job.db_time_now
    render json: tag_info.map { |row| grouped_info_json(row, @group, base_time: now) }
  end

  # @{not an}API List jobs
  #
  # @argument bucket [Required,String,"queued"|"running"|"future"|"failed"]
  #   Which jobs to consider. The +info+ column will vary depending on which
  #   bucket is chosen:
  #   - queued: length of time the job has been waiting to run, in seconds
  #   - running: length of time the job has been running, in seconds
  #   - future: scheduled run time for the job
  #   - failed: the timestamp when the job failed
  #
  # @argument tag [Optional,String]
  #   Include only jobs with the given tag
  #
  # @argument strand [Optional,String]
  #   Include only jobs with the given strand
  #
  # @argument singleton [Optional,String]
  #   Include only job with the given singleton
  #
  # @argument account_id [Optional,Integer]
  #   Include only jobs with the given account id
  #
  # @argument shard_id [Optional,Integer]
  #   Include only jobs with the given shard id
  #
  # @argument order [String,"tag"|"strand"|"singleton"|"info"]
  #   Sort column. Default is "info". See the +bucket+ argument for a description of this field.
  def list
    scope = jobs_scope

    %i[tag strand singleton account_id shard_id].each do |filter_param|
      scope = scope.where(filter_param => params[filter_param]) if params[filter_param].present?
    end
    scope = scope.order(list_order_clause)

    jobs = Api.paginate(scope, self, api_v1_jobs_list_url)

    now = Delayed::Job.db_time_now
    render json: jobs.map { |job| job_json(job, base_time: now) }
  end

  # @{not an}API Find tags or strands via text search
  #
  # @argument bucket [Required,String,"queued"|"running"|"future"|"failed"]
  #   Which jobs to consider.
  #
  # @argument group [String,"tag"|"strand"|"singleton"]
  #   How to group jobs. Default is "tag".
  #
  # @argument term [Required,String]
  #   Search term
  #
  # @example_request
  #     curl https://<canvas>/jobs2/running/by_tag/search?term=foo \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   { "foobar": 3, "foobaz": 1 }
  def search
    term = params[:term]
    raise ActionController::BadRequest unless term.present?

    result = jobs_scope
             .where(ActiveRecord::Base.wildcard(@group, term))
             .group(@group)
             .order({ count_id: :DESC }, @group)
             .limit(SEARCH_LIMIT)
             .count(:id)

    render json: result
  end

  protected

  def require_bucket
    @bucket = params[:bucket]
    throw :abort unless BUCKETS.include?(@bucket)
  end

  def require_group
    @group = params[:group].to_sym if %w[tag strand singleton].include?(params[:group])
    throw :abort unless @group
  end

  def queued_scope
    Delayed::Job.where("run_at <= now() AND (locked_by IS NULL OR locked_by = ?)", ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY)
  end

  def jobs_scope
    case @bucket
    when "queued" then queued_scope
    when "running" then Delayed::Job.running
    when "future" then Delayed::Job.future
    when "failed" then Delayed::Job::Failed
    end
  end

  def grouped_info_json(row, group, base_time:)
    { :count => row.count, group => row[group], :info => grouped_info_data(row, base_time: base_time) }
  end

  def job_json(job, base_time:)
    job_fields = %w[id tag strand singleton shard_id max_concurrent priority attempts max_attempts locked_by run_at locked_at handler]
    job_fields += %w[failed_at original_job_id last_error] if @bucket == "failed"
    json = api_json(job, @current_user, nil, only: job_fields)
    json.merge("info" => list_info_data(job, base_time: base_time))
  end

  def grouped_order_clause(group_type)
    case params[:order]
    when "tag", "strand", "singleton"
      "LOWER(#{params[:order]})"
    when "count"
      { count: :DESC }
    when "group"
      "LOWER(#{group_type})"
    else
      case @bucket
      when "queued" then :min_run_at
      when "running" then :first_locked_at
      when "future" then :next_run_at
      when "failed" then { last_failed_at: :DESC }
      end
    end
  end

  def grouped_info_select
    case @bucket
    when "queued" then "MIN(run_at) AS min_run_at"
    when "running" then "MIN(locked_at) AS first_locked_at"
    when "future" then "MIN(run_at) AS next_run_at"
    when "failed" then "MAX(failed_at) AS last_failed_at"
    end
  end

  def grouped_info_data(row, base_time:)
    case @bucket
    when "queued" then base_time - row.min_run_at
    when "running" then base_time - row.first_locked_at
    when "future" then row.next_run_at
    when "failed" then row.last_failed_at
    end
  end

  def list_info_data(row, base_time:)
    case @bucket
    when "queued" then base_time - row.run_at
    when "running" then base_time - row.locked_at
    when "future" then row.run_at
    when "failed" then row.failed_at
    end
  end

  def list_order_clause
    case params[:order]
    when "tag", "strand", "singleton"
      "LOWER(#{params[:order]})"
    when "id"
      { id: :DESC }
    else
      case @bucket
      when "queued", "future" then :run_at
      when "running" then :locked_at
      when "failed" then { failed_at: :DESC }
      end
    end
  end

  def set_navigation
    set_active_tab "jobs_v2"
    add_crumb t("#crumbs.jobs_v2", "Jobs v2")
  end
end
