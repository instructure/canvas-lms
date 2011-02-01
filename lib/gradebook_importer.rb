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
  
  attr_reader :context, :contents
  def initialize(context=nil, contents=nil)
    raise ArgumentError, "Must provide a valid context for this gradebook." unless valid_context?(context)
    raise ArgumentError, "Must provide CSV contents." unless contents
    @context = context
    @contents = contents
  end
  
  FasterCSV::Converters[:nil] = lambda{|e| (e.nil? ? e : raise) rescue e}
  FasterCSV::Converters[:nil_saving_numeric] = [:nil, :numeric]
  
  def parsed_contents
    @parsed_contents ||= FasterCSV.parse( self.contents, :converters => :nil_saving_numeric )
    @students_start_at = 2
    @last_assignment_column = @parsed_contents[0].length - 1 
    while @parsed_contents[0][@last_assignment_column].match(/Current Score|Final Score/)
      @last_assignment_column -= 1
    end
    @parsed_contents
  end
  
  def students
    return @students if @students
    @students = self.parsed_contents[@students_start_at..-1].inject([]) do |l, e|
      unsorted_name = to_unsorted_name(e.first)
      student_id = e[1] # the second column in the csv should have the student_id for each row
      student = @context.students.find_by_id(student_id) || @context.students.find_by_name(unsorted_name)
      student ||= User.new(:name => unsorted_name)
      student.original_id = student.id
      student.id ||= NegativeId.generate
      l << student
    end
    @students
  end
  
  def assignments
    return @assignments if @assignments
    assignment_names = self.parsed_contents[0][3..@last_assignment_column]
    points_possible = self.parsed_contents[@students_start_at - 1][3..@last_assignment_column]
    @assignments = (0...assignment_names.size).inject([]) do |l, i|
      title,id = Assignment.title_and_id(assignment_names[i])
      name = assignment_names[i]
      points = points_possible[i]
      assignment = @context.assignments.active.gradeable.find_by_id(id) if id
      assignment ||= @context.assignments.active.gradeable.find_by_title(title)
      assignment ||= @context.assignments.active.gradeable.find_by_title(name)
      assignment ||= Assignment.new(:title => title || name)
      assignment.points_possible = points
      assignment.original_id = assignment.id
      assignment.id ||= NegativeId.generate
      l << assignment
    end
    @assignments
  end
  
  def submissions
    return @submissions if @submissions
    @submissions = []
    self.students.each_with_index do |student, i|
      list = []
      self.assignments.each_with_index do |assignment, j|
        list << {'grade' => self.parsed_contents[i + @students_start_at][j + 3], 'assignment_id' => assignment.new_record? ? assignment.id : assignment.original_id}
      end
      @submissions << list
    end
    @submissions
  end
  
  def to_json
    {
      :students => self.students.inject([]) { |l, s| l << student_to_hash(s) },
      :assignments => self.assignments.inject([]) { |l, a| l << assignment_to_hash(a)}
    }.to_json
  end

  
  protected

    def student_to_hash(user)
      user_attributes = wanted_user_keys.inject({}) do |h, k|
        h[k] = user.send(k.to_sym)
        h
      end
      user_attributes[:submissions] = self.submissions[students.index(user)]
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
