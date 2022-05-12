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

  before_action :require_view_jobs, except: %i[manage]
  before_action :require_manage_jobs, only: %i[manage]

  before_action :require_bucket, only: %i[grouped_info list search]
  before_action :require_group, only: %i[grouped_info search]
  before_action :set_date_range, only: %i[grouped_info list search]
  before_action :set_site_admin_context, :set_navigation, only: [:index]

  def require_view_jobs
    require_site_admin_with_permission(:view_jobs)
  end

  def require_manage_jobs
    require_site_admin_with_permission(:manage_jobs)
  end

  def redirect
    redirect_to(Account.site_admin.feature_enabled?(:jobs_v2) ? jobs_v2_index_url : jobs_v1_index_url)
  end

  def index
    respond_to do |format|
      format.html do
        @page_title = t("Jobs Control Panel v2")

        css_bundle :jobs_v2
        js_bundle :jobs_v2

        jobs_server = @domain_root_account.shard.delayed_jobs_shard&.database_server_id
        cluster = @domain_root_account.shard&.database_server_id
        js_env(
          manage_jobs: Account.site_admin.grants_right?(@current_user, session, :manage_jobs),
          jobs_scope_filter: {
            jobs_server: (jobs_server && t("Server: %{server}", server: jobs_server)) || t("All Jobs"),
            cluster: cluster && t("Cluster: %{cluster}", cluster: cluster),
            shard: t("Shard: %{shard}", shard: @domain_root_account.shard.name),
            account: t("Account: %{account}", account: @domain_root_account.name)
          }.compact
        )

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

  # @argument scope [Optional,String,"jobs_server"|"cluster"|"shard"|"account"]
  #   The scope of jobs to consider. By default, all jobs on the jobs server are
  #   considered. if "cluster", "shard", or "account" is given, jobs will be filtered
  #   to the unit of that type belonging to the domain root account.
  #
  # @argument start_date [Optional,Date]
  #   Filter to jobs with a +run_at+ greater than or equal to the given timestamp.
  #   when +bucket+ is "failed", +failed_at+ will be considered instead.
  #
  # @argument end_date [Optional,Date]
  #   Filter to jobs with a +run_at+ less than or equal to the given timestamp.
  #   when +bucket+ is "failed", +failed_at+ will be considered instead.
  #
  def grouped_info
    GuardRail.activate(:secondary) do
      scope = jobs_scope
              .select("count(*) AS count, #{@group}, #{grouped_info_select}")
              .where.not(@group => nil)
              .group(@group)
              .order(grouped_order_clause(@group))

      # This seems silly, but it forces postgres to use the available indicies.
      scope = scope.where("locked_by IS NULL OR locked_by IS NOT NULL") if @group == :singleton

      tag_info = Api.paginate(scope, self, api_v1_jobs_grouped_info_url)
      now = Delayed::Job.db_time_now
      render json: tag_info.map { |row| grouped_info_json(row, @group, base_time: now) }
    end
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
  #
  # @argument scope [Optional,String,"jobs_server"|"cluster"|"shard"|"account"]
  #   The scope of jobs to consider. By default, all jobs on the jobs server are
  #   considered. if "cluster", "shard", or "account" is given, jobs will be filtered
  #   to the unit of that type belonging to the domain root account.
  #
  # @argument start_date [Optional,Date]
  #   Filter to jobs with a +run_at+ greater than or equal to the given timestamp.
  #   when +bucket+ is "failed", +failed_at+ will be considered instead.
  #
  # @argument end_date [Optional,Date]
  #   Filter to jobs with a +run_at+ less than or equal to the given timestamp.
  #   when +bucket+ is "failed", +failed_at+ will be considered instead.
  #
  def list
    GuardRail.activate(:secondary) do
      scope = jobs_scope

      %i[tag strand singleton account_id shard_id].each do |filter_param|
        scope = scope.where(filter_param => params[filter_param]) if params[filter_param].present?
      end

      # This seems silly, but it forces postgres to use the available indicies.
      scope = scope.where("locked_by IS NULL OR locked_by IS NOT NULL") if params[:singleton].present?
      scope = scope.order(list_order_clause)

      jobs = Api.paginate(scope, self, api_v1_jobs_list_url)

      now = Delayed::Job.db_time_now
      render json: jobs.map { |job| job_json(job, base_time: now) }
    end
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
  #     curl https://<canvas>/api/v1/jobs2/running/by_tag/search?term=foo \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   { "foobar": 3, "foobaz": 1 }
  def search
    GuardRail.activate(:secondary) do
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
  end

  # @{not an}API Lookup job by id or original_job_id
  #
  # Searches all job buckets including queued, running, future, and failed.
  # for failed jobs, it will find by original_job_id or id, in that order
  # of preference. theoretically two jobs could be returned if a failed job's
  # id matches a different failed job's original_job_id, but in production
  # original job ids are much greater than failed job ids so overlap is rare.
  #
  # an additional +bucket+ will be returned indicating whether the job is
  # running, queued, future, or failed
  #
  # @example_request
  #     curl https://<canvas>/api/v1/jobs2/123 \
  #          -H 'Authorization: Bearer <token>'
  def lookup
    GuardRail.activate(:secondary) do
      id = params[:id]
      raise ActionController::BadRequest unless id.present?

      jobs = Delayed::Job.where(id: id).to_a
      jobs.concat Delayed::Job::Failed.where(id: id).or(
        Delayed::Job::Failed.where(original_job_id: id)
      ).order(:id).to_a

      render json: jobs.map { |job| job_json(job) }
    end
  end

  # @{not an}API Manage a strand
  #
  # @argument strand [Required,String]
  #   The name of the strand to manage
  #
  # @argument max_concurrent [Integer]
  #   The new maximum concurrency for the strand
  #
  # @argument priority [Integer]
  #   The new priority value to set
  #
  def manage
    strand = params[:strand].presence
    return render json: { message: "missing strand" }, status: :bad_request unless strand

    update_args = {}

    if params[:max_concurrent].present?
      update_args[:max_concurrent] = params[:max_concurrent].to_i
    end

    if params[:priority].present?
      update_args[:priority] = params[:priority].to_i
    end

    count = nil
    Delayed::Job.transaction do
      Delayed::Job.advisory_lock(strand)
      count = Delayed::Job.where(strand: strand).update_all(update_args)
      # TODO: revisit this after DE-1158
      unleash_more_jobs(strand, update_args[:max_concurrent]) if update_args[:max_concurrent]
    end
    render json: { status: "OK", count: count }
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
    scope = case @bucket
            when "queued" then queued_scope
            when "running" then Delayed::Job.running
            when "future" then Delayed::Job.future
            when "failed" then Delayed::Job::Failed
            end

    if @start_date || @end_date
      date_column = case @bucket
                    when "failed"
                      "failed_at"
                    when "running"
                      "locked_at"
                    else
                      "run_at"
                    end
      scope = scope.where("#{date_column}>=?", @start_date) if @start_date
      scope = scope.where("#{date_column}<=?", @end_date) if @end_date
    end

    case params[:scope]
    when "cluster"
      database_server_id = @domain_root_account.shard.database_server_id
      shard_ids = Shard.where(database_server_id: database_server_id).pluck(:id)

      scope.where(shard_id: shard_ids)
    when "shard" then scope.where(shard_id: @domain_root_account.shard)
    when "account" then scope.where(account_id: @domain_root_account)
    else scope
    end
  end

  def grouped_info_json(row, group, base_time:)
    { :count => row.count, group => row[group], :info => grouped_info_data(row, base_time: base_time) }
  end

  def job_json(job, base_time: nil)
    job_fields = %w[id tag strand singleton shard_id max_concurrent priority attempts max_attempts locked_by run_at locked_at handler]
    job_fields += %w[failed_at original_job_id last_error] if job.is_a?(Delayed::Job::Failed)
    json = api_json(job, @current_user, nil, only: job_fields)
    if @bucket && base_time
      json["info"] = list_info_data(job, base_time: base_time)
    else
      json["bucket"] = infer_bucket(job)
    end
    json
  end

  def infer_bucket(job)
    if job.is_a?(Delayed::Job::Failed)
      "failed"
    elsif job.locked_at && job.locked_by != ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY
      "running"
    elsif job.run_at <= Time.zone.now
      "queued"
    else
      "future"
    end
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
    when "strand_singleton"
      "LOWER(strand) ASC, LOWER(singleton) ASC"
    when "tag"
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

  def set_date_range
    @start_date = Time.zone.parse(params[:start_date]) if Api::ISO8601_REGEX.match?(params[:start_date])
    @end_date = Time.zone.parse(params[:end_date]) if Api::ISO8601_REGEX.match?(params[:end_date])
  end

  def set_navigation
    set_active_tab "jobs"
    add_crumb t("#crumbs.jobs", "Jobs")
  end

  def unleash_more_jobs(strand, new_parallelism)
    needed_jobs = new_parallelism - Delayed::Job.where(strand: strand, next_in_strand: true).count
    if needed_jobs > 0
      Delayed::Job.where(strand: strand, next_in_strand: false, locked_by: nil, singleton: nil).order(:id).limit(needed_jobs).update_all(next_in_strand: true)
    end
  end
end
