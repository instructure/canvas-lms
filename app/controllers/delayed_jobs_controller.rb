#
# Copyright (C) 2011 Instructure, Inc.
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
#

class DelayedJobsController < ApplicationController
  before_filter :require_site_admin
  ON_HOLD_COUNT = 50
  POPULAR_TAG_COUNTS = 5
  
  def index
    total_count = Delayed::Job.count
    @delayed_jobs = Delayed::Job.paginate(:page => params[:page], :per_page => 30, :total_entries => total_count, :order => 'id DESC')
    @running_now = Delayed::Job.find(:all, :conditions => "locked_by IS NOT NULL AND locked_by != '' AND locked_by != 'on hold'")
    @counts = {}
    @counts[:healthy_waiting] = Delayed::Job.count(:all, :conditions => "attempts = 0 AND run_at < '#{1.second.from_now.to_s(:db)}' AND (locked_by IS NULL or locked_by = '')")
    @counts[:healthy_running] = Delayed::Job.count(:all, :conditions => "attempts = 0 AND (locked_by IS NOT NULL AND locked_by != '')")
    @counts[:healthy_future] = Delayed::Job.count(:all, :conditions => "attempts = 0 AND run_at > '#{1.second.from_now.to_s(:db)}' AND (locked_by IS NULL or locked_by = '')")
    
    @counts[:failed_not_max] = Delayed::Job.count(:all, :conditions => "attempts > 0 AND attempts < #{Delayed::Worker.max_attempts}")
    @counts[:failed_max] = Delayed::Job.count(:all, :conditions => "attempts = #{Delayed::Worker.max_attempts}")
    @counts[:failed_waiting] = Delayed::Job.count(:all, :conditions => "attempts > 0 AND attempts < #{Delayed::Worker.max_attempts} AND run_at < '#{1.second.from_now.to_s(:db)}' AND (locked_by IS NULL or locked_by = '')")
    @counts[:failed_running] = Delayed::Job.count(:all, :conditions => "attempts > 0 AND attempts < #{Delayed::Worker.max_attempts} AND (locked_by IS NOT NULL AND locked_by != '')")
    @counts[:failed_future] = Delayed::Job.count(:all, :conditions => "attempts > 0 AND attempts < #{Delayed::Worker.max_attempts} AND run_at > '#{1.second.from_now.to_s(:db)}' AND (locked_by IS NULL or locked_by = '')")
    
    @counts[:hold_total] = Delayed::Job.count(:all, :conditions => "attempts = #{ON_HOLD_COUNT}")
    
    @counts[:total_jobs] = total_count

    @tags = Delayed::Job.count(:group => 'tag', :limit => POPULAR_TAG_COUNTS, :order => 'count(tag) desc', :select => 'tag')
  end
  
  def show
    @delayed_job = Delayed::Job.find(params[:id])
  end
  
  def edit
    @delayed_job = Delayed::Job.find(params[:id])
  end
  
  def update
    @delayed_job = Delayed::Job.find(params[:id])
    if @delayed_job.update_attributes(params[:delayed_backend_active_record_job])
      flash[:notice] = "Successfully updated delayed job."
      redirect_to delayed_job_url(@delayed_job)
    else
      render :action => 'edit'
    end
  end
  
  def queue
    attr_hash = {:locked_by=>nil, :locked_at=>nil, :run_at=>1.minute.ago, :attempts=>0, :failed_at=>nil, :last_error=>nil}
    conditions = nil
    method_name = params[:method_name].strip rescue ""
    if method_name != ""
      conditions = ["handler LIKE ?", "%method: :#{method_name}%"]
    elsif params[:id] and params[:id] != ""
      conditions = ["id = ?", params[:id]]
    end
    Delayed::Job.update_all(attr_hash, conditions) if conditions
    
    redirect_to delayed_jobs_url
  end
  
  def hold
    attr_hash = {:locked_by=>"on hold", :locked_at=>1.second.ago, :attempts=>ON_HOLD_COUNT, :failed_at=>1.minute.ago}
    conditions = nil
    method_name = params[:method_name].strip rescue ""
    if method_name != ""
      conditions = ["handler LIKE ?", "%method: :#{method_name}%"]
    elsif params[:id] and params[:id] != ""
      conditions = ["id = ?", params[:id]]
    end
    Delayed::Job.update_all(attr_hash, conditions) if conditions
    
    redirect_to delayed_jobs_url
  end
  
  def destroy
    @delayed_job = Delayed::Job.find(params[:id])
    @delayed_job.destroy
    flash[:notice] = "Successfully destroyed delayed job."
    redirect_to delayed_jobs_url
  end
end
