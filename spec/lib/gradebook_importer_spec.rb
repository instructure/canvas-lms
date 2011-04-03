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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradebookImporter do
  context "construction" do
    
    it "should require a context, usually a course" do
      lambda{GradebookImporter.new(1)}.should raise_error(ArgumentError, "Must provide a valid context for this gradebook.")
      lambda{GradebookImporter.new(course_model, valid_gradebook_contents)}.should_not raise_error
    end
    
    it "should store the context and make it available" do
      course_model
      new_gradebook_importer
      @gi.context.should be_is_a(Course)
    end
    
    it "should require the contents of an upload" do
      lambda{GradebookImporter.new(course_model)}.should raise_error(ArgumentError, "Must provide CSV contents.")
    end
    
    it "should store the contents and make them available" do
      course_model
      new_gradebook_importer
      @gi.contents.should_not be_nil
    end
    
    it "should handle points possible being sorted in weird places" do
      course_model
      importer_with_rows(
        'Student,ID,Section,Assignment 1,Final Score',
        '"Blend, Bill",6,My Course,-,',
        'Points Possible,,,10,',
        '"Farner, Todd",4,My Course,-,')
      @gi.assignments.length.should == 1
      @gi.assignments.first.points_possible.should == 10
      @gi.students.length.should == 2
    end
  end
  
  context "to_json" do
    before do
      course_model
      new_gradebook_importer
    end
    
    it "should have a simplified json output" do
      hash = ActiveSupport::JSON.decode(@gi.to_json)
      hash.keys.sort.should eql(["assignments", "students"])
      students = hash["students"]
      students.should be_is_a(Array)
      student = students.first
      student.keys.sort.should eql(["id", "last_name_first", "name", "original_id", "submissions"])
      submissions = student["submissions"]
      submissions.should be_is_a(Array)
      submission = submissions.first
      submission.keys.sort.should eql(["assignment_id", "grade"])
      assignments = hash["assignments"]
      assignments.should be_is_a(Array)
      assignment = assignments.first
      assignment.keys.sort.should eql(["grading_type", "id", "original_id", "points_possible", "title"])
    end
  end
end

def new_gradebook_importer(contents = valid_gradebook_contents)
  @gi = GradebookImporter.new(@course, contents)
  @gi.parse!
  @gi
end

def valid_gradebook_contents
  @contents ||= File.read(File.join(File.dirname(__FILE__), %w(.. fixtures gradebooks basic_course.csv)))
end

def importer_with_rows(*rows)
  new_gradebook_importer(rows.join("\n"))
end
