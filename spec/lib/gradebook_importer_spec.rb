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

    it "should handle muted line and being sorted in weird places" do
      course_model
      importer_with_rows(
          'Student,ID,Section,Assignment 1,Final Score',
          '"Blend, Bill",6,My Course,-,',
          'Points Possible,,,10,',
          ', ,,Muted,',
          '"Farner, Todd",4,My Course,-,')
      @gi.assignments.length.should == 1
      @gi.assignments.first.points_possible.should == 10
      @gi.students.length.should == 2
    end
  end

  context "User lookup" do
    it "should Lookup with either Student Name, ID, SIS User ID, or SIS Login ID" do
      course_model

      student_in_course(:name => "Some Name")
      @u1 = @user

      user_with_pseudonym(:active_all => true)
      @user.pseudonym.sis_user_id = "SISUSERID"
      @user.pseudonym.save!
      student_in_course(:user => @user)
      @u2 = @user

      user_with_pseudonym(:active_all => true, :username => "something_that_has_not_been_taken")
      student_in_course(:user => @user)
      @u3 = @user

      user_with_pseudonym(:active_all => true, :username => "inactive_login")
      @user.pseudonym.destroy
      student_in_course(:user => @user)
      @u4 = @user

      user_with_pseudonym(:active_all => true, :username => "inactive_login")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(:unique_id => 'active_login', :account => Account.default)
      student_in_course(:user => @user)
      @u5 = @user

      uploaded_csv = FasterCSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "","", ""]
        csv << [@u1.name , "", "", "", "", 99]
        csv << ["" , "", @u2.pseudonym.sis_user_id, "", "", 99]
        csv << ["" , "", "", @u3.pseudonym.unique_id, "", 99]
        csv << ["", "", "", 'inactive_login', "", 99]
        csv << ["", "", "", 'active_login', "", 99]
        csv << ["" , "", "bogusSISid", "", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = ActiveSupport::JSON.decode(@gi.to_json)

      hash['students'][0]['id'].should == @u1.id
      hash['students'][0]['original_id'].should == @u1.id
      hash['students'][0]['name'].should eql(@u1.name)

      hash['students'][1]['id'].should == @u2.id
      hash['students'][1]['original_id'].should == @u2.id

      hash['students'][2]['id'].should == @u3.id
      hash['students'][2]['original_id'].should == @u3.id

      # Looking up by login, but there are no active pseudonyms for u4
      hash['students'][3]['id'].should < 0
      hash['students'][3]['original_id'].should be_nil

      hash['students'][4]['id'].should == @u5.id
      hash['students'][4]['original_id'].should == @u5.id

      hash['students'][5]['id'].should <  0
      hash['students'][5]['original_id'].should be_nil
    end
    
    it "should allow ids that look like numbers" do
      course_model

      user_with_pseudonym(:active_all => true)
      @user.pseudonym.sis_user_id = "0123456"
      @user.pseudonym.save!
      student_in_course(:user => @user)
      @u0 = @user

      # user with an sis-id that is a number
      user_with_pseudonym(:active_all => true, :username => "octal_ud")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(:unique_id => '0231163', :account => Account.default)
      student_in_course(:user => @user)
      @u1 = @user

      uploaded_csv = FasterCSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "","", ""]
        csv << ["" , "", "0123456", "", "", 99]
        csv << ["" , "", "", "0231163", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = ActiveSupport::JSON.decode(@gi.to_json)

      hash['students'][0]['id'].should == @u0.id
      hash['students'][0]['original_id'].should == @u0.id

      hash['students'][1]['id'].should == @u1.id
      hash['students'][1]['original_id'].should == @u1.id
    end
  end

  it "should parse new and existing assignments" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1')
    @assignment3 = @course.assignments.create!(:name => 'Assignment 3')
    importer_with_rows(
        'Student,ID,Section,Assignment 1,Assignment 2',
        'Some Student,,,,'
    )
    @gi.assignments.length.should == 2
    @gi.assignments.first.should == @assignment1
    @gi.assignments.last.title.should == 'Assignment 2'
    @gi.assignments.last.should be_new_record
    @gi.assignments.last.id.should < 0
    @gi.missing_assignments.should == [@assignment3]
  end

  it "should not include missing assignments if no new assignments" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1')
    @assignment3 = @course.assignments.create!(:name => 'Assignment 3')
    importer_with_rows(
        'Student,ID,Section,Assignment 1',
        'Some Student,,,'
    )
    @gi.assignments.should == [@assignment1]
    @gi.missing_assignments.should == []
  end

  it "should not include assignments with no changes" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1"
    )
    @gi.assignments.should == []
    @gi.missing_assignments.should == []
  end

  it "should include assignments that changed only in points possible" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        "Points Possible,,,20"
    )
    @gi.assignments.should == [@assignment1]
    @gi.assignments.first.should be_changed
    @gi.assignments.first.points_possible.should == 20
  end

  it "should parse new and existing users" do
    course_with_student
    @student2 = user
    @course.enroll_student(@student2)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10",
        "New Student,,,12"
    )
    @gi.students.length.should == 2
    @gi.students.first.should == @student
    @gi.students.last.should be_new_record
    @gi.students.last.id.should < 0
    @gi.missing_students.should == [@student2]
  end

  it "should not include assignments that don't have any grade changes" do
    course_with_student
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, :grade => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    @gi.assignments.should == []
  end

  it "should include assignments that the grade changed for an existing user" do
    course_with_student
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, :grade => 8)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    @gi.assignments.should == [@assignment1]
    submission = @gi.students.first.read_attribute(:submissions).first
    submission['original_grade'].should == '8'
    submission['grade'].should == '10'
    submission['assignment_id'].should == @assignment1.id
  end

  context "to_json" do
    before do
      course_model
      new_gradebook_importer
    end

    it "should have a simplified json output" do
      hash = ActiveSupport::JSON.decode(@gi.to_json)
      hash.keys.sort.should eql(["assignments", "missing_objects", "original_submissions", "students", "unchanged_assignments"])
      students = hash["students"]
      students.should be_is_a(Array)
      student = students.first
      student.keys.sort.should eql(["id", "last_name_first", "name", "original_id", "submissions"])
      submissions = student["submissions"]
      submissions.should be_is_a(Array)
      submission = submissions.first
      submission.keys.sort.should eql(["assignment_id", "grade", "original_grade"])
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
