#
# Copyright (C) 2012 Instructure, Inc.
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
  include GradebookTransformer

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

  attr_reader :context, :contents, :assignments, :students, :submissions, :missing_assignments, :missing_students

  def self.create_from(progress, course, user, attachment)
    uploaded_gradebook = new(course, attachment, user, progress)
    uploaded_gradebook.parse!
  end

  def initialize(context=nil, csv=nil, user=nil, progress=nil)
    raise ArgumentError, "Must provide a valid context for this gradebook." unless valid_context?(context)
    raise ArgumentError, "Must provide CSV contents." unless csv
    @context = context
    @user = user
    @contents = csv
    @progress = progress

    @upload = GradebookUpload.new course: @context, user: @user, progress: @progress

    if @context.feature_enabled?(:differentiated_assignments)
      @visible_assignments = AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(
        course_id: @context.id, user_id: @context.all_students.pluck(:id)
      )
    end
  end

  CSV::Converters[:nil] = lambda do |e|
    begin
      e.nil? ? e : raise
    rescue
      e
    end
  end

  def parse!
    @student_columns = 3 # name, user id, section
    # preload a ton of data that presumably we'll be querying
    @all_assignments = @context.assignments
      .published
      .gradeable
      .select([:id, :title, :points_possible, :grading_type, :due_at])
      .index_by(&:id)
    @all_students = @context.all_students
      .select(['users.id', :name, :sortable_name])
      .index_by(&:id)

    csv = CSV.parse(contents, :converters => :nil)
    @assignments = process_header(csv)
    @root_accounts = {}
    @pseudonyms_by_sis_id = {}
    @pseudonyms_by_login_id = {}
    @students = []
    @pp_row = []
    csv.each do |row|
      if row[0] =~ /Points Possible/
        row.shift(@student_columns)
        process_pp(row)
        next
      end

      next if row.compact.all? { |c| c.strip =~ /^(Muted|)$/i }

      @students << process_student(row)
      process_submissions(row, @students.last)
    end

    memo = @assignments
    @assignments = select_in_current_grading_periods @assignments, @context
    @assignments_outside_current_periods = memo - @assignments

    @missing_assignments = []
    @missing_assignments = @all_assignments.values - @assignments if @missing_assignment
    @missing_students = []
    @missing_students = @all_students.values - @students if @missing_student

    # look up existing score for everything that was provided
    @original_submissions = @context.submissions
      .select([:assignment_id, :user_id, :score, :excused])
      .where(:assignment_id => (@missing_assignment ? @all_assignments.values : @assignments),
             :user_id => (@missing_student ? @all_students.values : @students))
      .map do |submission|
        {
          :user_id => submission.user_id,
          :assignment_id => submission.assignment_id,
          :score => submission.excused? ? "EX" : submission.score.to_s
        }
    end

    # cache the score on the existing object
    original_submissions_by_student = @original_submissions.inject({}) do |r, s|
      r[s[:user_id]] ||= {}
      r[s[:user_id]][s[:assignment_id]] = s[:score]
      r
    end
    @students.each do |student|
      student.gradebook_importer_submissions.each do |submission|
        submission['original_grade'] = original_submissions_by_student[student.id]
          .try(:[], submission['assignment_id'].to_i)
      end
    end

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

          submission['original_grade'].to_s == submission['grade'].to_s ||
            (submission['original_grade'].blank? && submission['grade'].blank?)
        end
      end
      indexes_to_delete.reverse_each do |idx|
        @assignments.delete_at(idx)
        @students.each do |student|
          student.gradebook_importer_submissions.delete_at(idx)
        end
      end
      @unchanged_assignments = !indexes_to_delete.empty?
      @students = [] if @assignments.empty?
    end

    # remove concluded enrollments
    prior_enrollment_ids = (
      @all_students.keys - @context.students.pluck(:user_id).map(&:to_i)
    ).to_set
    @students.delete_if { |s| prior_enrollment_ids.include? s.id }

    @original_submissions = [] unless @missing_student || @missing_assignment
    @upload.gradebook = self.as_json

    @upload.save!
  end

  def process_header(csv)
    row = csv.shift
    raise "Couldn't find header row" unless header?(row)

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
    if row[2] =~ /SIS\s+User\s+ID/ && row[3] =~ /SIS\s+Login\s+ID/
      @sis_user_id_column = 2
      @sis_login_id_column = 3
      @student_columns += 2
      if row[4] =~ /Root\s+Account/
        @root_account_column = 4
        @student_columns += 1
      end
    end
  end

  def strip_non_assignment_columns(row)
    drop_student_information_columns(row)

    while row.last =~ /Current Score|Current Points|Final Score|Final Points|Final Grade/
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
    end
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
    l = []
    @assignments.each_with_index do |assignment, idx|
      assignment_id = assignment.new_record? ? assignment.id : assignment.previous_id
      grade = row[idx + @student_columns]
      unless assignment_visible_to_student(student, assignment, assignment_id, @visible_assignments)
        grade = ''
      end
      new_submission = {
        'grade' => grade,
        'assignment_id' => assignment_id
      }
      l << new_submission
    end
    student.gradebook_importer_submissions = l
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
      :assignments_outside_current_periods =>
        @assignments_outside_current_periods.map { |a| assignment_to_hash(a) }
    }
  end

  protected
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
      :grading_type => assignment.grading_type,
      :due_at => assignment.due_at
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
end
