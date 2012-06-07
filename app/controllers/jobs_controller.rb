class JobsController < ApplicationController
  before_filter :require_manage_jobs
  before_filter :set_site_admin_context, :set_navigation, :only => [:index]
  POPULAR_TAG_COUNTS = 10
  LIMIT = 100

  def require_manage_jobs
    require_site_admin_with_permission(:manage_jobs)
  end

  def index
    if request.path == '/delayed_jobs'
      return redirect_to(jobs_url)
    end

    if params[:id].present?
      params[:q] = params[:id]
      params[:flavor] = params[:flavor] == 'failed' ? params[:flavor] : 'all'
    end

    ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) do
      jobs_scope

      respond_to do |format|
        format.html do
          running
          tags(@jobs)
          @jobs_count = @jobs.count
          render
        end

        format.js do
          result = {}
          case params[:only]
          when 'running'
            result[:running] = running
          when 'tags'
            result[:tags] = tags(@jobs)
          when 'jobs'
            result[:jobs] = @jobs.all(
              :limit => params[:limit] || LIMIT,
              :offset => params[:offset].try(:to_i))
            result[:total] = @jobs.count
          end
          render :json => result.to_json(:include_root => false)
        end
      end
    end
  end

  def batch_update
    jobs_scope

    case params[:update_action]
    when 'hold'
      @jobs.hold!
    when 'unhold'
      @jobs.unhold!
    when 'destroy'
      @jobs.delete_all
    end

    render :json => { :status => 'OK' }
  end

  protected

  def running
    @running = Delayed::Job.running.scoped(:order => 'id desc')
  end

  def tags(scope)
    @tags = scope.count(:group => 'tag', :limit => POPULAR_TAG_COUNTS, :order => 'count(tag) desc', :select => 'tag').map { |t,c| { :tag => t, :count => c } }
  end

  def jobs_scope
    @flavor = params[:flavor] || 'current'

    case @flavor
    when 'future'
      @jobs = Delayed::Job.future
    when 'current'
      @jobs = Delayed::Job.current
    when 'all'
      # pass
      @jobs = Delayed::Job
    when 'failed'
      @jobs = Delayed::Job::Failed
    end

    @jobs = @jobs.scoped(:order => 'id desc')

    if params[:q].present?
      if params[:q].to_i > 0
        @jobs = @jobs.scoped(:conditions => { :id => params[:q].to_i })
      else
        @jobs = @jobs.scoped(:conditions => ["#{Delayed::Job.wildcard('tag', params[:q])} OR strand = ?", params[:q]])
      end
    end

    if params[:job_ids].present?
      @jobs = @jobs.scoped(:conditions => { :id => params[:job_ids].map(&:to_i) })
    end
  end

  def set_navigation
    @active_tab = 'jobs'
    add_crumb t('#crumbs.jobs', "Jobs")
  end
end
