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
  FasterCSV::Converters[:nil_saving_numeric] = [:nil, :numeric]
  
  def parse!
    @student_columns = 3 # name, user id, section
    
    csv = FasterCSV.new(self.contents, :converters => :nil_saving_numeric)
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
      
      @students << process_student(row.shift(@student_columns))
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
        @student_columns += 2
      end
    end

    row.shift(@student_columns)
    while row.last =~ /Current Score|Final Score|Final Grade/
      row.pop
    end
    
    row.map do |name_and_id|
      title, id = Assignment.title_and_id(name_and_id)
      assignment = @context.assignments.active.gradeable.find_by_id(id) if id.present?
      assignment ||= @context.assignments.active.gradeable.find_by_title(name_and_id) #backward compat
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
    unsorted_name = to_unsorted_name(row[0])
    student_id = row[1] # the second column in the csv should have the student_id for each row
    student = @context.students.find_by_id(student_id) if student_id.present?
    student ||= @context.students.find_by_name(unsorted_name) if unsorted_name.present?
    student ||= User.new(:name => unsorted_name)
    student.original_id = student.id
    student.id ||= NegativeId.generate
    student
  end
  
  def process_submissions(row, student)
    l = []
    @assignments.each_with_index do |assignment, idx|
      l << {
        'grade' => row[idx],
        'assignment_id' => assignment.new_record? ? assignment.id : assignment.original_id
      }
    end
    l
  end
  
  def to_json
    {
      :students => @students.inject([]) { |l, s| l << student_to_hash(s) },
      :assignments => @assignments.inject([]) { |l, a| l << assignment_to_hash(a)}
    }.to_json
  end
  
  protected

    def student_to_hash(user)
      user_attributes = wanted_user_keys.inject({}) do |h, k|
        h[k] = user.send(k.to_sym)
        h
      end
      user_attributes[:submissions] = @submissions[@students.index(user)]
      user_attributes
    end
    
    def wanted_user_keys
      @wanted_user_keys ||= %w(last_name_first name original_id id)
    end
    
    def assignment_to_hash(assignment)
      wanted_assignment_keys.inject({}) do |h, k|
        h[k] = assignment.send(k.to_sym)
        h
      end
    end
    
    def wanted_assignment_keys
      %w(title original_id points_possible grading_type id)
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
    
    def to_unsorted_name(name)
      comma_separated = name.split(",")
      last_name = comma_separated[0]
      first_name = comma_separated[1]
      tail = comma_separated[2..-1]
      full_name = "#{first_name} #{last_name}".strip
      full_name += "," + tail.join(', ') if tail and not tail.empty?
      full_name
    end
end
