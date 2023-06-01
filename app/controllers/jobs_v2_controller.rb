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
  include Api::V1::Progress

  BUCKETS = %w[queued running future failed].freeze
  SEARCH_LIMIT = 100

  MANAGE_ENDPOINTS = %i[manage requeue unstuck throttle].freeze
  before_action :require_view_jobs, except: MANAGE_ENDPOINTS
  before_action :require_manage_jobs, only: MANAGE_ENDPOINTS

  before_action :require_bucket, only: %i[grouped_info list search]
  before_action :require_group, only: %i[grouped_info search]
  before_action :set_date_range, only: %i[grouped_info list search]
  before_action :set_site_admin_context, :set_navigation, only: [:index, :job_stats]

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
        deferred_js_bundle :jobs_v2

        jobs_server = @domain_root_account.shard.delayed_jobs_shard&.database_server_id
        cluster = @domain_root_account.shard&.database_server_id
        js_env(
          manage_jobs: Account.site_admin.grants_right?(@current_user, session, :manage_jobs),
          jobs_scope_filter: {
            jobs_server: (jobs_server && t("Server: %{server}", server: jobs_server)) || t("All Jobs"),
            cluster: cluster && t("Cluster: %{cluster}", cluster:),
            shard: t("Shard: %{shard}", shard: @domain_root_account.shard.name),
            account: t("Account: %{account}", account: @domain_root_account.name)
          }.compact
        )

        render html: "", layout: true
      end
    end
  end

  def job_stats
    respond_to do |format|
      format.html do
        @page_title = t("Jobs Stats by Cluster")

        js_env(
          manage_jobs: Account.site_admin.grants_right?(@current_user, session, :manage_jobs)
        )

        deferred_js_bundle :job_stats
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

      group_info = Api.paginate(scope, self, api_v1_jobs_grouped_info_url)
      group_statuses = get_group_statuses(group_info, @group) if %i[strand singleton].include?(@group)

      now = Delayed::Job.db_time_now
      render json: group_info.map { |row| grouped_info_json(row, @group, base_time: now, group_statuses:) }
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

      jobs = Delayed::Job.where(id:).to_a
      jobs.concat Delayed::Job::Failed.where(id:).or(
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
      count = Delayed::Job.where(strand:).update_all(update_args)
      SwitchmanInstJobs::JobsMigrator.unblock_strand!(strand, new_parallelism: update_args[:max_concurrent]) if update_args[:max_concurrent]
    end
    render json: { status: "OK", count: }
  end

  # @{not an}API requeue a failed job
  #
  # given a job that exhausted all of its max_attempts and has been put into failed_jobs
  # requeue it. it will be attempted once more and not retried if max_attempts > 1
  # (this will push attempts over max_attempts)
  #
  def requeue
    failed_job = Delayed::Job::Failed.find(params[:id])
    job = failed_job.requeue!
    render json: job_json(job)
  end

  # @{not an}API unstuck orphaned strands/singletons
  #
  # Given a strand or singleton that cannot progress because no job is next_in_strand,
  # unstuck the jobs by setting next_in_strand on the appropriate number of stuck jobs
  #
  # if a +strand+ or +singleton+ is supplied, it will be unstucked synchronously and status "OK"
  # will be returned.
  #
  # otherwise, a job will be queued to run the unblocker on all strands and singletons in
  # job shards given by the ids in the +job_shards+ parameter (all job shards in the region
  # if none specified) and status "pending" will be returned along with progress information.
  #
  # if a strand or singleton is blocked by the shard migrator, status "blocked" will be returned.
  #
  # @argument strand [Optional,String]
  #   The name of the strand to unstuck
  #
  # @argument singleton [Optional,String]
  #   The name of the singleton to unstuck
  #
  def unstuck
    if params[:strand].present?
      begin
        count = SwitchmanInstJobs::JobsMigrator.unblock_strand!(params[:strand])
        raise ActiveRecord::RecordNotFound if count.nil?

        render json: { status: "OK", count: }
      rescue SwitchmanInstJobs::JobsBlockedError
        render json: { status: "blocked" }
      end
    elsif params[:singleton].present?
      begin
        count = SwitchmanInstJobs::JobsMigrator.unblock_singleton!(params[:singleton])
        raise ActiveRecord::RecordNotFound if count.nil?

        render json: { status: "OK", count: }
      rescue SwitchmanInstJobs::JobsBlockedError
        render json: { status: "blocked" }
      end
    else
      progress = Progress.create(context: @current_user, tag: "JobsV2Controller::run_unstucker!")
      progress.process_job(JobsV2Controller,
                           :run_unstucker!,
                           { priority: Delayed::HIGH_PRIORITY },
                           shard_ids: Array(params[:job_shards]))
      render json: { status: "pending", progress: progress_json(progress, @current_user, session) }
    end
  end

  # @{not an}API return information about job clusters
  #
  # @argument job_shards [Optional, Array] ids of specific job shards to query
  #
  # @example_response
  #   [
  #     {
  #       "id": 106,
  #       "database_server_id": "jobs6",
  #       "block_stranded_shard_ids": [1170],
  #       "jobs_held_shard_ids": [],
  #       "domain": "jobs6.instructure.com",
  #       "counts": {
  #          "queued": 1170,
  #          "running": 135,
  #          "future": 1500,
  #          "blocked": 17
  #       }
  #     },
  #     ...
  #   ]
  def clusters
    GuardRail.activate(:secondary) do
      scope = self.class.filtered_dj_shards(Array(params[:job_shards]))

      # since fetching blocked job stats can be expensive, we will do one job cluster per page by default
      shards = Api.paginate(scope, self, api_v1_job_clusters_url, default_per_page: 1)
      render json: shards.map { |dj_shard|
        json = dj_shard.slice(:id, :database_server_id)
        json["block_stranded_shard_ids"] = Shard.where(delayed_jobs_shard_id: dj_shard.id, block_stranded: true).pluck(:id)
        json["jobs_held_shard_ids"] = Shard.where(delayed_jobs_shard_id: dj_shard.id, jobs_held: true).pluck(:id)
        dj_shard.activate do
          account = Account.root_accounts.active.first
          json["domain"] = account.primary_domain&.host if account.respond_to?(:primary_domain)
          json["domain"] ||= request.host_with_port
          json["counts"] = {}
          json["counts"]["queued"] = queued_scope.count
          json["counts"]["running"] = Delayed::Job.running.count
          json["counts"]["future"] = Delayed::Job.future.count
          json["counts"]["blocked"] = SwitchmanInstJobs::JobsMigrator.blocked_job_count
        end
        json
      }
    end
  end

  # @{not an}API return a list of stuck strands in a given job shard
  #
  # @argument job_shard [Optional, Integer]
  #   The id of the job shard to check. The domain root account's job shard
  #   will be checked by default
  #
  # @example_response
  #   [
  #     { name: "foo", count: 100 },
  #     { name: "bar", count: 3 }
  #   ]
  #
  def stuck_strands
    GuardRail.activate(:secondary) do
      activate_job_shard do
        scope = SwitchmanInstJobs::JobsMigrator.blocked_strands.select("strand, count(*) AS count").order(:strand)
        strands = Api.paginate(scope, self, api_v1_jobs_stuck_strands_url)
        render json: strands.map { |row| { name: row.strand, count: row.count } }
      end
    end
  end

  # @{not an}API return a list of stuck singletons in a given job shard
  #
  # @argument job_shard [Optional, Integer]
  #   The id of the job shard to check. The domain root account's job shard
  #   will be checked by default
  #
  # @example_response
  #   [
  #     { name: "foo", count: 1 },
  #     { name: "bar", count: 1 }
  #   ]
  #
  def stuck_singletons
    GuardRail.activate(:secondary) do
      activate_job_shard do
        scope = SwitchmanInstJobs::JobsMigrator.blocked_singletons.select("singleton, count(*) AS count").order(:singleton)
        singletons = Api.paginate(scope, self, api_v1_jobs_stuck_singletons_url)
        render json: singletons.map { |row| { name: row.singleton, count: row.count } }
      end
    end
  end

  # @{not an}API Test throttle search term
  #
  # @argument term [Required, String]
  #   The search term. Will find unstranded queued jobs whose tags start with this term.
  #
  # @argument shard_id [Optional, Integer]
  #   If given, limit search to jobs on this shard
  #
  # @example_response
  #   {
  #     matched_jobs: 103,
  #     matched_tags: 7
  #   }
  #
  def throttle_check
    GuardRail.activate(:secondary) do
      term = params[:term]
      raise ActionController::BadRequest, "missing term" unless term.present?

      scope = throttle_scope(term, params[:shard_id])
      render json: {
        matched_jobs: scope.count,
        matched_tags: scope.distinct.count(:tag)
      }
    end
  end

  # @{not an}API Throttle jobs with a specific tag pattern by stranding them
  #
  # @argument term [Required, String]
  #   The search term. Unstranded queued jobs whose tags start with this term
  #   (case sensitively) will be throttled.
  #
  # @argument shard_id [Optional, Integer]
  #   If given, limit to jobs on this shard
  #
  # @argument max_concurrent [Optional, Integer]
  #   The number of matched jobs to allow to run concurrently. Default 1
  #
  # @example_response
  #   {
  #     job_count: 110,
  #     new_strand: "tmp_strand_2b369177"
  #   }
  #
  def throttle
    term = params[:term]
    raise ActionController::BadRequest, "missing term" unless term.present?

    max_concurrent = params[:max_concurrent]&.to_i || 1

    scope = throttle_scope(term, params[:shard_id])
    job_count, new_strand = ::Delayed::Job.apply_temp_strand!(scope, max_concurrent:)

    render json: {
      job_count:,
      new_strand:
    }
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

  def activate_job_shard(&)
    if params[:job_shard].present?
      shard = ::Switchman::Shard.find(params[:job_shard])
      if shard.delayed_jobs_shard_id && shard.delayed_jobs_shard_id != shard.id
        return render json: { message: "not a job shard" }, status: :bad_request
      end

      shard.activate(&)
    else
      yield
    end
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
      shard_ids = ::Switchman::Shard.where(database_server_id:).pluck(:id)

      scope.where(shard_id: shard_ids)
    when "shard" then scope.where(shard_id: @domain_root_account.shard)
    when "account" then scope.where(account_id: @domain_root_account)
    else scope
    end
  end

  def throttle_scope(search_term, shard_id)
    scope = Delayed::Job
            .where(strand: nil, singleton: nil, locked_by: nil)
            .where(ActiveRecord::Base.wildcard("tag", search_term, type: :right, case_sensitive: true))
    scope = scope.where(shard_id:) if shard_id.present?
    scope
  end

  def grouped_info_json(row, group, base_time:, group_statuses: nil)
    json = {
      :count => row.count,
      group => row[group],
      :info => grouped_info_data(row, base_time:)
    }
    json[:orphaned] = group_statuses[row[group]] if group_statuses&.key?(row[group])
    json
  end

  def job_json(job, base_time: nil)
    job_fields = %w[id tag strand singleton shard_id max_concurrent priority attempts max_attempts locked_by run_at locked_at handler]
    job_fields += %w[failed_at original_job_id requeued_job_id last_error] if job.is_a?(Delayed::Job::Failed)
    json = api_json(job, @current_user, nil, only: job_fields)
    if @bucket && base_time
      json["info"] = list_info_data(job, base_time:)
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
    if action_name == "job_stats"
      add_crumb t("Job Stats by Cluster")
    else
      add_crumb t("#crumbs.jobs", "Jobs")
    end
  end

  # returns a hash from strand name to boolean indicating the strand or singleton is orphaned
  # (i.e., no job in the group has next_in_strand set)
  def get_group_statuses(jobs, strand_or_singleton)
    return nil unless jobs.present? && %w[queued future].include?(@bucket)

    scope = case strand_or_singleton
            when :strand
              Delayed::Job.where(strand: jobs.map(&:strand))
            when :singleton
              Delayed::Job.where(strand: nil, singleton: jobs.map(&:singleton))
            else
              raise ArgumentError, "strand_or_singleton must be one of those two"
            end
    scope
      .group(strand_or_singleton)
      .pluck("#{strand_or_singleton}, BOOL_OR(next_in_strand)")
      .to_h
      .transform_values(&:!)
  end

  class << self
    def filtered_dj_shards(shard_ids)
      scope = ::Switchman::Shard.delayed_jobs_shards
      scope = scope.order(:id) unless scope.is_a?(Array)
      if shard_ids.present?
        shard_ids = Array(shard_ids).map(&:to_i)
        scope = if scope.is_a?(Array)
                  scope.select { |shard| shard_ids.include?(shard.id) }
                else
                  scope.where(id: shard_ids)
                end
      end
      scope
    end

    def run_unstucker!(progress, shard_ids: [])
      dj_shards = filtered_dj_shards(shard_ids)
      progress.calculate_completion!(0, dj_shards.size)
      dj_shards.each do |dj_shard|
        SwitchmanInstJobs::JobsMigrator.unblock_strands(dj_shard)
        progress.increment_completion!
      end
    end
  end
end
