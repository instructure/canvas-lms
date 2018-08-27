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

require_relative '../spec_helper'

require 'csv'

describe GradebookImporter do
  let(:gradebook_user) do
    teacher = User.create!
    course_with_teacher(user: teacher, course: @course)
    teacher
  end

  context "construction" do
    let!(:gradebook_course){ course_model }

    it "requires a context, usually a course" do
      user = user_model
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.new
      expect{ GradebookImporter.new(upload) }.
        to raise_error(ArgumentError, "Must provide a valid context for this gradebook.")
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress: progress)
      expect{ GradebookImporter.new(upload, valid_gradebook_contents, user, progress) }.
        not_to raise_error
    end

    it "stores the context and make it available" do
      new_gradebook_importer
      expect(@gi.context).to be_is_a(Course)
    end

    it "requires the contents of an upload" do
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress: progress)
      expect{ GradebookImporter.new(upload) }.
        to raise_error(ArgumentError, "Must provide attachment.")
    end

    it "handles points possible being sorted in weird places" do
      importer_with_rows(
        'Student,ID,Section,Assignment 1,Final Score',
        '"Blend, Bill",6,My Course,-,',
        'Points Possible,,,10,',
        '"Farner, Todd",4,My Course,-,')
      expect(@gi.assignments.length).to eq 1
      expect(@gi.assignments.first.points_possible).to eq 10
      expect(@gi.students.length).to eq 2
    end

    it "handles muted line and being sorted in weird places" do
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

    context 'when dealing with a file containing semicolon field separators' do
      context 'with interspersed commas to throw you off' do
        before(:each) do
          @rows = [
            'Student;ID;Section;Aufgabe 1;Aufgabe 2;Final Score',
            'Points Possible;;;10000,54;100,00;',
            '"Merkel 1,0, Angela";1;Mein Kurs;123,4;57,4%;',
            '"Einstein 1,1, Albert";2;Mein Kurs;1.234,5;4.200,3%;',
            '"Curie, Marie";3;Mein Kurs;12.34,5;4.20.0,3%;',
            '"Planck, Max";4;Mein Kurs;-1.234,50;-4.200,30%;',
            '"Bohr, Neils";5;Mein Kurs;1.234.5;4.200.3%;',
            '"Dirac, Paul";6;Mein Kurs;1,234,5;4,200,3%;'
          ]

          importer_with_rows(*@rows)
        end

        it 'parses out assignments only' do
          expect(@gi.assignments.length).to eq 2
        end

        it 'parses out points_possible correctly' do
          expect(@gi.assignments.first.points_possible).to eq(10_000.54)
        end

        it 'parses out students correctly' do
          expect(@gi.students.length).to eq 6
        end

        it 'does not reformat numbers that are part of strings' do
          expect(@gi.students.first.name).to eq('Merkel 1,0, Angela')
        end

        it 'normalizes pure numbers' do
          expected_grades = %w[123.4 1234.5 1234.5 -1234.50 1234.5 1234.5]
          actual_grades = @gi.upload.gradebook.fetch('students').map { |student| student.fetch('submissions').first.fetch('grade') }

          expect(actual_grades).to match_array(expected_grades)
        end

        it 'normalizes percentages' do
          expected_grades = %w[57.4% 4200.3% 4200.3% -4200.30% 4200.3% 4200.3%]
          actual_grades = @gi.upload.gradebook.fetch('students').map { |student| student.fetch('submissions').second.fetch('grade') }

          expect(actual_grades).to match_array(expected_grades)
        end
      end

      context 'without any interspersed commas' do
        before(:each) do
          @rows = [
            'Student;ID;Section;Aufgabe 1;Aufgabe 2;Final Score',
            'Points Possible;;;10000,54;100,00;',
            '"Angela Merkel";1;Mein Kurs;123,4;57,4%;',
            '"Albert Einstein";2;Mein Kurs;1.234,5;4.200,3%;',
            '"Marie Curie";3;Mein Kurs;12.34,5;4.20.0,3%;',
            '"Max Planck";4;Mein Kurs;-1.234,50;-4.200,30%;',
            '"Neils Bohr";5;Mein Kurs;1.234.5;4.200.3%;',
            '"Paul Dirac";6;Mein Kurs;1,234,5;4,200,3%;'
          ]

          importer_with_rows(*@rows)
        end

        it 'parses out assignments only' do
          expect(@gi.assignments.length).to eq 2
        end

        it 'parses out points_possible correctly' do
          expect(@gi.assignments.first.points_possible).to eq(10_000.54)
        end

        it 'parses out students correctly' do
          expect(@gi.students.length).to eq 6
        end

        it 'does not reformat numbers that are part of strings' do
          expect(@gi.students.first.name).to eq('Angela Merkel')
        end

        it 'normalizes pure numbers' do
          expected_grades = %w[123.4 1234.5 1234.5 -1234.50 1234.5 1234.5]
          actual_grades = @gi.upload.gradebook.fetch('students').map { |student| student.fetch('submissions').first.fetch('grade') }

          expect(actual_grades).to match_array(expected_grades)
        end

        it 'normalizes percentages' do
          expected_grades = %w[57.4% 4200.3% 4200.3% -4200.30% 4200.3% 4200.3%]
          actual_grades = @gi.upload.gradebook.fetch('students').map { |student| student.fetch('submissions').second.fetch('grade') }

          expect(actual_grades).to match_array(expected_grades)
        end
      end
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
        allow(a).to receive(:open).and_return(file)
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
    it "Lookups with either Student Name, ID, SIS User ID, or SIS Login ID" do
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
        csv << [@u1.name, "", "", "", "", 99]
        csv << ["", "", @u2.pseudonym.sis_user_id, "", "", 99]
        csv << ["", "", "", @u3.pseudonym.unique_id, "", 99]
        csv << ["", "", "", 'inactive_login', "", 99]
        csv << ["", "", "", 'active_login', "", 99]
        csv << ["", "", "bogusSISid", "", "", 99]
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

    it "Lookups by root account" do
      course_model

      student_in_course(name: "Some Name", active_all: true)
      @u1 = @user

      account2 = Account.create!
      p = @u1.pseudonyms.create!(account: account2, unique_id: 'uniqueid')
      p.sis_user_id = 'SISUSERID'
      p.save!
      expect(Account).to receive(:find_by_domain).with('account2').and_return(account2)

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Root Account", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "","", "", ""]
        csv << ["", "", @u1.pseudonym.sis_user_id, "", "account2", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u1.id
      expect(hash[:students][0][:previous_id]).to eq @u1.id
      expect(hash[:students][0][:name]).to eql(@u1.name)
    end

    it "allows ids that look like numbers" do
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
        csv << ["", "", "0123456", "", "", 99]
        csv << ["", "", "", "0231163", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u0.id
      expect(hash[:students][0][:previous_id]).to eq @u0.id

      expect(hash[:students][1][:id]).to eq @u1.id
      expect(hash[:students][1][:previous_id]).to eq @u1.id
    end

    it "fails and updates progress if invalid header row" do
      uploaded_csv = CSV.generate do |csv|
        csv << ["", "", "0123456", "", "", 99]
        csv << ["", "", "", "0231163", "", 99]
      end

      importer_with_rows(uploaded_csv)
      @progress.reload
      expect(@progress).to be_failed
      expect(@progress.message).to eq 'Invalid header row'
    end
  end

  it "parses new and existing assignments" do
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

  it "parses assignments correctly with existing custom columns" do
    course_model
    @assignment1 = @course.assignments.create! name: 'Assignment 1'
    @assignment3 = @course.assignments.create! name: 'Assignment 3'
    @custom_column1 = @course.custom_gradebook_columns.create! title: "Custom Column 1"

    importer_with_rows(
      'Student,ID,Section,Custom Column 1,Assignment 1,Assignment 2',
      'Some Student,,,,,'
    )

    expect(@gi.assignments.length).to eq 2
    expect(@gi.assignments.first).to eq @assignment1
    expect(@gi.assignments.last.title).to eq 'Assignment 2'
    expect(@gi.assignments.last).to be_new_record
    expect(@gi.assignments.last.id).to be < 0
    expect(@gi.missing_assignments).to eq [@assignment3]
  end

  it "parses CSVs with the SIS Login ID column" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course: course, user: @user, progress: progress)
    importer = GradebookImporter.new(
      upload, valid_gradebook_contents_with_sis_login_id, user, progress
    )

    expect{importer.parse!}.not_to raise_error
  end

  it "parses CSVs with semicolons" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course: course, user: @user, progress: progress)
    new_gradebook_importer(
      attachment_with_rows(
        'Student;ID;Section;An Assignment',
        'A Student;1;Section 13;2',
        'Another Student;2;Section 13;10'
      ),
      upload,
      user,
      progress
    )
    expect(upload.gradebook["students"][1]["name"]).to eql 'Another Student'
  end

  it "parses CSVs with commas" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course: course, user: @user, progress: progress)
    new_gradebook_importer(
      attachment_with_rows(
        'Student,ID,Section,An Assignment',
        'A Student,1,Section 13,2',
        'Another Student,2,Section 13,10'
      ),
      upload,
      user,
      progress
    )
    expect(upload.gradebook["students"][1]["name"]).to eql 'Another Student'
  end

  it "does not include missing assignments if no new assignments" do
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

  it "does not include assignments with no changes" do
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

  it "includes assignments that changed only in points possible" do
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

  it "does not create assignments for the totals columns" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
        "Student,ID,Section,Assignment 1,Current Points,Final Points,Current Score,Final Score,Final Grade",
        "Points Possible,,,20,,,,,"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to be_empty
  end

  it "does not create assignments for unposted columns" do
    course_model
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1,Current Points,Final Points,Unposted Current Score," \
        "Unposted Final Score,Unposted Final Grade",
      "Points Possible,,,20,,,,,"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to be_empty
  end

  it "parses new and existing users" do
    course_with_student(active_all: true)
    @student1 = @student
    e = student_in_course
    e.update_attribute :workflow_state, 'completed'
    concluded_student = @student
    @student2 = user_factory
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

  it "does not include assignments that don't have any grade changes" do
    course_with_student
    course_with_teacher(course: @course)
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, grade: 10, grader: @teacher)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq []
  end

  it "includes assignments that the grade changed for an existing user" do
    course_with_student(active_all: true)
    @assignment1 = @course.assignments.create!(:name => 'Assignment 1', :points_possible => 10)
    @assignment1.grade_student(@student, grade: 8, grader: @teacher)
    importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq [@assignment1]
    submission = @gi.upload.gradebook.fetch('students').first.fetch('submissions').first
    expect(submission['original_grade']).to eq '8.0'
    expect(submission['grade']).to eq '10'
    expect(submission['assignment_id']).to eq @assignment1.id
  end

  context "custom gradebook columns" do
    before do
      @student = User.create!
      course_with_student(course: @course, user: @student, active_enrollment: true)
      @course.custom_gradebook_columns.create!({title: "CustomColumn1", read_only: false})
      @course.custom_gradebook_columns.create!({title: "CustomColumn2", read_only: false})
    end

    it "includes non read only custom columns" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 1,test 2,10"
      )
      col = @gi.upload.gradebook.fetch('custom_columns').map do |custom_column|
        custom_column.fetch('title')
      end
      expect(col).to eq ['CustomColumn1', 'CustomColumn2']
    end

    it "excludes read only custom columns" do
      @course.custom_gradebook_columns.create!({title: "CustomColumn3", read_only: true})
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,CustomColumn3,Assignment 1",
        ",#{@student.id},,test 1,test 2,test 3,10"
      )
      col = @gi.upload.gradebook.fetch('custom_columns').find { |custom_column| custom_column.fetch('title') == 'CustomColumn3' }
      expect(col).to eq nil
    end

    it "expects custom column datum from non read only columns" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 1,test 2,10"
      )
      col = @gi.upload.gradebook.fetch('students').first.fetch('custom_column_data').map { |custom_column| custom_column.fetch('new_content') }
      expect(col).to eq ['test 1', 'test 2']
    end
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
        keys = [:assignments,
                :custom_columns,
                :missing_objects,
                :original_submissions,
                :students,
                :unchanged_assignments,
                :warning_messages]
        expect(hash.keys.sort).to eql(keys)
      end

      it "a student only has specified keys" do
        keys = [:custom_column_data, :id, :last_name_first, :name, :previous_id, :submissions]
        expect(student.keys.sort).to eql(keys)
      end

      it "a submission only has specified keys" do
        keys = ["assignment_id", "grade", "gradeable", "original_grade"]
        expect(submission.keys.sort).to eql(keys)
      end

      it "an assignment only has specified keys" do
        keys = [:grading_type, :id, :points_possible, :previous_id,
                :title]
        expect(assignment.keys.sort).to eql(keys)
      end
    end
  end

  context "moderated assignments" do
    let(:course) { course_model }
    let(:user) do
      user = User.create!
      course.enroll_teacher(user).accept!
      user
    end
    let(:progress) { Progress.create!(tag: "test", context: user) }

    before :each do
      @existing_moderated_assignment = Assignment.create!(
        context: course,
        name: 'An Assignment',
        moderated_grading: true,
        grader_count: 1
      )
    end

    it "allows importing grades of assignments when user is final grader" do
      @existing_moderated_assignment.update!(final_grader: user)
      upload = GradebookUpload.create!(course: course, user: user, progress: progress)
      new_gradebook_importer(
        attachment_with_rows(
          'Student;ID;Section;An Assignment',
          'A Student;1;Section 13;2',
          'Another Student;2;Section 13;10'
        ),
        upload,
        user,
        progress
      )
      expect(upload.gradebook["students"][1]["submissions"][0]["gradeable"]).to be true
    end

    it "does not allow importing grades of assignments when user is not final grader" do
      upload = GradebookUpload.create!(course: course, user: user, progress: progress)
      new_gradebook_importer(
        attachment_with_rows(
          'Student;ID;Section;An Assignment',
          'A Student;1;Section 13;2',
          'Another Student;2;Section 13;10'
        ),
        upload,
        user,
        progress
      )
      expect(upload.gradebook["students"][1]["submissions"][0]["gradeable"]).to be false
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

    it "ignores submissions for students without visibility" do
      @assignment_one.grade_student(@student_one, grade: "3", grader: @teacher)
      @assignment_two.grade_student(@student_two, grade: "3", grader: @teacher)
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

    it "does not break the creation of new assignments" do
      importer_with_rows(
          "Student,ID,Section,a1,a2,a3",
          "#{@student_one.name},#{@student_one.id},,1,2,3"
      )
      expect(@gi.assignments.last.title).to eq 'a3'
      expect(@gi.assignments.last).to be_new_record
      expect(@gi.assignments.last.id).to be < 0
      submissions = @gi.as_json[:students][0][:submissions]
      expect(submissions.length).to eq(2)
      expect(submissions.first["grade"]).to eq "1"
      expect(submissions.last["grade"]).to eq "3"
    end
  end

  context "with grading periods" do
    before(:once) do
      account = Account.default
      @course = account.courses.create!
      @teacher = User.create!
      course_with_teacher(course: @course, user: @teacher, active_enrollment: true)
      group = account.grading_period_groups.create!
      group.enrollment_terms << @course.enrollment_term
      @now = Time.zone.now
      @closed_period = group.grading_periods.create!(
        title: "Closed Period",
        start_date: 3.months.ago(@now),
        end_date: 1.month.ago(@now),
        close_date: 1.month.ago(@now)
      )

      @active_period = group.grading_periods.create!(
        title: "Active Period",
        start_date: 1.month.ago(@now),
        end_date: 2.months.from_now(@now),
        close_date: 2.months.from_now(@now)
      )

      @closed_assignment = @course.assignments.create!(
        name: "Assignment in closed period",
        points_possible: 10,
        due_at: date_in_closed_period
      )

      @open_assignment = @course.assignments.create!(
        name: "Assignment in open period",
        points_possible: 10,
        due_at: date_in_open_period
      )
    end

    let(:assignments) { @gi.as_json[:assignments] }
    let(:date_in_open_period) { 1.month.from_now(@now) }
    let(:date_in_closed_period) { 2.months.ago(@now) }
    let(:student_submissions) { @gi.as_json[:students][0][:submissions] }

    context "uploading submissions for existing assignments" do
      context "assignments without overrides" do
        before(:once) do
          @student = User.create!
          course_with_student(course: @course, user: @student, active_enrollment: true)
        end


        it "excludes entire assignments if no submissions for the assignment are being uploaded" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5",
          )
          assignment_ids = assignments.map { |a| a[:id] }
          expect(assignment_ids).to_not include @closed_assignment.id
        end

        it "includes assignments if there is at least one submission in the assignment being uploaded" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5",
          )
          assignment_ids = assignments.map { |a| a[:id] }
          expect(assignment_ids).to include @open_assignment.id
        end

        context "submissions already exist" do
          before(:once) do
            Timecop.freeze(@closed_period.end_date - 1.day) do
              @closed_assignment.grade_student(@student, grade: 8, grader: @teacher)
            end
            @open_assignment.grade_student(@student, grade: 8, grader: @teacher)
          end

          it "does not include submissions that fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5",
            )
            assignment_ids = student_submissions.map { |s| s['assignment_id'] }
            expect(assignment_ids).to_not include @closed_assignment.id
          end

          it "includes submissions that do not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5",
            )
            assignment_ids = student_submissions.map { |s| s['assignment_id'] }
            expect(assignment_ids).to include @open_assignment.id
          end
        end


        context "submissions do not already exist" do
          it "does not include submissions that will fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5",
            )
            expect(student_submissions.map {|s| s['assignment_id']}).to_not include @closed_assignment.id
          end

          it "includes submissions that will not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5",
            )
            expect(student_submissions.map {|s| s['assignment_id']}).to include @open_assignment.id
          end
        end

        it "marks excused submission as 'EX' even if 'ex' is not capitalized" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,,eX",
          )
          expect(student_submissions.first.fetch('grade')).to eq 'EX'
        end
      end

      context "assignments with overrides" do
        before(:once) do
          section_one = @course.course_sections.create!(name: 'Section One')
          @student = student_in_section(section_one)

          # set up overrides such that the student has a due date in an open grading period
          # for @closed_assignment and a due date in a closed grading period for @open_assignment
          @override_in_open_grading_period = @closed_assignment.assignment_overrides.create! do |override|
            override.set = section_one
            override.due_at_overridden = true
            override.due_at = date_in_open_period
          end

          @open_assignment.assignment_overrides.create! do |override|
            override.set = section_one
            override.due_at_overridden = true
            override.due_at = date_in_closed_period
          end
        end

        it "excludes entire assignments if there are no submissions in the assignment" \
        "being uploaded that are gradeable" do
          @override_in_open_grading_period.update_attribute(:due_at, date_in_closed_period)
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5"
          )
          assignment_ids = assignments.map { |a| a[:id] }
          expect(assignment_ids).not_to include @closed_assignment.id
        end

        it "includes assignments if there is at least one submission in the assignment" \
        "being uploaded that is gradeable (it does not fall in a closed grading period)" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5"
          )
          assignment_ids = assignments.map { |a| a[:id] }
          expect(assignment_ids).to include @closed_assignment.id
        end

        context "submissions already exist" do
          before(:once) do
            Timecop.freeze(@closed_period.end_date - 1.day) do
              @closed_assignment.grade_student(@student, grade: 8, grader: @teacher)
              @open_assignment.grade_student(@student, grade: 8, grader: @teacher)
            end
          end

          it "does not include submissions that fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.map { |s| s['assignment_id'] }
            expect(assignment_ids).not_to include @open_assignment.id
          end

          it "includes submissions that do not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.map { |s| s['assignment_id'] }
            expect(assignment_ids).to include @closed_assignment.id
          end
        end

        context "submissions do not already exist" do
          it "does not include submissions that will fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.map {|s| s['assignment_id']}
            expect(assignment_ids).to_not include @open_assignment.id
          end

          it "includes submissions that will not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.map {|s| s['assignment_id']}
            expect(assignment_ids).to include @closed_assignment.id
          end
        end
      end
    end

    context "uploading submissions for new assignments" do
      before(:once) do
        @student = User.create!
        course_with_student(course: @course, user: @student, active_enrollment: true)
      end

      it "does not create a new assignment if the last grading period is closed" do
        @active_period.destroy!
        importer_with_rows(
          "Student,ID,Section,Some new assignment",
          ",#{@student.id},,5",
        )
        expect(assignments.count).to eq(0)
      end

      it "creates a new assignment if the last grading period is not closed" do
        importer_with_rows(
          "Student,ID,Section,Some new assignment",
          ",#{@student.id},,5",
        )
        expect(assignments.count).to eq(1)
      end
    end
  end

  describe "#translate_pass_fail" do
    let(:account) { Account.default }
    let(:course) { Course.create account: account }
    let(:student) do
      student = User.create
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

    it "translates positive score in gradebook_importer_assignments grade to complete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "3", "original_grade" => ""}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first['grade']

      expect(grade).to eq "complete"
    end

    it "translates positive grade in gradebook_importer_assignments original_grade to complete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "5"}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first['original_grade']

      expect(original_grade).to eq "complete"
    end

    it "translates 0 grade in gradebook_importer_assignments grade to incomplete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "0", "original_grade" => ""}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first['grade']

      expect(grade).to eq "incomplete"
    end

    it "translates 0 grade in gradebook_importer_assignments original_grade to incomplete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "0"}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first['original_grade']

      expect(original_grade).to eq "incomplete"
    end

    it "doesn't change empty string grade in gradebook_importer_assignments grade" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => ""}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first['grade']

      expect(grade).to eq ""
    end

    it "doesn't change empty string grade in gradebook_importer_assignments original_grade" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => ""}] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first['original_grade']

      expect(original_grade).to eq ""
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
    allow(a).to receive(:open).and_return(file)
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
end
