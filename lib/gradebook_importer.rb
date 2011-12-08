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
  
  attr_reader :context, :contents, :assignments, :students, :submissions
  def initialize(context=nil, contents=nil)
    raise ArgumentError, "Must provide a valid context for this gradebook." unless valid_context?(context)
    raise ArgumentError, "Must provide CSV contents." unless contents
    @context = context
    @contents = contents
  end
  
  FasterCSV::Converters[:nil] = lambda{|e| (e.nil? ? e : raise) rescue e}
  
  def parse!
    @student_columns = 3 # name, user id, section
    # preload a ton of data that presumably we'll be querying
    @all_assignments = @context.assignments.active.gradeable.find(:all, :select => 'id, title, points_possible, grading_type').inject({}) { |r, a| r[a.id] = a; r}
    @all_students = @context.students.find(:all, :select => 'users.id, name, sortable_name').inject({}) { |r, s| r[s.id] = s; r }

    csv = FasterCSV.new(self.contents, :converters => :nil)
    header = csv.shift
    @assignments = process_header(header)
    
    @students = []
    @submissions = []
    csv.each do |row|
      if row[0] =~ /Points Possible/
        row.shift(@student_columns)
        process_pp(row)
        next
      end
      
      @students << process_student(row)
      @submissions << process_submissions(row, @students.last)
    end
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
    while row.last =~ /Current Score|Final Score|Final Grade/
      row.pop
    end
    
    row.map do |name_and_id|
      title, id = Assignment.title_and_id(name_and_id)
      assignment = @all_assignments[id.to_i] if id.present?
      assignment ||= @all_assignments.detect { |id, a| a.title == name_and_id }.try(:last) #backward compat
      assignment ||= Assignment.new(:title => title || name_and_id)
      assignment.original_id = assignment.id
      assignment.id ||= NegativeId.generate
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
    student.original_id = student.id
    student.id ||= NegativeId.generate
    student
  end
  
  def process_submissions(row, student)
    l = []
    @assignments.each_with_index do |assignment, idx|
      l << {
        'grade' => row[idx + @student_columns],
        'assignment_id' => assignment.new_record? ? assignment.id : assignment.original_id
      }
    end
    l
  end
  
  def to_json
    student_data = []
    @students.each_with_index { |s, idx| student_data << student_to_hash(s, idx) }
    {
      :students => student_data,
      :assignments => @assignments.map { |a| assignment_to_hash(a) }
    }.to_json
  end
  
  protected
    def all_pseudonyms
      @all_pseudonyms ||= @context.root_account.pseudonyms.active.find(:all, :select => 'id, unique_id, sis_user_id, user_id', :conditions => {:user_id => @all_students.values.map(&:id)})
    end

    def pseudonyms_by_sis_id
      @pseudonyms_by_sis_id ||= all_pseudonyms.inject({}) { |r, p| r[p.sis_user_id] = p if p.sis_user_id; r }
    end

    def pseudonyms_by_login_id
      @pseudonyms_by_login_id ||= all_pseudonyms.inject({}) { |r, p| r[p.unique_id] = p; r }
    end

    def student_to_hash(user, idx)
      {
        :last_name_first => user.last_name_first,
        :name => user.name,
        :original_id => user.original_id,
        :id => user.id,
        :submissions => @submissions[idx]
      }
    end
    
    def assignment_to_hash(assignment)
      {
        :id => assignment.id,
        :original_id => assignment.original_id,
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
