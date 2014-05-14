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
  def initialize(context=nil, contents=nil)
    raise ArgumentError, "Must provide a valid context for this gradebook." unless valid_context?(context)
    raise ArgumentError, "Must provide CSV contents." unless contents
    @context = context
    @contents = contents
  end
  
  CSV::Converters[:nil] = lambda{|e| (e.nil? ? e : raise) rescue e}
  
  def parse!
    @student_columns = 3 # name, user id, section
    # preload a ton of data that presumably we'll be querying
    @all_assignments = @context.assignments.active.gradeable.select([:id, :title, :points_possible, :grading_type]).index_by(&:id)
    @all_students = @context.students.select(['users.id', :name, :sortable_name]).index_by(&:id)

    csv = CSV.new(self.contents, :converters => :nil)
    header = csv.shift
    @assignments = process_header(header)

    @students = []
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

    @missing_assignments = []
    @missing_assignments = @all_assignments.values - @assignments if @missing_assignment
    @missing_students = []
    @missing_students = @all_students.values - @students if @missing_student

    # look up existing score for everything that was provided
    @original_submissions = @context.submissions.
        select([:assignment_id, :user_id, :score]).
        where(:assignment_id => (@missing_assignment ? @all_assignments.values : @assignments),
              :user_id => (@missing_student ? @all_students.values : @students)).
        map do |s|
          {
            :user_id => s.user_id,
            :assignment_id => s.assignment_id,
            :score => s.score.to_s
          }
        end

    # cache the score on the existing object
    original_submissions_by_student = @original_submissions.inject({}) do |r, s|
      r[s[:user_id]] ||= {}
      r[s[:user_id]][s[:assignment_id]] = s[:score]
      r
    end
    @students.each do |student|
      student.read_attribute(:submissions).each do |submission|
        submission['original_grade'] = original_submissions_by_student[student.id].try(:[], submission['assignment_id'].to_i)
      end
    end

    unless @missing_student
      # weed out assignments with no changes
      indexes_to_delete = []
      @assignments.each_with_index do |assignment, idx|
        next if assignment.changed?
        indexes_to_delete << idx if @students.all? do |student|
          submission = student.read_attribute(:submissions)[idx]
          submission['original_grade'].to_s == submission['grade'] || (submission['original_grade'].blank? && submission['grade'].blank?)
        end
      end
      indexes_to_delete.reverse.each do |idx|
        @assignments.delete_at(idx)
        @students.each do |student|
          student.read_attribute(:submissions).delete_at(idx)
        end
      end
      @unchanged_assignments = !indexes_to_delete.empty?
      @students = [] if @assignments.empty?
    end

    @original_submissions = [] unless @missing_student || @missing_assignment
  end
  
  def process_header(row)
    if row.length < 3 || row[0] !~ /Student/ || row[1] !~ /ID/
      raise "Couldn't find header row"
    end

    if row[2] !~ /Section/
      if row[4] !~ /Section/ || row[2] !~ /SIS\s+User\s+ID/ || row[3] !~ /SIS\s+Login\s+ID/
        raise "Couldn't find header row"
      else
        @sis_user_id_column = 2
        @sis_login_id_column = 3
        @student_columns += 2
      end
    end

    row.shift(@student_columns)
    while row.last =~ /Current Score|Current Points|Final Score|Final Points|Final Grade/
      row.pop
    end
    
    row.map do |name_and_id|
      title, id = Assignment.title_and_id(name_and_id)
      assignment = @all_assignments[id.to_i] if id.present?
      assignment ||= @all_assignments.detect { |id, a| a.title == name_and_id }.try(:last) #backward compat
      assignment ||= Assignment.new(:title => title || name_and_id)
      assignment.previous_id = assignment.id
      assignment.id ||= NegativeId.generate
      @missing_assignment ||= assignment.new_record?
      assignment
    end
  end
  
  def process_pp(row)
    @assignments.each_with_index do |assignment, idx|
      assignment.points_possible = row[idx] if row[idx]
    end
  end
  
  def process_student(row)
    student_id = row[1] # the second column in the csv should have the student_id for each row
    student = @all_students[student_id.to_i] if student_id.present?
    unless student
      pseudonym = pseudonyms_by_sis_id[row[@sis_user_id_column]] if @sis_user_id_column && row[@sis_user_id_column].present?
      pseudonym ||= pseudonyms_by_login_id[row[@sis_login_id_column]] if @sis_login_id_column && row[@sis_login_id_column].present?
      student = @all_students[pseudonym.user_id] if pseudonym
    end
    student ||= @all_students.detect { |id, s| s.name == row[0] || s.sortable_name == row[0] }.try(:last) if row[0].present?
    student ||= User.new(:name => row[0])
    student.previous_id = student.id
    student.id ||= NegativeId.generate
    @missing_student ||= student.new_record?
    student
  end
  
  def process_submissions(row, student)
    l = []
    @assignments.each_with_index do |assignment, idx|
      l << {
        'grade' => row[idx + @student_columns],
        'assignment_id' => assignment.new_record? ? assignment.id : assignment.previous_id
      }
    end
    student.write_attribute(:submissions, l)
  end
  
  def as_json(options={})
    {
      :students => @students.map { |s| student_to_hash(s) },
      :assignments => @assignments.map { |a| assignment_to_hash(a) },
      :missing_objects => {
          :assignments => @missing_assignments.map { |a| assignment_to_hash(a) },
          :students => @missing_students.map { |s| student_to_hash(s) }
      },
      :original_submissions => @original_submissions,
      :unchanged_assignments => @unchanged_assignments
    }
  end
  
  protected
    def all_pseudonyms
      @all_pseudonyms ||= @context.root_account.pseudonyms.active.select([:id, :unique_id, :sis_user_id, :user_id]).where(:user_id => @all_students.values).all
    end

    def pseudonyms_by_sis_id
      @pseudonyms_by_sis_id ||= all_pseudonyms.inject({}) { |r, p| r[p.sis_user_id] = p if p.sis_user_id; r }
    end

    def pseudonyms_by_login_id
      @pseudonyms_by_login_id ||= all_pseudonyms.inject({}) { |r, p| r[p.unique_id] = p; r }
    end

    def student_to_hash(user)
      {
        :last_name_first => user.last_name_first,
        :name => user.name,
        :previous_id => user.previous_id,
        :id => user.id,
        :submissions => user.read_attribute(:submissions)
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
      return context && [
        :students, 
        :assignments, 
        :submissions, 
        :students=, 
        :assignments=, 
        :submissions=
      ].all?{ |m| context.respond_to?(m) }
    end
end
