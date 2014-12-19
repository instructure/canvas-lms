#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

require 'csv'

module AccountReports::ReportHelper
  include ::Api

  def parse_utc_string(datetime)
    if datetime.is_a? String
      Time.use_zone('UTC') {Time.zone.parse(datetime)}
    else
      datetime
    end
  end

# This function will take a datetime or a datetime string and convert into
# iso8601 for the root_account's timezone
# A string datetime needs to be in UTC
  def default_timezone_format(datetime, account=root_account)
    datetime = parse_utc_string(datetime)
    if datetime
      datetime.in_time_zone(account.default_time_zone).iso8601
    else
      nil
    end
  end

  # This function will take a datetime or a datetime string and convert into
  # strftime for the root_account's timezone
  # it will then format the datetime using the given format string
  def timezone_strftime(datetime, format, account=root_account)
    if datetime = parse_utc_string(datetime)
      (datetime.in_time_zone(account.default_time_zone)).strftime(format)
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
    if (term_id = (@account_report.has_parameter? "enrollment_term_id") || (@account_report.has_parameter? "enrollment_term"))
      @term ||= api_find(root_account.enrollment_terms,term_id)
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
    if (course_id = (@account_report.has_parameter? "course_id") || (@account_report.has_parameter? "course"))
      @course ||= api_find(root_account.all_courses, course_id)
    end
  end

  def section
    if section_id = (@account_report.has_parameter? "section_id")
      @section ||= api_find(root_account.course_sections, section_id)
    end
  end

  def add_term_scope(scope,table = 'courses')
    if term
      scope.where(table => { :enrollment_term_id => term })
    else
      scope
    end
  end

  def add_course_sub_account_scope(scope,table = 'courses')
    if account != root_account
      scope.where("EXISTS (SELECT course_id
                           FROM course_account_associations caa
                           WHERE caa.account_id = ?
                           AND caa.course_id=#{table}.id
                           AND caa.course_section_id IS NULL)", account)
    else
      scope
    end
  end

  def add_course_enrollments_scope(scope,table = 'enrollments')
    if course
      scope.where(table => { :course_id => course })
    else
      scope
    end
  end

  def add_user_sub_account_scope(scope,table = 'users')
    if account != root_account
      scope.where("EXISTS (SELECT user_id
                           FROM user_account_associations uaa
                           WHERE uaa.account_id = ?
                           AND uaa.user_id=#{table}.id)", account)
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
    account_report.parameters ||= {}
    add_extra_text(I18n.t(
      'account_reports.default.extra_text_term', "Term: %{term_name};",
      :term_name => term_name
    ))
  end

  def check_report_key(key)
    AccountReports.available_reports[@account_report.report_type][:parameters].keys.include? key
  end

  def report_extra_text
    if check_report_key(:enrollment_term_id)
      add_extra_text(I18n.t('account_reports.default.term_text', "Term: %{term_name};",
                       :term_name => term_name))
    end

    if start_at && check_report_key(:start_at)
      add_extra_text(I18n.t('account_reports.default.start_text',
                            "Start At: %{start_at};", :start_at => default_timezone_format(start_at)))
    end

    if end_at && check_report_key(:end_at)
      add_extra_text(I18n.t('account_reports.default.end_text',
                            "End At: %{end_at};", :end_at => default_timezone_format(end_at)))
    end

    if course && check_report_key(:course_id)
      add_extra_text(I18n.t('account_reports.default.course_text',
                            "For Course: %{course};", :course => course.id))
    end

    if section && check_report_key(:section_id)
      add_extra_text(I18n.t('account_reports.default.section_text',
                            "For Section: %{section};", :section => section.id))
    end
  end

  def report_title(account_report )
    AccountReports.available_reports[account_report.report_type].title
  end

  def send_report(file = nil, account_report = @account_report)
    type = report_title(account_report)
    if account_report.has_parameter? "extra_text"
      options = account_report.parameters["extra_text"]
    end
    AccountReports.message_recipient(
      account_report,
      I18n.t(
        'account_reports.default.message',
        "%{type} report successfully generated with the following settings. Account: %{account}; %{options}",
        :type => type, :account => account.name, :options => options),
      file)
  end

  def write_report(headers)
    file = AccountReports.generate_file(@account_report)
    CSV.open(file, "w") do |csv|
      csv << headers
      yield csv
    end
    Shackles.activate(:master) do
      send_report(file)
    end
  end

  def add_extra_text(text)
    if @account_report.has_parameter?('extra_text')
      @account_report.parameters["extra_text"] << " #{text}"
    else
      @account_report.parameters["extra_text"] = text
    end
  end

end
