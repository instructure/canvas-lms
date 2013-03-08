#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

module Canvas::AccountReports::ReportHelper

# This function will take a datetime or a datetime string and convert into
# iso8601 for the root_account's timezone
# A string datetime needs to be in UTC
  def default_timezone_format(datetime, account=root_account)
    if datetime.is_a? String
      datetime = Time.use_zone('UTC') do
        Time.zone.parse(datetime)
      end
    end
    if datetime
      datetime.in_time_zone(account.default_time_zone).iso8601
    else
      nil
    end
  end

# This function will take a datetime string and parse into UTC from the
# root_account's timezone
  def account_time_parse(datetime, account=root_account)
    Time.use_zone(account.default_time_zone) do
      Time.zone.parse datetime.to_s rescue nil
    end
  end

  def account
    @account ||= @account_report.account
  end

  def root_account
    @domain_root_account ||= account.root_account
  end

  def term
    if @account_report.has_parameter? "enrollment_term"
      @term ||= api_find(root_account.enrollment_terms,
                         @account_report.parameters["enrollment_term"])
    end
  end

  def start_at
    if @account_report.has_parameter? "start_at"
      @start ||= account_time_parse(@account_report.parameters["start_at"])
    end
  end

  def end_at
    if @account_report.has_parameter? "end_at"
      @end ||= account_time_parse(@account_report.parameters["end_at"])
    end
  end

  def course
    if @account_report.has_parameter? "course"
      @course ||= api_find(root_account.courses,
                           @account_report.parameters["course"])
    end
  end

  def add_term_scope(scope,table = 'courses')
    if term
      scope.scoped(:conditions => ["#{table}.enrollment_term_id=?", term.id])
    else
      scope
    end
  end

  def add_course_sub_account_scope(scope,table = 'courses')
    if account.id != root_account.id
      scope.scoped(:conditions => ["EXISTS (SELECT course_id
                                            FROM course_account_associations caa
                                            WHERE caa.account_id = ?
                                            AND caa.course_id=#{table}.id
                                            AND caa.course_section_id IS NULL
                                            )", account.id])
    else
      scope
    end
  end

  def add_user_sub_account_scope(scope,table = 'users')
    if account.id != root_account.id
      scope.scoped(:conditions => ["EXISTS (SELECT user_id
                                            FROM user_account_associations uaa
                                            WHERE uaa.account_id = ?
                                            AND uaa.user_id=#{table}.id
                                            )", account.id])
    else
      scope
    end
  end

  def term_name
    term ? term.name : I18n.t(
      'account_reports.default.all_terms', "All Terms"
    )
  end

  def extra_text_term(account_report = @account_report)
    account_report.parameters["extra_text"] = I18n.t(
      'account_reports.default.extra_text_term', "Term: %{term_name};",
      :term_name => term_name
    )
  end

  def send_report(file = nil, account_report = @account_report)
    type = Canvas::AccountReports.for_account(account)[account_report.report_type][:title]
    if account_report.has_parameter? "extra_text"
      options = account_report.parameters["extra_text"]
    end
    Canvas::AccountReports.message_recipient(
      account_report,
      I18n.t(
        'account_reports.default.message',
        "%{type} report successfully generated with the following settings. Account: %{account}; %{options}",
        :type => type, :account => account.name, :options => options),
      file)
  end
end
