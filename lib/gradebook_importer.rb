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

class GradebookImporter
  ASSIGNMENT_PRELOADED_FIELDS = %i/
    id title points_possible grading_type updated_at context_id context_type group_category_id
    created_at due_at only_visible_to_overrides
  /.freeze

  class NegativeId
    class << self
      def generate
        instance.next
      end

      def instance
        @@inst ||= new
      end
    end
    def next
      @i ||= 0
      @i -= 1
    end
  end

  class InvalidHeaderRow < StandardError; end

  attr_reader :context, :contents, :attachment, :assignments, :students,
              :submissions, :missing_assignments, :missing_students, :upload

  def self.create_from(progress, gradebook_upload, user, attachment)
    self.new(gradebook_upload, attachment, user, progress).parse!
  end

  def initialize(upload=nil, attachment=nil, user=nil, progress=nil)
    @upload = upload
    @context = upload.course

    raise ArgumentError, "Must provide a valid context for this gradebook." unless valid_context?(@context)
    raise ArgumentError, "Must provide attachment." unless attachment

    @user = user
    @attachment = attachment
    @progress = progress

    @visible_assignments = AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(
      course_id: @context.id, user_id: @context.all_students.pluck(:id)
    )
  end

  CSV::Converters[:nil] = lambda do |e|
    begin
      e.nil? ? e : raise
    rescue
      e
    end
  end

  CSV::Converters[:decimal_comma_to_period] = -> (field) do
    if field =~ /^-?[0-9.,]+%?$/
      # This field is a pure number or percentage => let's normalize it
      number_parts = field.split(/[,.]/)
      last_number_part = number_parts.pop

      if number_parts.empty?
        last_number_part
      else
        [number_parts.join(), last_number_part].join('.')
      end
    else
      field
    end
  end

  def parse!
    # preload a ton of data that presumably we'll be querying
    @context.preload_user_roles!
    @all_assignments = @context.assignments
      .preload({ context: :account })
      .published
      .gradeable
      .select(ASSIGNMENT_PRELOADED_FIELDS)
      .index_by(&:id)
    @all_students = @context.all_students
      .select(['users.id', :name, :sortable_name, 'users.updated_at'])
      .index_by(&:id)

    @assignments = nil
    @root_accounts = {}
    @pseudonyms_by_sis_id = {}
    @pseudonyms_by_login_id = {}
    @students = []
    @pp_row = []
    @warning_messages = {
      prevented_new_assignment_creation_in_closed_period: false,
      prevented_grading_ungradeable_submission: false
    }

    begin
      csv_stream do |row|
        already_processed = check_for_non_student_row(row)
        unless already_processed
          @students << process_student(row)
          process_submissions(row, @students.last)
        end
      end
    rescue InvalidHeaderRow
      @progress.message = "Invalid header row"
      @progress.workflow_state = "failed"
      @progress.save
      return
    end

    @missing_assignments = []
    @missing_assignments = @all_assignments.values - @assignments if @missing_assignment
    @missing_students = []
    @missing_students = @all_students.values - @students if @missing_student

    # look up existing score for everything that was provided
    assignment_ids = @missing_assignment ? @all_assignments.values : @assignments
    user_ids = @missing_student ? @all_students.values : @students
    # preload periods to avoid N+1s
    periods = GradingPeriod.for(@context)
    # preload is_admin to avoid N+1
    is_admin = @context.account_membership_allows(@user)
    # Preload effective due dates to avoid N+1s
    effective_due_dates = EffectiveDueDates.for_course(@context, @all_assignments.values)

    @original_submissions = @context.submissions
      .preload(:grading_period, assignment: { context: :account })
      .select(['submissions.id', :assignment_id, :user_id, :grading_period_id, :score, :excused, :cached_due_date, 'submissions.updated_at'])
      .where(assignment_id: assignment_ids, user_id: user_ids)
      .map do |submission|
        is_gradeable = gradeable?(submission: submission, is_admin: is_admin)
        score = submission.excused? ? "EX" : submission.score.to_s
        {
          user_id: submission.user_id,
          assignment_id: submission.assignment_id,
          score: score,
          gradeable: is_gradeable
        }
      end

    # cache the score on the existing object
    original_submissions_by_student = @original_submissions.inject({}) do |r, s|
      r[s[:user_id]] ||= {}
      r[s[:user_id]][s[:assignment_id]] ||= {}
      r[s[:user_id]][s[:assignment_id]][:score] = s[:score]
      r[s[:user_id]][s[:assignment_id]][:gradeable] = s[:gradeable]
      r
    end

    @students.each do |student|
      student.gradebook_importer_submissions.each do |submission|
        submission_assignment_id = submission.fetch('assignment_id').to_i
        assignment = original_submissions_by_student.
          fetch(student.id, {}).
          fetch(submission_assignment_id, {})
        submission['original_grade'] = assignment.fetch(:score, nil)
        submission['gradeable'] = assignment.fetch(:gradable, nil)

        if submission.fetch('gradeable').nil?
          assignment = @all_assignments[submission['assignment_id']] || @context.assignments.build
          new_submission = Submission.new
          new_submission.user = student
          new_submission.assignment = assignment
          edd = effective_due_dates.find_effective_due_date(student.id, assignment.id)
          new_submission.cached_due_date = edd.fetch(:due_at, nil)
          new_submission.grading_period_id = edd.fetch(:grading_period_id, nil)
          submission['gradeable'] = !edd.fetch(:in_closed_grading_period, false) && gradeable?(
            submission: new_submission,
            is_admin: is_admin
          )
        end
      end
    end

    translate_pass_fail(@assignments, @students)

    unless @missing_student
      # weed out assignments with no changes
      indexes_to_delete = []
      @assignments.each_with_index do |assignment, idx|
        next if assignment.changed? && !readonly_assignment?(idx)
        indexes_to_delete << idx if readonly_assignment?(idx) || @students.all? do |student|
          submission = student.gradebook_importer_submissions[idx]

          # Have potentially mixed case excused in grade match case
          # expectations for the compare so it doesn't look changed
          submission['grade'] = 'EX' if submission['grade'].to_s.upcase == 'EX'
          no_change = submission['grade'] == submission['original_grade'] ||
            (submission['original_grade'].present? && submission['grade'].present? && submission['original_grade'].to_f == submission['grade'].to_f) ||
            (submission['original_grade'].blank? && submission['grade'].blank?)

          if !submission['gradeable'] && !no_change
            @warning_messages[:prevented_grading_ungradeable_submission] = true
          end

          no_change || !submission['gradeable']
        end
      end

      indexes_to_delete.reverse_each do |idx|
        @assignments.delete_at(idx)
        @students.each do |student|
          student.gradebook_importer_submissions.delete_at(idx)
        end
      end

      @students.each do |student|
        student.gradebook_importer_submissions.select! { |sub| sub['gradeable'] }
      end

      @unchanged_assignments = !indexes_to_delete.empty?
      @students = [] if @assignments.empty?
    end

    # remove concluded enrollments
    prior_enrollment_ids = (
      @all_students.keys - @context.gradable_students.pluck(:user_id).map(&:to_i)
    ).to_set
    @students.delete_if { |s| prior_enrollment_ids.include? s.id }

    @original_submissions = [] unless @missing_student || @missing_assignment

    if prevent_new_assignment_creation?(periods, is_admin)
      @assignments.delete_if do |assignment|
        new_assignment = assignment.new_record?
        if new_assignment
          @warning_messages[:prevented_new_assignment_creation_in_closed_period] = true
        end
        new_assignment
      end
    end

    @upload.gradebook = self.as_json
    @upload.save!
  end

  def translate_pass_fail(assignments, students)
    assignments.each_with_index do |assignment, idx|
      next unless assignment.grading_type == "pass_fail"
      students.each do |student|
        submission = student.gradebook_importer_submissions[idx]
        if submission['grade'].present?
          submission['grade'] = assignment.score_to_grade(submission['grade'],
                                                          submission['grade'])
        end
        if submission['original_grade'].present?
          submission['original_grade'] =
            assignment.score_to_grade(submission['original_grade'],
                                      submission['original_grade'])
        end
      end
    end
  end

  def process_header(row)
    raise InvalidHeaderRow unless header?(row)

    row = strip_non_assignment_columns(row)
    parse_assignments(row) # requires non-assignment columns to be stripped
  end

  def header?(row)
    return false unless row_has_student_headers? row

    update_column_count row

    return false if last_student_info_column(row) !~ /Section/

    true
  end

  def last_student_info_column(row)
    row[@student_columns - 1]
  end

  def row_has_student_headers?(row)
    row.length > 3 && row[0] =~ /Student/ && row[1] =~ /ID/
  end

  def update_column_count(row)
    # A side effect that's necessary to finish validation, but needs to come
    # after the row.length check above.
    @student_columns = 3 # name, user id, section
    if row[2] =~ /SIS\s+Login\s+ID/
      @sis_login_id_column = 2
      @student_columns += 1
    elsif row[2] =~ /SIS\s+User\s+ID/ && row[3] =~ /SIS\s+Login\s+ID/
      @sis_user_id_column = 2
      @sis_login_id_column = 3
      @student_columns += 2
      if row[4] =~ /Root\s+Account/
        @student_columns +=1
        @root_account_column = 4
      end
    end
  end

  def strip_non_assignment_columns(row)
    drop_student_information_columns(row)

    # This regex will also include columns for unposted scores, which
    # will be one of these values with "Unposted" prepended.
    while row.last =~ /Current Score|Current Points|Current Grade|Final Score|Final Points|Final Grade/
      row.pop
    end

    row
  end

  def drop_student_information_columns(row)
    row.shift(@student_columns)
  end

  # this method requires non-assignment columns to be stripped from the row
  def parse_assignments(stripped_row)
    stripped_row.map do |name_and_id|
      title, id = Assignment.title_and_id(name_and_id)
      assignment = @all_assignments[id.to_i] if id.present?
      # backward compat
      assignment ||= @all_assignments.find { |_id, a| a.title == name_and_id }
        .try(:last)
      assignment ||= Assignment.new(:title => title || name_and_id)
      assignment.previous_id = assignment.id
      assignment.id ||= NegativeId.generate

      @missing_assignment ||= assignment.new_record?
      assignment
    end.compact
  end

  def prevent_new_assignment_creation?(periods, is_admin)
    return false unless @context.grading_periods?
    return false if is_admin

    GradingPeriod.date_in_closed_grading_period?(
      course: @context,
      date: nil,
      periods: periods
    )
  end

  def process_pp(row)
    @pp_row = row
    @assignments.each_with_index do |assignment, idx|
      assignment.points_possible = row[idx] if row[idx]
    end
  end

  def process_student(row)
    student_id = row[1] # the second column in the csv should have the student_id for each row
    student = @all_students[student_id.to_i] if student_id.present?
    unless student
      ra_sis_id = row[@root_account_column].presence if @root_account_column
      unless @root_accounts.key?(ra_sis_id)
        ra = ra_sis_id.nil? ? @context.root_account : Account.find_by_domain(ra_sis_id)
        add_root_account_to_pseudonym_cache(ra) if ra
        @root_accounts[ra_sis_id] = ra
      end
      ra = @root_accounts[ra_sis_id]
      if ra && @sis_user_id_column && row[@sis_user_id_column].present?
        sis_user_id = [ra.id, row[@sis_user_id_column]]
      end
      if ra && @sis_login_id_column && row[@sis_login_id_column].present?
        sis_login_id = [ra.id, row[@sis_login_id_column]]
      end
      pseudonym = @pseudonyms_by_sis_id[sis_user_id] if sis_user_id
      pseudonym ||= @pseudonyms_by_login_id[sis_login_id] if sis_login_id
      student = @all_students[pseudonym.user_id] if pseudonym
    end
    if row[0].present?
      student ||= @all_students.find do |_id, s|
        s.name == row[0] || s.sortable_name == row[0]
      end.try(:last)
    end
    student ||= User.new(:name => row[0])
    student.previous_id = student.id
    student.id ||= NegativeId.generate
    @missing_student ||= student.new_record?
    student
  end

  def process_submissions(row, student)
    importer_submissions = []
    @assignments.each_with_index do |assignment, idx|
      assignment_id = assignment.new_record? ? assignment.id : assignment.previous_id
      grade = row[idx + @student_columns]
      if !assignment_visible_to_student(student, assignment, assignment_id, @visible_assignments)
        grade = ''
      end
      new_submission = {
        'grade' => grade,
        'assignment_id' => assignment_id
      }
      importer_submissions << new_submission
    end
    student.gradebook_importer_submissions = importer_submissions
  end

  def assignment_visible_to_student(student, assignment, assignment_id, visible_assignments)
    return true unless visible_assignments # wont be set if DA is off
    return true if assignment.new_record? || student.new_record?

    assignments_visible_to_student = visible_assignments[student.id].to_set
    assignments_visible_to_student.try(:include?, assignment_id)
  end

  def as_json(_options={})
    {
      :students => @students.map { |s| student_to_hash(s) },
      :assignments => @assignments.map { |a| assignment_to_hash(a) },
      :missing_objects => {
        :assignments => @missing_assignments.map { |a| assignment_to_hash(a) },
        :students => @missing_students.map { |s| student_to_hash(s) }
      },
      :original_submissions => @original_submissions,
      :unchanged_assignments => @unchanged_assignments,
      :warning_messages => @warning_messages
    }
  end

  protected

  def identify_delimiter(rows)
    field_counts = {}
    %w[; ,].each do |separator|
      begin
        field_count_by_row = rows.map { |line| CSV.parse_line(line, col_sep: separator).size }

        # If the number of fields generated by this separator is consistent for all lines,
        # we should be able to assume it's a valid delimiter for this file
        field_counts[separator] = field_count_by_row.first if field_count_by_row.uniq.size == 1
      rescue CSV::MalformedCSVError => e
      end
    end

    (field_counts.size == 1 && field_counts.keys.first == ';') ? :semicolon : :comma
  end

  def semicolon_delimited?(csv_file)
    first_lines = []
    File.open(csv_file.path) do |csv|
      while !csv.eof? && first_lines.size < 3
        first_lines << csv.readline
      end
    end

    return false if first_lines.blank?

    identify_delimiter(first_lines) == :semicolon
  end

  def check_for_non_student_row(row)
    # check if this is the first row, a header row
    if @assignments.nil?
      @assignments = process_header(row)
      return true
    end


    if row[0] =~ /Points Possible/
      # this row is describing the assignment, has no student data
      row.shift(@student_columns)
      process_pp(row)
      return true
    end

    if row.compact.all? { |c| c.strip =~ /^(Muted|)$/i }
      # this row is muted or empty and should not be processed at all
      return true
    end

    false # nothing unusual, signal to process as a student row
  end

  def csv_stream
    csv_file = attachment.open(need_local_file: true)
    is_semicolon_delimited = semicolon_delimited?(csv_file)
    csv_parse_options = {
      converters: %i(nil),
      skip_lines: /^[;, ]*$/,
      col_sep: is_semicolon_delimited ? ";" : ","
    }

    if is_semicolon_delimited
      csv_parse_options[:converters] << :decimal_comma_to_period
    end

    # using "foreach" rather than "parse" processes a chunk of the
    # file at a time rather than loading the whole file into memory
    # at once, a boon for memory consumption
    CSV.foreach(csv_file.path, csv_parse_options) do |row|
      yield row
    end
  end

  def add_root_account_to_pseudonym_cache(root_account)
    pseudonyms = root_account.shard.activate do
      root_account.pseudonyms
        .active
        .select([:id, :unique_id, :sis_user_id, :user_id])
        .where(:user_id => @all_students.values).to_a
    end
    pseudonyms.each do |pseudonym|
      @pseudonyms_by_sis_id[[root_account.id, pseudonym.sis_user_id]] = pseudonym
      @pseudonyms_by_login_id[[root_account.id, pseudonym.unique_id]] = pseudonym
    end
  end

  def student_to_hash(user)
    {
      :last_name_first => user.last_name_first,
      :name => user.name,
      :previous_id => user.previous_id,
      :id => user.id,
      :submissions => user.gradebook_importer_submissions
    }
  end

  def assignment_to_hash(assignment)
    {
      :id => assignment.id,
      :previous_id => assignment.previous_id,
      :title => assignment.title,
      :points_possible => assignment.points_possible,
      :grading_type => assignment.grading_type
    }
  end

  def valid_context?(context=nil)
    context && [
      :students,
      :assignments,
      :submissions,
      :students=,
      :assignments=,
      :submissions=
    ].all?{ |m| context.respond_to?(m) }
  end

  def readonly_assignment?(index)
    @pp_row[index] =~ /read\s+only/
  end

  private

  def gradeable?(submission:, is_admin: false)
    # `submission#grants_right?` will check if the user
    # is an admin, but if we've pre-loaded that value already
    # to avoid an N+1, check that first.
    is_admin || submission.grants_right?(@user, :grade)
  end
end
