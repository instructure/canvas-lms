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

require 'csv'

module AccountReports::ReportHelper
  include ::Api

  def parse_utc_string(datetime)
    if datetime.is_a? String
      Time.use_zone('UTC') { Time.zone.parse(datetime) }
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
    if (datetime = parse_utc_string(datetime))
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
      @term ||= api_find(root_account.enrollment_terms, term_id)
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

  def assignment_group
    if (assignment_group_id = (@account_report.has_parameter? "assignment_group_id") ||
      (@account_report.has_parameter? "assignment_group"))
      @assignment_group = course.assignment_groups.find(assignment_group_id)
    end
  end

  def section
    if section_id = (@account_report.has_parameter? "section_id")
      @section ||= api_find(root_account.course_sections, section_id)
    end
  end

  def add_term_scope(scope, table = 'courses')
    if term
      scope.where(table => {:enrollment_term_id => term})
    else
      scope
    end
  end

  def add_course_scope(scope, table = 'courses')
    if course
      scope.where(table => {:id => course.id})
    else
      scope
    end
  end

  def add_course_sub_account_scope(scope, table = 'courses')
    if account != root_account
      scope.where("EXISTS (SELECT course_id
                           FROM #{CourseAccountAssociation.quoted_table_name} caa
                           WHERE caa.account_id = ?
                           AND caa.course_id=#{table}.id
                           AND caa.course_section_id IS NULL)", account)
    else
      scope
    end
  end

  def add_course_enrollments_scope(scope, table = 'enrollments')
    if course
      scope.where(table => {:course_id => course})
    else
      scope
    end
  end

  def add_user_sub_account_scope(scope, table = 'users')
    if account != root_account
      scope.where("EXISTS (SELECT user_id
                           FROM #{UserAccountAssociation.quoted_table_name} uaa
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

  def loaded_pseudonym(pseudonyms, u, include_deleted: false, enrollment: nil)
    context = enrollment || root_account
    user_pseudonyms = pseudonyms[u.id] || []
    u.instance_variable_set(include_deleted ? :@all_pseudonyms : :@all_active_pseudonyms, user_pseudonyms)
    SisPseudonym.for(u, context, {type: :trusted, require_sis: false, include_deleted: include_deleted})
  end

  def load_cross_shard_logins(users, include_deleted: false)
    shards = root_account.trusted_account_ids.map {|id| Shard.shard_for(id)}
    shards << root_account.shard
    User.preload_shard_associations(users)
    shards = shards & users.map(&:associated_shards).flatten
    pseudonyms = Pseudonym.shard(shards.uniq).where(user_id: users)
    pseudonyms = pseudonyms.active unless include_deleted
    pseudonyms.each do |p|
      p.account = root_account if p.account_id == root_account.id
    end
    preloads = Account.reflections['role_links'] ? {account: :role_links} : :account
    ActiveRecord::Associations::Preloader.new.preload(pseudonyms, preloads)
    pseudonyms.group_by(&:user_id)
  end

  def include_deleted_objects
    if @account_report.has_parameter? "include_deleted"
      @include_deleted = value_to_boolean(@account_report.parameters["include_deleted"])

      if @include_deleted
        add_extra_text(I18n.t('Include Deleted Objects;'))
      end
    end
  end

  def report_title(account_report)
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

  def write_report(headers, &block)
    file = generate_and_run_report(headers, &block)
    Shackles.activate(:master) { send_report(file) }
  end

  def generate_and_run_report(headers = nil, extension = 'csv')
    file = AccountReports.generate_file(@account_report, extension)
    ExtendedCSV.open(file, "w") do |csv|
      csv.instance_variable_set(:@account_report, @account_report)
      csv << headers unless headers.nil?
      Shackles.activate(:slave) { yield csv } if block_given?
      @account_report.update_attribute(:current_line, csv.lineno)
    end
    file
  end

  # to use write_report_in_batches you need the following
  # 1. create account_report_runners with batch_items populated with the ids
  #    that will run for the batch. Example would be doing something with
  #    courses and you would pass 1_000 course_ids to the runner or you could
  #    pass enrollment_term_ids to each runner
  # 2. have a method named parallel_#{report_type}
  # 3. the parallel_#{report_type} method will need to know what to do with the
  #    strings or ids in the account_report_runner.batch_items.
  #    batch_items is an array of strings.
  #    in the example with courses it would run the report for the ids or for
  #    the enrollment_term_id the query could use the id and get the results for
  #    the term.
  # 4. the parallel_#{report_type} will also need to add rows individually with
  #    add_report_row or a little more efficient way would be to use
  #    build_report_row, and then add_report_rows at the end of the method.
  def write_report_in_batches(headers)
    # we use total_lines to track progress in the normal progress.
    # just use it here to do the same thing here even though it is not really
    # the number of lines.
    total_runners = @account_report.account_report_runners.count

    # If there are no runners, short-circuit and just send back an empty report with headers only.
    # Otherwise, the report will get stuck in a "running" state and never exit.
    if total_runners == 0
      write_report(headers)
      return
    end

    @account_report.update_attributes(total_lines: total_runners)

    args = {priority: Delayed::LOW_PRIORITY, max_attempts: 1, n_strand: ["account_report_runner", root_account.global_id]}
    @account_report.account_report_runners.find_each do |runner|
      self.send_later_enqueue_args(:run_account_report_runner, args, runner, headers)
    end
  end

  def add_report_row(row:, row_number: nil, report_runner:, account_report: @account_report)
    Shackles.activate(:master) do
      account_report.account_report_rows.create!(row: row,
                                                 row_number: row_number,
                                                 account_report: account_report,
                                                 account_report_runner: report_runner,
                                                 created_at: Time.zone.now)
    end
  end

  def run_account_report_runner(report_runner, headers)
    return if report_runner.reload.workflow_state == 'aborted'
    @account_report = report_runner.account_report
    begin
      if @account_report.workflow_state == 'aborted'
        report_runner.abort
        return
      end
      report_runner.start
      Shackles.activate(:slave) {AccountReports::REPORTS[@account_report.report_type].parallel_proc.call(@account_report, report_runner)}
      update_parallel_progress(account_report: @account_report,report_runner: report_runner)
    rescue => e
      report_runner.fail
      self.fail_with_error(e)
    ensure
      if last_account_report_runner?(@account_report)
        write_report headers do |csv|
          @account_report.account_report_rows.order(:account_report_runner_id, :row_number).find_each {|record| csv << record.row}
        end
        # total lines was used to track progress but was not accurate.
        @account_report.update_attributes(total_lines: @account_report.current_line)
        @account_report.delete_account_report_rows
      end
    end
  end

  def fail_with_error(error)
    Shackles.activate(:master) do
      @account_report.account_report_runners.incomplete.update_all(workflow_state: 'aborted')
      @account_report.delete_account_report_rows
      Canvas::Errors.capture_exception(:account_report, error)
      @account_report.workflow_state = 'error'
      @account_report.save!
      raise error
    end
  end

  def runner_aborted?(report_runner)
    if report_runner.reload.workflow_state == 'aborted'
      report_runner.delete_account_report_rows
      true
    else
      false
    end
  end

  def update_parallel_progress(account_report: @account_report, report_runner:)
    return if runner_aborted?(report_runner)
    report_runner.complete
    # let the regular report process update progress to 100 percent, cap at 99.
    progress = [(account_report.account_report_runners.completed.count.to_f/account_report.total_lines * 100).to_i, 99].min
    current_line = account_report.account_report_rows.count
    account_report.current_line ||= 0
    account_report.progress ||= 0
    updates = {}
    updates[:current_line] = current_line if account_report.current_line < current_line
    updates[:progress] = progress if account_report.progress < progress
    unless updates.empty?
      Shackles.activate(:master) do
        AccountReport.where(id: account_report).where("progress <?", progress).update_all(updates)
      end
    end
  end

  def last_account_report_runner?(account_report)
    return false if account_report.account_report_runners.incomplete.exists?
    AccountReport.transaction do
      @account_report.reload(lock: true)
      return false if account_report.workflow_state == 'error'
      if @account_report.workflow_state == 'running'
        @account_report.workflow_state = 'compiling'
        @account_report.save!
        true
      else
        false
      end
    end
  end

  class ExtendedCSV < CSV
    def <<(row)
      if @lineno % 1_000 == 0
        Shackles.activate(:master) do
          report = self.instance_variable_get(:@account_report).reload
          updates = {}
          updates[:current_line] = @lineno
          updates[:progress] = (@lineno.to_f / report.total_lines * 100).to_i if report.total_lines
          report.update_attributes(updates)
          if report.workflow_state == 'deleted'
            report.workflow_state = 'aborted'
            report.save!
            raise 'aborted'
          end
        end
      end
      super(row)
    end
  end

  def read_csv_in_chunks(filename, chunk_size = 1000)
    CSV.open(filename) do |csv|
      rows = []
      while (!(row = csv.readline).nil?)
        rows << row
        if rows.size == chunk_size
          yield rows
          rows = []
        end
      end
      yield rows unless rows.empty?
    end
  end

  def add_extra_text(text)
    if @account_report.has_parameter?('extra_text')
      @account_report.parameters["extra_text"] << " #{text}"
    else
      @account_report.parameters["extra_text"] = text
    end
    Shackles.activate(:master) do
      @account_report.save!
    end
  end

end
