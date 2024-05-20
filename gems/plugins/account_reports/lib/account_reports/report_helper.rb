# frozen_string_literal: true

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

module AccountReports::ReportHelper
  include ::Api

  class DatabaseReplicationError < StandardError; end

  def parse_utc_string(datetime)
    if datetime.is_a? String
      Time.use_zone("UTC") { Time.zone.parse(datetime) }
    else
      datetime
    end
  end

  # This function will take a datetime or a datetime string and convert into
  # iso8601 for the root_account's timezone
  # A string datetime needs to be in UTC
  def default_timezone_format(datetime, account = root_account)
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
  def timezone_strftime(datetime, format, account = root_account)
    if (datetime = parse_utc_string(datetime))
      datetime.in_time_zone(account.default_time_zone).strftime(format)
    end
  end

  # This function will take a datetime string and parse into UTC from the
  # root_account's timezone
  def account_time_parse(datetime, account = root_account)
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
    if (term_id = @account_report.value_for_param("enrollment_term_id") || @account_report.value_for_param("enrollment_term"))
      @term ||= api_find(root_account.enrollment_terms, term_id)
    end
  end

  def datetime_from_param(param)
    if @account_report.value_for_param(param)
      account_time_parse(@account_report.parameters[param])
    end
  end

  def restricted_datetime_from_param(param, earliest: nil, latest: nil, fallback: nil)
    time = datetime_from_param(param)
    return fallback if time.nil? && fallback
    return unless time

    time = earliest if earliest&.> time
    time = latest if latest&.< time
    time
  end

  def start_at
    @start ||= datetime_from_param("start_at")
  end

  def end_at
    @end ||= datetime_from_param("end_at")
  end

  def course
    if (course_id = @account_report.value_for_param("course_id") || @account_report.value_for_param("course"))
      @course ||= api_find(root_account.all_courses, course_id)
    end
  end

  def assignment_group
    if (assignment_group_id = @account_report.value_for_param("assignment_group_id") ||
      @account_report.value_for_param("assignment_group"))
      @assignment_group = course.assignment_groups.find(assignment_group_id)
    end
  end

  def section
    if (section_id = @account_report.value_for_param("section_id"))
      @section ||= api_find(root_account.course_sections, section_id)
    end
  end

  def add_term_scope(scope, table = "courses")
    if term
      scope.where(table => { enrollment_term_id: term })
    else
      scope
    end
  end

  def add_course_scope(scope, table = "courses")
    if course
      scope.where(table => { id: course.id })
    else
      scope
    end
  end

  def add_course_sub_account_scope(scope, table = "courses")
    if account == root_account
      scope
    else
      scope.where(<<~SQL.squish, account)
        EXISTS (SELECT course_id
                FROM #{CourseAccountAssociation.quoted_table_name} caa
                WHERE caa.account_id = ?
                AND caa.course_id=#{table}.id
                AND caa.course_section_id IS NULL)
      SQL
    end
  end

  def add_course_enrollments_scope(scope, table = "enrollments")
    if course
      scope.where(table => { course_id: course })
    else
      scope
    end
  end

  def add_user_sub_account_scope(scope, table = "users")
    if account == root_account
      scope
    else
      scope.where("EXISTS (SELECT user_id
                           FROM #{UserAccountAssociation.quoted_table_name} uaa
                           WHERE uaa.account_id = ?
                           AND uaa.user_id=#{table}.id)",
                  account)
    end
  end

  def term_name
    if term
      term.name
    else
      I18n.t(
        "account_reports.default.all_terms", "All Terms"
      )
    end
  end

  def extra_text_term(account_report = @account_report)
    account_report.parameters ||= {}
    add_extra_text(I18n.t("account_reports.default.extra_text_term", "Term: %{term_name};", term_name:))
  end

  def check_report_key(key)
    AccountReports.available_reports[@account_report.report_type].parameters.key? key
  end

  def report_extra_text
    if check_report_key(:enrollment_term_id)
      add_extra_text(I18n.t("account_reports.default.term_text",
                            "Term: %{term_name};",
                            term_name:))
    end

    if start_at && check_report_key(:start_at)
      add_extra_text(I18n.t("account_reports.default.start_text",
                            "Start At: %{start_at};",
                            start_at: default_timezone_format(start_at)))
    end

    if end_at && check_report_key(:end_at)
      add_extra_text(I18n.t("account_reports.default.end_text",
                            "End At: %{end_at};",
                            end_at: default_timezone_format(end_at)))
    end

    if course && check_report_key(:course_id)
      add_extra_text(I18n.t("account_reports.default.course_text",
                            "For Course: %{course};",
                            course: course.id))
    end

    if section && check_report_key(:section_id)
      add_extra_text(I18n.t("account_reports.default.section_text",
                            "For Section: %{section};",
                            section: section.id))
    end
  end

  def loaded_pseudonym(pseudonyms, user, include_deleted: false, enrollment: nil)
    user_pseudonyms = pseudonyms[user.id] || []
    user.instance_variable_set(include_deleted ? :@all_pseudonyms : :@all_active_pseudonyms, user_pseudonyms)
    if enrollment&.sis_pseudonym_id
      enrollment_pseudonym = user_pseudonyms.index_by(&:id)[enrollment.sis_pseudonym_id]
      return enrollment_pseudonym if enrollment_pseudonym && (enrollment_pseudonym.workflow_state != "deleted" || include_deleted)
    end
    SisPseudonym.for(user, root_account, type: :trusted, require_sis: false, include_deleted:, root_account:)
  end

  def preload_logins_for_users(users, include_deleted: false)
    shards = root_account.trusted_account_ids.map { |id| Shard.shard_for(id) }
    shards << root_account.shard
    User.preload_shard_associations(users)
    shards &= users.map(&:associated_shards).flatten
    pseudonyms = Pseudonym.shard(shards.uniq).where(user_id: users.map(&:id))
    pseudonyms = pseudonyms.active unless include_deleted
    pseudonyms.each do |p|
      p.account = root_account if p.account_id == root_account.id
    end
    preloads = Account.reflections["role_links"] ? { account: :role_links } : :account
    ActiveRecord::Associations.preload(pseudonyms, preloads)
    pseudonyms.group_by(&:user_id)
  end

  def emails_by_user_id(user_ids)
    Shard.partition_by_shard(user_ids) do |shard_user_ids|
      CommunicationChannel
        .email
        .unretired
        .select([:user_id, :path])
        .where(user_id: shard_user_ids)
        .order("user_id, position ASC")
        .distinct_on(:user_id)
    end.index_by(&:user_id)
  end

  def include_deleted_objects
    if @account_report.value_for_param "include_deleted"
      @include_deleted = value_to_boolean(@account_report.parameters["include_deleted"])

      if @include_deleted
        add_extra_text(I18n.t("Include Deleted Objects;"))
      end
    end
  end

  def include_enrollment_filter
    if @account_report.value_for_param "enrollment_filter"
      @enrollment_filter = Enrollment.valid_types & Api.value_to_array(@account_report.parameters["enrollment_filter"])
      if @enrollment_filter
        add_extra_text("Include Enrollment Roles: #{@enrollment_filter.to_sentence};")
      end
    end
  end

  def include_enrollment_states
    if @account_report.value_for_param "enrollment_states"
      @enrollment_states = valid_enrollment_workflow_states
      if @enrollment_states
        add_extra_text("Include Enrollment States: #{@enrollment_states.to_sentence};")
      end
    end
  end

  def valid_enrollment_workflow_states
    %w[invited creation_pending active completed inactive deleted rejected].freeze &
      Api.value_to_array(@account_report.parameters["enrollment_states"])
  end

  def report_title(account_report)
    AccountReports.available_reports[account_report.report_type].title
  end

  def send_report(file = nil, account_report = @account_report)
    type = report_title(account_report)
    if account_report.value_for_param "extra_text"
      options = account_report.parameters["extra_text"]
    end
    AccountReports.finalize_report(
      account_report,
      I18n.t(
        "account_reports.default.message",
        "%{type} report successfully generated with the following settings. Account: %{account}; %{options}",
        type:,
        account: account.name,
        options:
      ),
      file
    )
  end

  def write_report(headers, enable_i18n_features = false, replica = :report, &)
    file = generate_and_run_report(headers, "csv", enable_i18n_features, replica, &)
    GuardRail.activate(:primary) { send_report(file) }
  end

  def generate_and_run_report(headers = nil, extension = "csv", enable_i18n_features = false, replica = :report)
    file = AccountReports.generate_file(@account_report, extension)
    options = {}
    if enable_i18n_features
      options = CSVWithI18n.csv_i18n_settings(@account_report.user)
    end
    ExtendedCSV.open(file, "w", **options) do |csv|
      csv.instance_variable_set(:@account_report, @account_report)
      csv << headers unless headers.nil?
      activate_report_db(replica:) { yield csv } if block_given?
      GuardRail.activate(:primary) { @account_report.update_attribute(:current_line, csv.lineno) }
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
  #    add_report_row.
  # files param is used if you need to have multiple files in a zip file report.
  # files is a hash of filenames and headers for the file.
  # { 'file_name' => ['header', 'row', 'goes', 'here'], 'file_two' => ['other', 'header'] }
  # for files to work, the rows need to populate the file the row belongs to.
  def write_report_in_batches(headers, files: nil)
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

    @account_report.update(total_lines: total_runners)

    args = { priority: Delayed::LOW_PRIORITY, n_strand: ["account_report_runner", root_account.global_id] }
    # allow retries if account report runner fails
    args[:max_attempts] = 2 if root_account.feature_enabled?(:custom_report_experimental)
    @account_report.account_report_runners.find_each do |runner|
      delay(**args).run_account_report_runner(runner, headers, files:)
    end
  end

  def add_report_row(row:, row_number: nil, report_runner:, file: nil)
    report_runner.rows << build_report_row(row:, row_number:, report_runner:, file:)
    if report_runner.rows.length == 1_000
      report_runner.write_rows
    end
  end

  def build_report_row(row:, row_number: nil, report_runner:, file: nil)
    report_runner.shard.activate do
      # force all fields to strings
      AccountReportRow.new(row: row.map { |field| field&.to_s&.encode(Encoding::UTF_8) },
                           row_number:,
                           file:,
                           account_report_id: report_runner.account_report_id,
                           account_report_runner_id: report_runner.id,
                           created_at: Time.zone.now)
    end
  end

  def number_of_items_per_runner(item_count, min: 25, max: 1000)
    # use 100 jobs for the report, but no fewer than 25, and no more than 1000 per job
    (item_count / 99.to_f).round(0).clamp(min, max)
  end

  def create_report_runners(ids, total, min: 25, max: 1000)
    return if ids.empty?

    ids_so_far = 0
    ids.each_slice(number_of_items_per_runner(total, min:, max:)) do |batch|
      @account_report.add_report_runner(batch)
      ids_so_far += batch.length
      if ids_so_far >= Setting.get("ids_per_report_runner_batch", 10_000).to_i
        GuardRail.activate(:primary) { @account_report.write_report_runners }
        ids_so_far = 0
      end
    end
    GuardRail.activate(:primary) { @account_report.write_report_runners }
  end

  def activate_report_db(replica: :report, &block)
    # if there is no report db configured, use the secondary.
    # Rails 6.1 - Shard.current.database_server.roles will be set.
    # It is not set in older versions of Rails.
    Shard.current.database_server.tap do |ds|
      if (ds.respond_to?(:roles) && ds.roles.include?(replica)) || ds.config[replica]
        GuardRail.activate(replica, &block)
      else
        GuardRail.activate(:secondary, &block)
      end
    end
  end

  def run_account_report_runner(report_runner, headers, files: nil)
    return if report_runner.reload.workflow_state == "aborted"

    @account_report = report_runner.account_report
    begin
      if @account_report.aborted? || @account_report.deleted? || @account_report.error?
        report_runner.abort
        return
      end
      # runners can be completed before they get here, and we should not try to process them.
      unless report_runner.workflow_state == "completed"
        report_runner.start
        activate_report_db { AccountReports::REPORTS[@account_report.report_type].parallel_proc.call(@account_report, report_runner) }
      end
    rescue => e
      report_runner.fail
      fail_with_error(e)
    ensure
      update_parallel_progress(account_report: @account_report, report_runner:)
      compile_parallel_report(report_runner, headers, files:) if last_account_report_runner?(@account_report)
    end
  end

  def compile_parallel_report(report_runner, headers, files: nil)
    GuardRail.activate(:primary) { @account_report.update(total_lines: @account_report.account_report_rows.count + 1) }
    xlog_location = AccountReport.current_xlog_location
    # wait 2 minutes for report db to catch up, if it does not catch up, use the
    # secondary db when it is caught up.
    replica = if AccountReport.wait_for_replication(start: xlog_location, timeout: 120, use_report: true)
                :report
              elsif AccountReport.wait_for_replication(start: xlog_location, timeout: 30.minutes)
                :secondary
              else
                raise DatabaseReplicationError, "Replica failed to catch up in the allotted time"
              end
    files ? compile_parallel_zip_report(files, replica:) : write_report_from_rows(headers, replica:)
  rescue => e
    report_runner.fail
    fail_with_error(e)
  ensure
    GuardRail.activate(:primary) { @account_report.delete_account_report_rows }
  end

  def write_report_from_rows(headers, replica: :report)
    activate_report_db(replica:) do
      write_report(headers, false, replica) do |csv|
        @account_report.account_report_rows.order(:account_report_runner_id, :row_number)
                       .find_in_batches(strategy: :cursor) do |batch|
          batch.each { |record| csv << record.row }
        end
      end
    end
  end

  def compile_parallel_zip_report(files, replica: :report)
    csvs = {}
    activate_report_db(replica:) do
      files.each do |file, headers_for_file|
        csvs[file] = if @account_report.account_report_rows.where(file:).exists?
                       generate_and_run_report(headers_for_file, "csv", false, replica) do |csv|
                         @account_report.account_report_rows.where(file:)
                                        .order(:account_report_runner_id, :row_number)
                                        .find_in_batches(strategy: :cursor) do |batch|
                           batch.each { |record| csv << record.row }
                         end
                       end
                     else
                       generate_and_run_report(headers_for_file, "csv", false, replica)
                     end
      end
    end
    send_report(csvs)
  end

  def fail_with_error(error)
    GuardRail.activate(:primary) do
      Canvas::Errors.capture_exception(:account_report, error)
      @account_report.workflow_state = "error"
      @account_report.save!
      raise error
    end
  end

  def runner_aborted?(report_runner)
    if report_runner.reload.workflow_state == "aborted"
      report_runner.delete_account_report_rows
      true
    else
      false
    end
  end

  def update_parallel_progress(account_report: @account_report, report_runner:)
    return if runner_aborted?(report_runner) || report_runner.error?

    report_runner.complete
    # let the regular report process update progress to 100 percent, cap at 99.
    progress = [(account_report.account_report_runners.completed.count.to_f / account_report.total_lines * 100).to_i, 99].min
    current_line = account_report.account_report_rows.count
    account_report.current_line ||= 0
    account_report.progress ||= 0
    updates = {}
    updates[:current_line] = current_line if account_report.current_line < current_line
    updates[:progress] = progress if account_report.progress < progress
    unless updates.empty?
      GuardRail.activate(:primary) do
        AccountReport.where(id: account_report).where("progress <?", progress).update_all(updates)
      end
    end
  end

  def last_account_report_runner?(account_report)
    return false if account_report.account_report_runners.incomplete_or_failed.exists?

    AccountReport.transaction do
      @account_report.reload(lock: true)
      if @account_report.workflow_state == "running"
        @account_report.workflow_state = "compiling"
        @account_report.save!
        true
      else
        false
      end
    end
  end

  class ExtendedCSV < CSVWithI18n
    def <<(row)
      if lineno % 1_000 == 0
        GuardRail.activate(:primary) do
          report = instance_variable_get(:@account_report).reload
          updates = {}
          updates[:current_line] = lineno
          updates[:progress] = (lineno.to_f / (report.total_lines + 1) * 100).to_i if report.total_lines
          report.update(updates)
          if report.workflow_state == "deleted"
            report.workflow_state = "aborted"
            report.save!
            raise "aborted"
          end
        end
      end
      super(row)
    end
  end

  def read_csv_in_chunks(filename, chunk_size = 1000)
    CSV.open(filename) do |csv|
      rows = []
      until (row = csv.readline).nil?
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
    if @account_report.value_for_param("extra_text")
      @account_report.parameters["extra_text"] << " #{text}"
    else
      @account_report.parameters["extra_text"] = text
    end
    GuardRail.activate(:primary) do
      @account_report.save!
    end
  end
end
