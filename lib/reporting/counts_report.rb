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

require 'date'
require 'lib/external_statuses'

module Reporting

class CountsReport
  attr_accessor :overview, :detailed

  COUNTS_OVERVIEW = 'counts_overview'
  COUNTS_DETAILED = 'counts_detailed'
  COUNTS_PROGRESSIVE_OVERVIEW = 'counts_progressive_overview'
  COUNTS_PROGRESSIVE_DETAILED = 'counts_progressive_detailed'

  MONTHS_TO_KEEP = 24
  WEEKS_TO_KEEP = 52

  def self.process
    # use the slave, if we can
    config = ActiveRecord::Base.configurations["#{Rails.env}_slave"]
    if config
      ActiveRecord::Base.establish_connection(config)
    end

    self.new.process
  ensure
    # switch back to the old conn
    ActiveRecord::Base.establish_connection
  end

  def initialize
    date = Date.yesterday
    @yesterday = Time.parse("#{date.to_s} 23:59:00 UTC")
    @week = date.cweek
    # make it a javascript timestamp since we're saving in json
    @timestamp = @yesterday.to_i * 1000
    @overview = {:generated_at=>@timestamp, :totals => new_counts_hash}.with_indifferent_access
    ExternalStatuses.possible_external_statuses.each do |status|
      @overview[status.to_sym] = new_counts_hash
    end
    @detailed = {}.with_indifferent_access
  end

  def process
    start_time = Time.now

    each_account do |a|
      next if a.external_status == 'test'
      activity = last_activity(a.id)
      next unless activity

      account = {}
      account[:id] = a.id
      account[:name] = a.name
      account[:external_status] = a.external_status
      account[:last_activity] = activity
      account[:page_views_in_last_week] = PageView.count(:request_id, :conditions => ["account_id = ? AND created_at > ? AND created_at < ?", a.id, @yesterday - 1.week, @yesterday])
      account[:page_views_in_last_month] = PageView.count(:request_id, :conditions => ["account_id = ? AND created_at > ? AND created_at < ?", a.id, @yesterday - 1.month, @yesterday])

      course_ids = []
      get_course_ids(a, course_ids)

      account[:courses] = course_ids.length
      account[:teachers] = course_ids.length == 0 ? 0 : Enrollment.count(:user_id, :distinct => true, :conditions => { :course_id => course_ids, :type => 'TeacherEnrollment' })
      account[:students] = course_ids.length == 0 ? 0 : Enrollment.count(:user_id, :distinct => true, :conditions => { :course_id => course_ids, :type => 'StudentEnrollment' })
      account[:users] = course_ids.length == 0 ? 0 : Enrollment.count(:user_id, :distinct => true, :conditions => { :course_id => course_ids })
      # ActiveRecord::Base.calculate doesn't support multiple calculations in a single pass
      account[:files], account[:files_size] = course_ids.length == 0 ? [0, 0] : Attachment.connection.select_rows("SELECT COUNT(id), SUM(size) FROM #{Attachment.table_name} WHERE namespace='account_%s' AND root_attachment_id IS NULL AND file_state != 'deleted'" % [a.id]).first.map(&:to_i)
      account[:media_files], account[:media_files_size] = course_ids.length == [0, 0] ? 0 : MediaObject.connection.select_rows("SELECT COUNT(id), SUM(total_size) FROM #{MediaObject.table_name} WHERE root_account_id='%s' AND attachment_id IS NULL AND workflow_state != 'deleted'" % [a.id]).first.map(&:to_i)
      account[:media_files_size] *= 1000
      add_account_stats(account)
    end
    @overview[:seconds_to_process] = Time.now - start_time

    save_counts
    save_progressive
    ""
  end

  private

  # override to determine which accounts to report stats on
  def each_account(&block)
    Account.root_accounts.each(&block)
  end

  def save_counts
    overview = ReportSnapshot.new(:report_type => COUNTS_OVERVIEW)
    overview.data = @overview.to_json
    overview.save

    @overview[:detailed] = @detailed
    detailed = ReportSnapshot.new(:report_type => COUNTS_DETAILED)
    detailed.data = @overview.to_json
    detailed.save
  end

  def save_progressive
    if snapshot = ReportSnapshot.find_last_by_report_type(COUNTS_PROGRESSIVE_DETAILED)
      detailed_progressive = JSON.parse(snapshot.data).with_indifferent_access
    else
      detailed_progressive = start_progressive_hash.with_indifferent_access
    end
    
    detailed_progressive[:generated_at] = @timestamp
    create_progressive_hashes(detailed_progressive[:totals], @overview[:totals])
    ExternalStatuses.possible_external_statuses.each do |status|
      detailed_progressive[status.to_sym] ||= new_progressive_hash
      create_progressive_hashes(detailed_progressive[status.to_sym], @overview[status.to_sym])
    end
    @detailed.each do |k, v|
      detailed_progressive[:detailed][k.to_s] ||= new_progressive_hash
      create_progressive_hashes(detailed_progressive[:detailed][k.to_s], v)
    end

    detailed_snap = ReportSnapshot.new(:report_type => COUNTS_PROGRESSIVE_DETAILED)
    detailed_snap.data = detailed_progressive.to_json
    detailed_snap.save

    detailed_progressive.delete :detailed
    overview_snap = ReportSnapshot.new(:report_type => COUNTS_PROGRESSIVE_OVERVIEW)
    overview_snap.data = detailed_progressive.to_json
    overview_snap.save

  end
  
  def create_progressive_hashes(cumulative, totals)
    year = {:year=>@yesterday.year}
    copy_counts(year, totals)
    cumulative[:yearly].pop if cumulative[:yearly].last and cumulative[:yearly].last[:year] == year[:year] 
    cumulative[:yearly] << year
    
    month = {:year=>@yesterday.year, :month=>@yesterday.month}
    copy_counts(month, totals)
    if cumulative[:monthly].last and cumulative[:monthly].last[:year] == month[:year] and cumulative[:monthly].last[:month] == month[:month]
      cumulative[:monthly].pop 
    end
    month[:page_views] = totals[:page_views_in_last_month]
    cumulative[:monthly] << month
    while cumulative[:monthly].length > MONTHS_TO_KEEP
      cumulative[:monthly].shift
    end
    
    week = {:year=>@yesterday.year, :month=>@yesterday.month, :week=>@week}
    copy_counts(week, totals)
    if cumulative[:weekly].last and cumulative[:weekly].last[:year] == week[:year] and cumulative[:weekly].last[:week] == week[:week]
      cumulative[:weekly].pop 
    end
    week[:page_views] = totals[:page_views_in_last_week]
    cumulative[:weekly] << week
    while cumulative[:weekly].length > WEEKS_TO_KEEP
      cumulative[:weekly].shift
    end
  end
  
  def copy_counts(to, from)
    to[:institutions] = from[:institutions]
    to[:courses] = from[:courses]
    to[:teachers] = from[:teachers]
    to[:students] = from[:students]
    to[:users] = from[:users]
    to[:files] = from[:files]
    to[:files_size] = from[:files_size]
    to[:media_files] = from[:media_files]
    to[:media_files_size] = from[:media_files_size]
    to[:page_views_in_last_week] = from[:page_views_in_last_week]
    to[:page_views_in_last_month] = from[:page_views_in_last_month]
  end

  def add_account_stats(account)
    @detailed[account[:id].to_s] = account

    unless @overview[account[:external_status]]
      @overview[account[:external_status]] = new_counts_hash
    end

    @overview[account[:external_status]][:institutions] += 1
    @overview[account[:external_status]][:courses] += account[:courses]
    @overview[account[:external_status]][:teachers] += account[:teachers]
    @overview[account[:external_status]][:students] += account[:students]
    @overview[account[:external_status]][:files] += account[:files]
    @overview[account[:external_status]][:files_size] += account[:files_size]
    @overview[account[:external_status]][:media_files] += account[:media_files]
    @overview[account[:external_status]][:media_files_size] += account[:media_files_size]
    @overview[account[:external_status]][:users] += account[:users]
    @overview[account[:external_status]][:page_views_in_last_week] += account[:page_views_in_last_week]
    @overview[account[:external_status]][:page_views_in_last_month] += account[:page_views_in_last_month]

    @overview[:totals][:institutions] += 1
    @overview[:totals][:courses] += account[:courses]
    @overview[:totals][:teachers] += account[:teachers]
    @overview[:totals][:students] += account[:students]
    @overview[:totals][:files] += account[:files]
    @overview[:totals][:files_size] += account[:files_size]
    @overview[:totals][:media_files] += account[:media_files]
    @overview[:totals][:media_files_size] += account[:media_files_size]
    @overview[:totals][:users] += account[:users]
    @overview[:totals][:page_views_in_last_week] += account[:page_views_in_last_week]
    @overview[:totals][:page_views_in_last_month] += account[:page_views_in_last_month]
  end

  def last_activity(account_id)
    PageView.maximum(:created_at, :conditions => { :account_id => account_id })
  end

  def get_course_ids(account, course_ids)
    account.courses.find_all_by_workflow_state('available').each do |c|
      next if is_default_account(account) and not should_use_default_account_course(c)
      course_ids << c.id
    end
    account.sub_accounts.each do |sa|
      get_course_ids(sa, course_ids)
    end
  end

  def should_use_default_account_course(course)
    @one_month_ago ||= @yesterday - 1.month
    course.updated_at > @one_month_ago
  end

  def is_default_account(account)
    account.root_account.external_status == ExternalStatuses.default_external_status.to_s
  end

  def new_counts_hash
    {
      :institutions=>0,
      :courses=>0,
      :teachers=>0,
      :students=>0,
      :users=>0,
      :files=>0,
      :files_size=>0,
      :media_files=>0,
      :media_files_size=>0,
      :page_views_in_last_week=>0,
      :page_views_in_last_month=>0
    }
  end

  def new_progressive_hash
    {:yearly=>[], :monthly=>[], :weekly=>[]}
  end

  def start_progressive_hash
    hash = {
      :generated_at => @timestamp,
      :totals => new_progressive_hash,
      :detailed => {}
    }
    hash
  end

end

end
