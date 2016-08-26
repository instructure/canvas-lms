#
# Copyright (C) 2012-2016 Instructure, Inc.
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

require_relative '../spec_helper'

require 'csv'

describe GradebookImporter do
  let(:gradebook_user){ user_model }

  context "construction" do
    let!(:gradebook_course){ course_model }

    it "should require a context, usually a course" do
      user = user_model
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.new
      expect{ GradebookImporter.new(upload) }.
        to raise_error(ArgumentError, "Must provide a valid context for this gradebook.")
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress: progress)
      expect{ GradebookImporter.new(upload, valid_gradebook_contents, user, progress) }.
        not_to raise_error
    end

    it "should store the context and make it available" do
      new_gradebook_importer
      expect(@gi.context).to be_is_a(Course)
    end

    it "should require the contents of an upload" do
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress: progress)
      expect{ GradebookImporter.new(upload) }.
        to raise_error(ArgumentError, "Must provide attachment.")
    end


    it "should handle points possible being sorted in weird places" do
      importer_with_rows(
        'Student,ID,Section,Assignment 1,Final Score',
        '"Blend, Bill",6,My Course,-,',
        'Points Possible,,,10,',
        '"Farner, Todd",4,My Course,-,')
      expect(@gi.assignments.length).to eq 1
      expect(@gi.assignments.first.points_possible).to eq 10
      expect(@gi.students.length).to eq 2
    end

    it "should handle muted line and being sorted in weird places" do
      importer_with_rows(
          'Student,ID,Section,Assignment 1,Final Score',
          '"Blend, Bill",6,My Course,-,',
          'Points Possible,,,10,',
          ', ,,Muted,',
          '"Farner, Todd",4,My Course,-,')
      expect(@gi.assignments.length).to eq 1
      expect(@gi.assignments.first.points_possible).to eq 10
      expect(@gi.students.length).to eq 2
    end

    it "creates a GradebookUpload" do
      new_gradebook_importer
      expect(GradebookUpload.where(course_id: @course, user_id: @user)).not_to be_empty
    end

    context "when attachment and gradebook_upload is provided" do

      let(:attachment) do
        a = attachment_model
        file = Tempfile.new("gradebook.csv")
        file.puts("'Student,ID,Section,Assignment 1,Final Score'\n")
        file.puts("\"Blend, Bill\",6,My Course,-,\n")
        file.close
        a.stubs(:open).returns(file)
        return a
      end

      let(:progress){ Progress.create!(tag: "test", context: gradebook_user) }

      let(:upload) do
        GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress: progress)
      end

      let(:importer) { new_gradebook_importer(attachment, upload, gradebook_user, progress) }

      it "hangs onto the provided model for streaming" do
        expect(importer.attachment).to eq(attachment)
      end

      it "nils out contents when using an attachment (saves on memory to not parse all at once)" do
        expect(importer.contents).to be_nil
      end

      it "keeps the provided upload rather than creating a new one" do
        expect(importer.upload).to eq(upload)
      end

      it "sets the uploads course as the importer context" do
        expect(importer.context).to eq(gradebook_course)
      end

    end
  end

  context "User lookup" do
    it "should Lookup with either Student Name, ID, SIS User ID, or SIS Login ID" do
      course_model

      student_in_course(:name => "Some Name", active_all: true)
      @u1 = @user

      user_with_pseudonym(:active_all => true)
      @user.pseudonym.sis_user_id = "SISUSERID"
      @user.pseudonym.save!
      student_in_course(user: @user, active_all: true)
      @u2 = @user

      user_with_pseudonym(:active_all => true, :username => "something_that_has_not_been_taken")
      student_in_course(user: @user, active_all: true)
      @u3 = @user

      user_with_pseudonym(:active_all => true, :username => "inactive_login")
      @user.pseudonym.destroy
      student_in_course(user: @user, active_all: true)
      @u4 = @user

      user_with_pseudonym(:active_all => true, :username => "inactive_login")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(:unique_id => 'active_login', :account => Account.default)
      student_in_course(user: @user, active_all: true)
      @u5 = @user

      uploaded_csv = CSV.generate do |csv|
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
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u1.id
      expect(hash[:students][0][:previous_id]).to eq @u1.id
      expect(hash[:students][0][:name]).to eql(@u1.name)

      expect(hash[:students][1][:id]).to eq @u2.id
      expect(hash[:students][1][:previous_id]).to eq @u2.id

      expect(hash[:students][2][:id]).to eq @u3.id
      expect(hash[:students][2][:previous_id]).to eq @u3.id

      # Looking up by login, but there are no active pseudonyms for u4
      expect(hash[:students][3][:id]).to be < 0
      expect(hash[:students][3][:previous_id]).to be_nil

      expect(hash[:students][4][:id]).to eq @u5.id
      expect(hash[:students][4][:previous_id]).to eq @u5.id

      expect(hash[:students][5][:id]).to be <  0
      expect(hash[:students][5][:previous_id]).to be_nil
    end

    it "should Lookup by root account" do
      course_model

      student_in_course(name: "Some Name", active_all: true)
      @u1 = @user

      account2 = Account.create!
      p = @u1.pseudonyms.create!(account: account2, unique_id: 'uniqueid')
      p.sis_user_id = 'SISUSERID'
      p.save!
      Account.expects(:find_by_domain).with('account2').returns(account2)

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Root Account", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "","", "", ""]
        csv << ["" , "",  @u1.pseudonym.sis_user_id, "", "account2", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u1.id
      expect(hash[:students][0][:previous_id]).to eq @u1.id
      expect(hash[:students][0][:name]).to eql(@u1.name)
    end

    it "should allow ids that look like numbers" do
      course_model

      user_with_pseudonym(:active_all => true)
      @user.pseudonym.sis_user_id = "0123456"
      @user.pseudonym.save!
      student_in_course(user: @user, active_all: true)
      @u0 = @user

      # user with an sis-id that is a number
      user_with_pseudonym(:active_all => true, :username => "octal_ud")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(:unique_id => '0231163', :account => Account.default)
      student_in_course(user: @user, active_all: true)
      @u1 = @user

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "","", ""]
        csv << ["" , "", "0123456", "", "", 99]
        csv << ["" , "", "", "0231163", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u0.id
      expect(hash[:students][0][:previous_id]).to eq @u0.id

      expect(hash[:students][1][:id]).to eq @u1.id
      expect(hash[:students][1][:previous_id]).to eq @u1.id
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
    expect(@gi.assignments.length).to eq 2
    expect(@gi.assignments.first).to eq @assignment1
    expect(@gi.assignments.last.title).to eq 'Assignment 2'
    expect(@gi.assignments.last).to be_new_record
    expect(@gi.assignments.last.id).to be < 0
    expect(@gi.missing_assignments).to eq [@assignment3]
  end

  it "should parse CSVs with the SIS Login ID column" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course: course, user: @user, progress: progress)
    importer = GradebookImporter.new(
      upload, valid_gradebook_contents_with_sis_login_id, user, progress
    )

    expect{importer.parse!}.not_to raise_error
  end

  it "should not include missing assignments if no new assignments" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1')
    @assignment3 = @course.assignments.create!(:name => 'Assignment 3')
    importer_with_rows(
        'Student,ID,Section,Assignment 1',
        'Some Student,,,'
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to eq []
  end

  it "should not include assignments with no changes" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1"
    )
    expect(@gi.assignments).to eq []
    expect(@gi.missing_assignments).to eq []
  end

  it "doesn't include readonly assignments" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1 = @course.assignments.create!(:name => 'Assignment 2', :points_possible => 10)
    importer_with_rows(
      'Student,ID,Section,Assignment 1,Readonly,Assignment 2',
      '    Points Possible,,,,(read only),'

    )
    expect(@gi.assignments).to eq []
    expect(@gi.missing_assignments).to eq []
  end

  it "should include assignments that changed only in points possible" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        "Points Possible,,,20"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.assignments.first).to be_changed
    expect(@gi.assignments.first.points_possible).to eq 20
  end

  it "should not try to create assignments for the totals columns" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1,Current Points,Final Points,Current Score,Final Score,Final Grade",
        "Points Possible,,,20,,,,,"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to be_empty
  end

  it "should parse new and existing users" do
    course_with_student(active_all: true)
    @student1 = @student
    e = student_in_course
    e.update_attribute :workflow_state, 'completed'
    concluded_student = @student
    @student2 = user
    @course.enroll_student(@student2)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student1.id},,10",
        "New Student,,,12",
        ",#{concluded_student.id},,10"
    )
    expect(@gi.students.length).to eq 2  # doesn't include concluded_student
    expect(@gi.students.first).to eq @student1
    expect(@gi.students.last).to be_new_record
    expect(@gi.students.last.id).to be < 0
    expect(@gi.missing_students).to eq [@student2]
  end

  it "should not include assignments that don't have any grade changes" do
    course_with_student
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, :grade => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq []
  end

  it "should include assignments that the grade changed for an existing user" do
    course_with_student(active_all: true)
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, :grade => 8)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq [@assignment1]
    submission = @gi.students.first.gradebook_importer_submissions.first
    expect(submission['original_grade']).to eq '8.0'
    expect(submission['grade']).to eq '10'
    expect(submission['assignment_id']).to eq @assignment1.id
  end

  context "to_json" do
    before do
      course_model
      new_gradebook_importer
    end

    let(:hash)        { @gi.as_json }
    let(:student)     { hash[:students].first }
    let(:submission)  { student[:submissions].first }
    let(:assignment)  { hash[:assignments].first }

    describe "simplified json output" do
      it "has only the specified keys" do
        keys = [:assignments,:assignments_outside_current_periods,
                :missing_objects, :original_submissions, :students,
                :unchanged_assignments]
        expect(hash.keys.sort).to eql(keys)
      end

      it "a student only has specified keys" do
        keys = [:id, :last_name_first, :name, :previous_id, :submissions]
        expect(student.keys.sort).to eql(keys)
      end

      it "a submission only has specified keys" do
        keys = ["assignment_id", "grade", "original_grade"]
        expect(submission.keys.sort).to eql(keys)
      end

      it "an assignment only has specified keys" do
        keys = [:due_at, :grading_type, :id, :points_possible, :previous_id,
                :title]
        expect(assignment.keys.sort).to eql(keys)
      end
    end
  end

  context "differentiated assignments" do
    def setup_DA
      course_with_teacher(active_all: true)
      @section_one = @course.course_sections.create!(name: 'Section One')
      @section_two = @course.course_sections.create!(name: 'Section Two')

      @student_one = student_in_section(@section_one)
      @student_two = student_in_section(@section_two)

      @assignment_one = assignment_model(course: @course, title: "a1")
      @assignment_two = assignment_model(course: @course, title: "a2")

      differentiated_assignment(assignment: @assignment_one, course_section: @section_one)
      differentiated_assignment(assignment: @assignment_two, course_section: @section_two)
    end

    before :once do
      setup_DA
    end

    it "should ignore submissions for students without visibility" do
      @assignment_one.grade_student(@student_one, :grade => "3")
      @assignment_two.grade_student(@student_two, :grade => "3")
      importer_with_rows(
        "Student,ID,Section,a1,a2",
        ",#{@student_one.id},#{@section_one.id},7,9",
        ",#{@student_two.id},#{@section_two.id},7,9"
      )
      json = @gi.as_json
      expect(json[:students][0][:submissions][0]["grade"]).to eq "7"
      expect(json[:students][0][:submissions][1]["grade"]).to eq ""
      expect(json[:students][1][:submissions][0]["grade"]).to eq ""
      expect(json[:students][1][:submissions][1]["grade"]).to eq "9"
    end

    it "should not break the creation of new assignments" do
      importer_with_rows(
          "Student,ID,Section,a1,a2,a3",
          "#{@student_one.name},#{@student_one.id},,1,2,3"
      )
      expect(@gi.assignments.last.title).to eq 'a3'
      expect(@gi.assignments.last).to be_new_record
      expect(@gi.assignments.last.id).to be < 0
      json = @gi.as_json
      expect(json[:students][0][:submissions].first["grade"]).to eq "1"
      expect(json[:students][0][:submissions].last["grade"]).to eq "3"
    end
  end

  context "multiple grading periods" do
    let(:group) { Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course) }
    let!(:old_period) do
      old_period_params = { title: "Course Period 2: old period",
                            start_date: 2.months.ago,
                            end_date: 1.month.ago }
      group.grading_periods.create old_period_params
    end

    let!(:current_period) do
      current_period_params = { title: "Course Period 1: current period",
                                start_date: 1.month.ago,
                                end_date: 1.month.from_now }
      group.grading_periods.create current_period_params
    end

    let(:future_period) do
      future_period_params = { title: "Course Period 3: future period",
                                start_date: 1.month.from_now,
                                end_date: 2.months.from_now }
      group.grading_periods.create future_period_params
    end

    let(:account)   { Account.default }
    let(:course)    { Course.create account: account }
    let(:student)   { User.create }
    let(:progress)  { Progress.create tag: "test", context: student }

    let(:importer_json) do
      lambda do |hashes|
        hashes.each { |hash| course.assignments.create hash }

        contents = <<CSV
Student,ID,Section,#{course.assignments.map(&:name).join(',')}
,#{student.id},#{',9' * course.assignments.length}
CSV
        upload = GradebookUpload.create!(course: course, user: student, progress: progress)
        attachment = attachment_with_rows(contents)
        importer = GradebookImporter.new(upload, attachment, student, progress)
        importer.parse!
        importer.as_json
      end
    end

    describe "assignments_outside_current_periods" do
      describe "when multiple grading periods is on" do
        before do
          course.root_account.enable_feature! :multiple_grading_periods
        end

        describe "empty assignments_outside_current_periods" do
          it "when assignments are in a current grading period" do
            assignment_hashes = [ { name:            'Assignment 1',
                                    points_possible: 10,
                                    due_at:          Time.zone.now } ]
            json = importer_json.call(assignment_hashes)
            expect(json[:assignments_outside_current_periods]).to be_empty
          end

          it "when all assignments have no due_ats" do
            assignment_hashes = [ { points_possible: 10,
                                    name:            'Assignment 2' } ]
            json = importer_json.call(assignment_hashes)
            expect(json[:assignments_outside_current_periods]).to be_empty
          end

          it "when assignment due_ats are nil and there is a future period" do
            future_period
            assignment_hashes = [ { points_possible: 10,
                                    name:            'Assignment 2.five' } ]
            json = importer_json.call(assignment_hashes)
            expect(json[:assignments_outside_current_periods]).to be_empty
          end
        end

        describe "when all assignments are in past grading periods" do
          it "indicates assignments not in a current grading period" do
            assignment_hashes = [ { points_possible: 10,
                                    name:            'Assignment 3',
                                    due_at:          6.weeks.ago } ]
            json = importer_json.call(assignment_hashes)
            past_assignment = json[:assignments_outside_current_periods].first
            expect(past_assignment[:title]).to eq 'Assignment 3'
          end
        end

        describe "when some assignments are in past grading periods" do
          it "indicates assignments not in a current grading period" do
            assignment_hashes = [ { points_possible: 10,
                                    name:            'Assignment 4',
                                    due_at:          6.weeks.ago},
                                  { points_possible: 10,
                                    name:            'Assignment 5',
                                    due_at:          1.day.from_now } ]
            json = importer_json.call(assignment_hashes)
            past_assignment = json[:assignments_outside_current_periods].first
            expect(past_assignment[:title]).to eq 'Assignment 4'
          end
        end
      end

      it "should be empty when multiple grading periods is off" do
        assignment_hashes = [ { points_possible: 10,
                                name:            'Assignment 6',
                                due_at:          6.weeks.ago } ]
        json = importer_json.call(assignment_hashes)
        course.root_account.disable_feature! :multiple_grading_periods
        expect(json[:assignments_outside_current_periods]).to be_empty
      end
    end
  end

  describe "#translate_pass_fail" do
    let(:account) { Account.default }
    let(:course) { Course.create account: account }
    let(:student) do
      student = User.create
      student.gradebook_importer_submissions = [{ "grade" => "",
                                                  "original_grade" => ""}]
      student
    end
    let(:assignment) do
      course.assignments.create!(:name => 'Assignment 1',
                                 :grading_type => "pass_fail",
                                 :points_possible => 6)
    end
    let(:assignments) { [assignment] }
    let(:students) { [student] }
    let(:progress) { Progress.create tag: "test", context: student }
    let(:gradebook_upload){ GradebookUpload.create!(course: course, user: student, progress: progress) }
    let(:importer) { GradebookImporter.new(gradebook_upload, "", student, progress) }
    let(:submission) { student.gradebook_importer_submissions.first }

    it "translates positive score in submission['grade'] to complete" do
      submission['grade'] = "3"
      importer.translate_pass_fail(assignments, students)

      expect(submission['grade']).to eq "complete"
    end

    it "translates positive grade in submission['original_grade'] to complete" do
      submission['original_grade'] = "3"
      importer.translate_pass_fail(assignments, students)

      expect(submission['original_grade']).to eq "complete"
    end

    it "translates 0 grade in submission['grade'] to incomplete" do
      submission['grade'] = "0"
      importer.translate_pass_fail(assignments, students)

      expect(submission['grade']).to eq "incomplete"
    end

    it "translates 0 grade in submission['original_grade'] to incomplete" do
      submission['original_grade'] = "0"
      importer.translate_pass_fail(assignments, students)

      expect(submission['original_grade']).to eq "incomplete"
    end

    it "doesn't change empty string grade in submission['grade']" do
      importer.translate_pass_fail(assignments, students)

      expect(submission['grade']).to eq ""
    end

    it "doesn't change empty string grade in submission['original_grade']" do
      importer.translate_pass_fail(assignments, students)

      expect(submission['grade']).to eq ""
    end
  end
end

def new_gradebook_importer(attachment = valid_gradebook_contents, upload = nil, user = gradebook_user, progress = nil)
  @user = user
  @progress = progress || Progress.create!(tag: "test", context: @user)
  upload ||= GradebookUpload.create!(course: @course, user: @user, progress: @progress)
  if attachment.is_a?(String)
    attachment = attachment_with_rows(attachment)
  end
  @gi = GradebookImporter.new(upload, attachment, @user, @progress)
  @gi.parse!
  @gi
end

def valid_gradebook_contents
  attachment_with_file(File.join(File.dirname(__FILE__), %w(.. fixtures gradebooks basic_course.csv)))
end

def valid_gradebook_contents_with_sis_login_id
  attachment_with_file(File.join(File.dirname(__FILE__), %w(.. fixtures gradebooks basic_course_with_sis_login_id.csv)))
end

def attachment_with
  a = attachment_model
  file = Tempfile.new("gradebook_import.csv")
  yield file
  file.close
  a.stubs(:open).returns(file)
  a
end

def attachment_with_file(path)
  contents = File.read(path)
  attachment_with do |tempfile|
    tempfile.write(contents)
  end
end

def attachment_with_rows(*rows)
  attachment_with do |tempfile|
    rows.each do |row|
      tempfile.puts(row)
    end
  end
end

def importer_with_rows(*rows)
  new_gradebook_importer(attachment_with_rows(rows))
end
