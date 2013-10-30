class JobsController < ApplicationController
  before_filter :require_manage_jobs, :only => [:batch_update]
  before_filter :require_view_jobs, :only => [:index, :show]
  before_filter :set_site_admin_context, :set_navigation, :only => [:index]
  POPULAR_TAG_COUNTS = 12
  LIMIT = 100

  def require_manage_jobs
    require_site_admin_with_permission(:manage_jobs)
  end

  def require_view_jobs
    require_site_admin_with_permission(:view_jobs)
  end

  def index
    @flavor = params[:flavor] || 'current'

    Shackles.activate(:slave) do
      respond_to do |format|
        format.html do
          @running_jobs_refresh_seconds = Setting.get('running_jobs_refresh_seconds', 2.seconds.to_s).to_f
          @job_tags_refresh_seconds  = Setting.get('job_tags_refresh_seconds', 10.seconds.to_s).to_f
        end

        format.js do
          case params[:only]
          when 'running'
            render :json => {running: Delayed::Job.running_jobs.map{ |j| j.as_json(include_root: false, except: [:handler, :last_error]) }}
          when 'tags'
            render :json => {tags: Delayed::Job.tag_counts(@flavor, POPULAR_TAG_COUNTS)}
          when 'jobs'
            jobs = jobs(@flavor, params[:limit] || LIMIT, params[:offset].to_i)
            jobs[:jobs].map!{ |j| j.as_json(:include_root => false, :except => [:handler, :last_error]) }
            render :json => jobs
          end
        end
      end
    end
  end

  def show
    if params[:flavor] == 'failed'
      job = Delayed::Job::Failed.find(params[:id])
    else
      job = Delayed::Job.find(params[:id])
    end
    render :json => job.as_json(:include_root => false)
  end

  def batch_update
    opts = {}

    if params[:job_ids].present?
      opts[:ids] = params[:job_ids]
    elsif params[:flavor].present?
      opts[:flavor] = params[:flavor]
      opts[:query] = params[:q]
    end

    count = Delayed::Job.bulk_update(params[:update_action], opts)

    render :json => { :status => 'OK', :count => count }
  end

  protected

  def jobs(flavor, limit, offset)
    case flavor
    when 'id'
      jobs = []
      jobs << Delayed::Job.find_by_id(params[:q]) if params[:q].present?
      jobs = jobs.compact
      jobs_count = jobs.size
    when 'future', 'current', 'failed'
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

    return { :jobs => jobs, :total => jobs_count }
  end

  def set_navigation
    @active_tab = 'jobs'
    add_crumb t('#crumbs.jobs', "Jobs")
  end
end
