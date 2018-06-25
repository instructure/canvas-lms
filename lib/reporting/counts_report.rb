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
#

require 'date'

module Reporting

class CountsReport
  MONTHS_TO_KEEP = 24
  WEEKS_TO_KEEP = 52

  def self.process_shard
    reporter = new

    Account.root_accounts.active.each do |account|
      next if account.external_status == 'test'

      reporter.process_account(account)
    end
  end

  def initialize
    date = Date.yesterday
    @yesterday = Time.parse("#{date} 23:59:00 UTC")
    @week = date.cweek
    @timestamp = @yesterday
  end

  def process_account(account)
    Shackles.activate(:slave) do
      data = {}.with_indifferent_access
      data[:generated_at] = @timestamp
      data[:id] = account.id
      data[:name] = account.name
      data[:external_status] = account.external_status

      course_ids = get_course_ids(account)
      data[:courses] = course_ids.length

      if data[:courses] == 0
        data[:teachers] = 0
        data[:students] = 0
        data[:users] = 0
        data[:files] = 0
        data[:files_size] = 0
        data[:media_files] = 0
        data[:media_files_size] = 0
      else
        timespan = Setting.get('recently_logged_in_timespan', 30.days.to_s).to_i.seconds
        enrollment_scope = Enrollment.active.not_fake.
          joins("INNER JOIN #{Pseudonym.quoted_table_name} ON enrollments.user_id=pseudonyms.user_id").
          where(pseudonyms: { workflow_state: 'active'}).
          where("course_id IN (?) AND pseudonyms.last_request_at>?", course_ids, timespan.seconds.ago)

        data[:teachers] = enrollment_scope.where(:type => 'TeacherEnrollment').distinct.count(:user_id)
        data[:students] = enrollment_scope.where(:type => 'StudentEnrollment').distinct.count(:user_id)
        data[:users] = enrollment_scope.distinct.count(:user_id)

        # ActiveRecord::Base.calculate doesn't support multiple calculations in account single pass
        data[:files], data[:files_size] = Attachment.connection.select_rows("SELECT COUNT(id), SUM(size) FROM #{Attachment.quoted_table_name} WHERE namespace IN ('account_%s','account_%s') AND root_attachment_id IS NULL AND file_state != 'deleted'" % [account.local_id, account.global_id]).first.map(&:to_i)
        data[:media_files], data[:media_files_size] = MediaObject.connection.select_rows("SELECT COUNT(id), SUM(total_size) FROM #{MediaObject.quoted_table_name} WHERE root_account_id='%s' AND attachment_id IS NULL AND workflow_state != 'deleted'" % [account.id]).first.map(&:to_i)
        data[:media_files_size] *= 1000
      end

      Shackles.activate(:master) do
        detailed = account.report_snapshots.detailed.build
        detailed.created_at = @yesterday
        detailed.data = data
        detailed.save!

        save_detailed_progressive(account, data)
      end
    end

    nil
  end

  private

  def save_detailed_progressive(account, data)
    if snapshot = account.report_snapshots.progressive.last
      progressive = snapshot.data.with_indifferent_access
    else
      progressive = new_progressive_hash.with_indifferent_access
    end
    progressive[:generated_at] = @timestamp
    create_progressive_hashes(progressive, data)

    snapshot = account.report_snapshots.progressive.build
    snapshot.created_at = @yesterday
    snapshot.data = progressive
    snapshot.save!
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
    cumulative[:monthly] << month
    while cumulative[:monthly].length > MONTHS_TO_KEEP
      cumulative[:monthly].shift
    end

    week = {:year=>@yesterday.year, :month=>@yesterday.month, :week=>@week}
    copy_counts(week, totals)
    if cumulative[:weekly].last and cumulative[:weekly].last[:year] == week[:year] and cumulative[:weekly].last[:week] == week[:week]
      cumulative[:weekly].pop
    end
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
  end

  def get_course_ids(account)
    is_default_account = account.external_status == ExternalStatuses.default_external_status.to_s
    course_ids = []
    account.all_courses.where(:workflow_state => 'available').select([:id, :updated_at]).find_in_batches do |batch|
      course_ids.concat batch.select { |course| !is_default_account || should_use_default_account_course(course) }.map(&:id)
    end
    course_ids
  end

  def should_use_default_account_course(course)
    @one_month_ago ||= @yesterday - 1.month
    course.updated_at > @one_month_ago
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
