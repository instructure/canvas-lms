# frozen_string_literal: true

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

require_relative "../spec_helper"

describe GradebookImporter do
  let(:gradebook_user) do
    teacher = User.create!
    course_with_teacher(user: teacher, course: @course)
    teacher
  end

  context "construction" do
    let!(:gradebook_course) { course_model }

    it "requires a context, usually a course" do
      user = user_model
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.new
      expect { GradebookImporter.new(upload) }
        .to raise_error(ArgumentError, "Must provide a valid context for this gradebook.")
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress:)
      expect { GradebookImporter.new(upload, valid_gradebook_contents, user, progress) }
        .not_to raise_error
    end

    it "stores the context and make it available" do
      new_gradebook_importer
      expect(@gi.context).to be_is_a(Course)
    end

    it "requires the contents of an upload" do
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress:)
      expect { GradebookImporter.new(upload) }
        .to raise_error(ArgumentError, "Must provide attachment.")
    end

    it "handles points possible being sorted in weird places" do
      importer_with_rows(
        "Student,ID,Section,Assignment 1,Final Score",
        '"Blend, Bill",6,My Course,-,',
        "Points Possible,,,10,",
        '"Farner, Todd",4,My Course,-,'
      )
      expect(@gi.assignments.length).to eq 1
      expect(@gi.assignments.first.points_possible).to eq 10
      expect(@gi.students.length).to eq 2
    end

    it "handles muted line and being sorted in weird places" do
      importer_with_rows(
        "Student,ID,Section,Assignment 1,Final Score",
        '"Blend, Bill",6,My Course,-,',
        "Points Possible,,,10,",
        ", ,,Muted,",
        '"Farner, Todd",4,My Course,-,'
      )
      expect(@gi.assignments.length).to eq 1
      expect(@gi.assignments.first.points_possible).to eq 10
      expect(@gi.students.length).to eq 2
    end

    it "ignores the line denoting manually posted assignments if present" do
      importer_with_rows(
        "Student,ID,Section,Assignment 1,Final Score",
        "Points Possible,,,10,",
        ", ,,Manual Posting,",
        '"Blend, Bill",6,My Course,-,',
        '"Farner, Todd",4,My Course,-,'
      )
      expect(@gi.students.length).to eq 2
    end

    it "expects and deals with invalid upload files" do
      user = user_model
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.new
      upload = GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress:)
      expect do
        GradebookImporter.create_from(progress, upload, user, invalid_gradebook_contents)
      end.to raise_error(Delayed::RetriableError)
    end

    it "ignores the line denoting manually posted anonymous assignments if present" do
      importer_with_rows(
        "Student,ID,Section,Assignment 1,Final Score",
        "Points Possible,,,10,",
        ", ,,Manual Posting (scores cachés aux instructeurs),",
        '"Blend, Bill",6,My Course,-,',
        '"Farner, Todd",4,My Course,-,'
      )
      expect(@gi.students.length).to eq 2
    end

    context "when dealing with a file containing semicolon field separators" do
      context "with interspersed commas to throw you off" do
        before do
          @rows = [
            "Student;ID;Section;Aufgabe 1;Aufgabe 2;Final Score",
            "Points Possible;;;10000,54;100,00;",
            '"Merkel 1,0, Angela";1;Mein Kurs;123,4;57,4%;',
            '"Einstein 1,1, Albert";2;Mein Kurs;1.234,5;4.200,3%;',
            '"Curie, Marie";3;Mein Kurs;12.34,5;4.20.0,3%;',
            '"Planck, Max";4;Mein Kurs;-1.234,50;-4.200,30%;',
            '"Bohr, Neils";5;Mein Kurs;1.234.5;4.200.3%;',
            '"Dirac, Paul";6;Mein Kurs;1,234,5;4,200,3%;'
          ]

          importer_with_rows(*@rows)
        end

        it "parses out assignments only" do
          expect(@gi.assignments.length).to eq 2
        end

        it "parses out points_possible correctly" do
          expect(@gi.assignments.first.points_possible).to eq(10_000.54)
        end

        it "parses out students correctly" do
          expect(@gi.students.length).to eq 6
        end

        it "does not reformat numbers that are part of strings" do
          expect(@gi.students.first.name).to eq("Merkel 1,0, Angela")
        end

        it "normalizes pure numbers" do
          expected_grades = %w[123.4 1234.5 1234.5 -1234.50 1234.5 1234.5]
          actual_grades = @gi.upload.gradebook.fetch("students").map { |student| student.fetch("submissions").first.fetch("grade") }

          expect(actual_grades).to match_array(expected_grades)
        end

        it "normalizes percentages" do
          expected_grades = %w[57.4% 4200.3% 4200.3% -4200.30% 4200.3% 4200.3%]
          actual_grades = @gi.upload.gradebook.fetch("students").map { |student| student.fetch("submissions").second.fetch("grade") }

          expect(actual_grades).to match_array(expected_grades)
        end
      end

      context "without any interspersed commas" do
        before do
          @rows = [
            "Student;ID;Section;Aufgabe 1;Aufgabe 2;Final Score",
            "Points Possible;;;10000,54;100,00;",
            '"Angela Merkel";1;Mein Kurs;123,4;57,4%;',
            '"Albert Einstein";2;Mein Kurs;1.234,5;4.200,3%;',
            '"Marie Curie";3;Mein Kurs;12.34,5;4.20.0,3%;',
            '"Max Planck";4;Mein Kurs;-1.234,50;-4.200,30%;',
            '"Neils Bohr";5;Mein Kurs;1.234.5;4.200.3%;',
            '"Paul Dirac";6;Mein Kurs;1,234,5;4,200,3%;'
          ]

          importer_with_rows(*@rows)
        end

        it "parses out assignments only" do
          expect(@gi.assignments.length).to eq 2
        end

        it "parses out points_possible correctly" do
          expect(@gi.assignments.first.points_possible).to eq(10_000.54)
        end

        it "parses out students correctly" do
          expect(@gi.students.length).to eq 6
        end

        it "does not reformat numbers that are part of strings" do
          expect(@gi.students.first.name).to eq("Angela Merkel")
        end

        it "normalizes pure numbers" do
          expected_grades = %w[123.4 1234.5 1234.5 -1234.50 1234.5 1234.5]
          actual_grades = @gi.upload.gradebook.fetch("students").map { |student| student.fetch("submissions").first.fetch("grade") }

          expect(actual_grades).to match_array(expected_grades)
        end

        it "normalizes percentages" do
          expected_grades = %w[57.4% 4200.3% 4200.3% -4200.30% 4200.3% 4200.3%]
          actual_grades = @gi.upload.gradebook.fetch("students").map { |student| student.fetch("submissions").second.fetch("grade") }

          expect(actual_grades).to match_array(expected_grades)
        end
      end
    end

    context "when dealing with a file containing comma field separators" do
      let(:rows) do
        [
          "Student,ID,Section,Assignment 1,Assignment 2,Final Score",
          "Points Possible,,,1000,50000,",
          'C. Iulius Caesar,1,,123.43,"45,678.12",99%',
          'Cn. Pompeius Magnus,2,,"123,32","45.678,23",99%',
        ]
      end

      let(:importer) { importer_with_rows(rows) }
      let(:students) { importer.upload.gradebook.fetch("students") }

      context "with values that use a period as a decimal separator" do
        let(:grades) { students.first.fetch("submissions").map { |submission| submission.fetch("grade") } }

        it "normalizes values with no thousands separator" do
          expect(grades.first).to eq "123.43"
        end

        it "normalizes values using a comma as the thousands separator" do
          expect(grades.second).to eq "45678.12"
        end
      end

      context "with values that use a comma as the decimal separator" do
        let(:grades) { students.second.fetch("submissions").map { |submission| submission.fetch("grade") } }

        it "normalizes values with no thousands separator" do
          expect(grades.first).to eq "123.32"
        end

        it "normalizes values using a period as the thousands separator" do
          expect(grades.second).to eq "45678.23"
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

      let(:progress) { Progress.create!(tag: "test", context: gradebook_user) }

      let(:upload) do
        GradebookUpload.create!(course: gradebook_course, user: gradebook_user, progress:)
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

      student_in_course(name: "Some Name", active_all: true)
      @u1 = @user

      user_with_pseudonym(active_all: true)
      @user.pseudonym.sis_user_id = "SISUSERID"
      @user.pseudonym.save!
      student_in_course(user: @user, active_all: true)
      @u2 = @user

      user_with_pseudonym(active_all: true, username: "something_that_has_not_been_taken")
      student_in_course(user: @user, active_all: true)
      @u3 = @user

      user_with_pseudonym(active_all: true, username: "inactive_login")
      @user.pseudonym.destroy
      student_in_course(user: @user, active_all: true)
      @u4 = @user

      user_with_pseudonym(active_all: true, username: "inactive_login")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(unique_id: "active_login", account: Account.default)
      student_in_course(user: @user, active_all: true)
      @u5 = @user

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "", "", ""]
        csv << [@u1.name, "", "", "", "", 99]
        csv << ["", "", @u2.pseudonym.sis_user_id, "", "", 99]
        csv << ["", "", "", @u3.pseudonym.unique_id, "", 99]
        csv << ["", "", "", "inactive_login", "", 99]
        csv << ["", "", "", "active_login", "", 99]
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

      expect(hash[:students][5][:id]).to be < 0
      expect(hash[:students][5][:previous_id]).to be_nil
    end

    it "Lookups by root account" do
      course_model

      student_in_course(name: "Some Name", active_all: true)
      @u1 = @user

      account2 = Account.create!
      p = @u1.pseudonyms.create!(account: account2, unique_id: "uniqueid")
      p.sis_user_id = "SISUSERID"
      p.save!
      expect(Account).to receive(:find_by_domain).with("account2").and_return(account2)

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Root Account", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "", "", "", ""]
        csv << ["", "", @u1.pseudonym.sis_user_id, "", "account2", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq @u1.id
      expect(hash[:students][0][:previous_id]).to eq @u1.id
      expect(hash[:students][0][:name]).to eql(@u1.name)
    end

    it "ignores integration_id when present" do
      course_model
      student_in_course(name: "Some Name", active_all: true)
      u1 = @user

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Integration ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "", "", "", ""]
        csv << ["", u1.id, "", "", "", "", 99]
      end

      importer_with_rows(uploaded_csv)
      hash = @gi.as_json

      expect(hash[:students][0][:id]).to eq u1.id
      expect(hash[:students][0][:previous_id]).to eq u1.id
      expect(hash[:students][0][:name]).to eql(u1.name)
    end

    it "allows ids that look like numbers" do
      course_model

      user_with_pseudonym(active_all: true)
      @user.pseudonym.sis_user_id = "0123456"
      @user.pseudonym.save!
      student_in_course(user: @user, active_all: true)
      @u0 = @user

      # user with an sis-id that is a number
      user_with_pseudonym(active_all: true, username: "octal_ud")
      @user.pseudonym.destroy
      @user.pseudonyms.create!(unique_id: "0231163", account: Account.default)
      student_in_course(user: @user, active_all: true)
      @u1 = @user

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Assignment 1"]
        csv << ["    Points Possible", "", "", "", ""]
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
      expect(@progress.message).to eq "Invalid header row"
    end
  end

  it "strips leading and trailing spaces from grades" do
    rows = [
      "Student;ID;Section;Aufgabe 1;Aufgabe 2;Final Score",
      "Points Possible;;;10000,54;100,00;",
      "'Merkel, Angela';1;Mein Kurs; 123,4;57,4%;",
      "'Einstein, Albert';2;Mein Kurs;1234,5 ;4.200,3%;"
    ]

    importer = importer_with_rows(*rows)
    grades = importer.upload.gradebook.fetch("students").map { |s| s.fetch("submissions").first.fetch("grade") }
    expect(grades).to match_array ["123,4", "1234,5"]
  end

  it "parses new and existing assignments" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1")
    @assignment3 = @course.assignments.create!(name: "Assignment 3")
    importer_with_rows(
      "Student,ID,Section,Assignment 1,Assignment 2",
      "Some Student,,,,"
    )
    expect(@gi.assignments.length).to eq 2
    expect(@gi.assignments.first).to eq @assignment1
    expect(@gi.assignments.last.title).to eq "Assignment 2"
    expect(@gi.assignments.last).to be_new_record
    expect(@gi.assignments.last.id).to be < 0
    expect(@gi.missing_assignments).to eq [@assignment3]
  end

  GradebookImporter::NON_ASSIGNMENT_COLUMN_HEADERS.each do |header|
    it "does not parse assignments with name that matches #{header}" do
      course = course_model
      @assignment1 = course.assignments.create!(name: "Assignment 1")
      @assignment2 = course.assignments.create!(name: header)

      importer_with_rows(
        "Student,ID,Section,Assignment 1,#{header}",
        "Some Student,,,,10"
      )

      expect(@gi.assignments).to eq [@assignment1]
    end
  end

  it "parses assignments correctly with existing custom columns" do
    course_model
    @assignment1 = @course.assignments.create! name: "Assignment 1"
    @assignment3 = @course.assignments.create! name: "Assignment 3"
    @custom_column1 = @course.custom_gradebook_columns.create! title: "Custom Column 1"

    importer_with_rows(
      "Student,ID,Section,Custom Column 1,Assignment 1,Assignment 2",
      "Some Student,,,,,"
    )

    expect(@gi.assignments.length).to eq 2
    expect(@gi.assignments.first).to eq @assignment1
    expect(@gi.assignments.last.title).to eq "Assignment 2"
    expect(@gi.assignments.last).to be_new_record
    expect(@gi.assignments.last.id).to be < 0
    expect(@gi.missing_assignments).to eq [@assignment3]
  end

  it "parses CSVs with the SIS Login ID column" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course:, user: @user, progress:)
    importer = GradebookImporter.new(
      upload, valid_gradebook_contents_with_sis_login_id, user, progress
    )

    expect { importer.parse! }.not_to raise_error
  end

  it "parses CSVs with semicolons" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course:, user: @user, progress:)
    new_gradebook_importer(
      attachment_with_rows(
        "Student;ID;Section;An Assignment",
        "A Student;1;Section 13;2",
        "Another Student;2;Section 13;10"
      ),
      upload,
      user,
      progress
    )
    expect(upload.gradebook["students"][1]["name"]).to eql "Another Student"
  end

  it "parses CSVs with commas" do
    course = course_model
    user = user_model
    progress = Progress.create!(tag: "test", context: @user)
    upload = GradebookUpload.create!(course:, user: @user, progress:)
    new_gradebook_importer(
      attachment_with_rows(
        "Student,ID,Section,An Assignment",
        "A Student,1,Section 13,2",
        "Another Student,2,Section 13,10"
      ),
      upload,
      user,
      progress
    )
    expect(upload.gradebook["students"][1]["name"]).to eql "Another Student"
  end

  it "parses arbitrarily ordered assignments" do
    course = course_model
    group1 = course.assignment_groups.create!(name: "first group", position: 1)
    group2 = course.assignment_groups.create!(name: "second group", position: 2)
    group3 = course.assignment_groups.create!(name: "third group", position: 3)

    assignment1 = course.assignments.create!(name: "Assignment 1", assignment_group: group1)
    assignment2 = course.assignments.create!(name: "Assignment 2", assignment_group: group2)
    assignment3 = course.assignments.create!(name: "Assignment 3", assignment_group: group3)

    importer_with_rows(
      "Student,ID,Section,Assignment 2,Assignment 3,Assignment 1",
      "Student 1,,,,,"
    )

    expect(@gi.assignments).to include(assignment1, assignment2, assignment3)
  end

  it "does not include missing assignments if no new assignments" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1")
    @assignment3 = @course.assignments.create!(name: "Assignment 3")
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      "Some Student,,,"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to eq []
  end

  it "does not include assignments with no changes" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1"
    )
    expect(@gi.assignments).to eq []
    expect(@gi.missing_assignments).to eq []
  end

  it "doesn't include readonly assignments" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    @assignment1 = @course.assignments.create!(name: "Assignment 2", points_possible: 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1,Readonly,Assignment 2",
      "    Points Possible,,,,(read only),"
    )
    expect(@gi.assignments).to eq []
    expect(@gi.missing_assignments).to eq []
  end

  it "includes assignments that changed only in points possible" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      "Points Possible,,,20"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.assignments.first).to be_changed
    expect(@gi.assignments.first.points_possible).to eq 20
  end

  it "does not create assignments for the totals columns after assignments" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    importer_with_rows(
      "Student,ID,Section,Assignment 1,Current Points,Final Points,Current Score,Final Score,Final Grade",
      "Points Possible,,,20,,,,,"
    )
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to be_empty
  end

  it "does not create assignments for arbitrarily placed totals columns" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    @assignment2 = @course.assignments.create!(name: "Assignment 2", points_possible: 10)
    importer_with_rows(
      "Student,ID,Section,Final Score,Assignment 1,Current Points,Assignment 2,Final Points,Current Score,Final Grade",
      "Points Possible,,,(read only),20,(read only),20,,,"
    )
    expect(@gi.assignments).to include(@assignment1, @assignment2)
    expect(@gi.assignments.map(&:title)).to_not include("Final Score", "Current Points")
    expect(@gi.missing_assignments).to be_empty
  end

  it "does not create assignments for unposted columns" do
    course_model
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    importer_with_rows(<<~CSV)
      Student,ID,Section,Assignment 1,Current Points,Final Points,Unposted Current Score,Unposted Final Score,Unposted Final Grade
      Points Possible,,,20,,,,,
    CSV
    expect(@gi.assignments).to eq [@assignment1]
    expect(@gi.missing_assignments).to be_empty
  end

  describe "override columns" do
    it "does not create assignments for the Override Score or Override Grade column" do
      course_model
      @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
      importer_with_rows(
        "Student,ID,Section,Assignment 1,Current Points,Final Points,Override Score,Override Grade",
        "Points Possible,,,20,,,,"
      )

      aggregate_failures do
        expect(@gi.assignments).to eq [@assignment1]
        expect(@gi.missing_assignments).to be_empty
      end
    end
  end

  it "parses new and existing users" do
    course_with_student(active_all: true)
    @student1 = @student
    e = student_in_course
    e.update_attribute :workflow_state, "completed"
    concluded_student = @student
    @student2 = user_factory
    @course.enroll_student(@student2)
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      ",#{@student1.id},,10",
      "New Student,,,12",
      ",#{concluded_student.id},,10"
    )
    expect(@gi.students.length).to eq 2 # doesn't include concluded_student
    expect(@gi.students.first).to eq @student1
    expect(@gi.students.last).to be_new_record
    expect(@gi.students.last.id).to be < 0
    expect(@gi.missing_students).to eq [@student2]
  end

  it "does not include assignments that don't have any grade changes" do
    course_with_student
    course_with_teacher(course: @course)
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    @assignment1.grade_student(@student, grade: 10, grader: @teacher)
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq []
  end

  it "checks for score changes at a precision of 2 decimal places" do
    course_with_student
    course_with_teacher(course: @course)
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    @assignment1.grade_student(@student, grade: 10.987, grader: @teacher)
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      ",#{@student.id},,10.99"
    )
    expect(@gi.assignments).to eq []
  end

  it "includes assignments that the grade changed for an existing user" do
    course_with_student(active_all: true)
    @assignment1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10)
    @assignment1.grade_student(@student, grade: 8, grader: @teacher)
    importer_with_rows(
      "Student,ID,Section,Assignment 1",
      ",#{@student.id},,10"
    )
    expect(@gi.assignments).to eq [@assignment1]
    submission = @gi.upload.gradebook.fetch("students").first.fetch("submissions").first
    expect(submission["original_grade"]).to eq "8.0"
    expect(submission["grade"]).to eq "10"
    expect(submission["assignment_id"]).to eq @assignment1.id
  end

  context "anonymous assignments" do
    before do
      @student = User.create!
      course_with_student(user: @student, active_all: true)
      @assignment = @course.assignments.create!(name: "Assignment 1", anonymous_grading: true, points_possible: 10)
      @assignment.grade_student(@student, grade: 8, grader: @teacher)
    end

    it "does not include grade changes for anonymous unposted assignments" do
      importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
      )
      expect(@gi.assignments).to be_empty
    end

    it "includes grade changes for anonymous posted assignments" do
      @assignment.post_submissions
      importer_with_rows(
        "Student,ID,Section,Assignment 1",
        ",#{@student.id},,10"
      )
      expect(@gi.assignments).not_to be_empty
    end
  end

  context "custom gradebook columns" do
    let(:uploaded_custom_columns) { @gi.upload.gradebook["custom_columns"] }
    let(:uploaded_student_custom_column_data) do
      student_data = @gi.upload.gradebook["students"].first
      student_data["custom_column_data"]
    end

    before do
      @student = User.create!
      course_with_student(course: @course, user: @student, active_enrollment: true)
      @course.custom_gradebook_columns.create!({ title: "CustomColumn1", read_only: false })
      @course.custom_gradebook_columns.create!({ title: "CustomColumn2", read_only: false })
    end

    it "includes non read only custom columns" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 1,test 2,10"
      )
      col = @gi.upload.gradebook.fetch("custom_columns").map do |custom_column|
        custom_column.fetch("title")
      end
      expect(col).to eq ["CustomColumn1", "CustomColumn2"]
    end

    it "excludes read only custom columns" do
      @course.custom_gradebook_columns.create!({ title: "CustomColumn3", read_only: true })
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,CustomColumn3,Assignment 1",
        ",#{@student.id},,test 1,test 2,test 3,10"
      )
      col = @gi.upload.gradebook.fetch("custom_columns").find { |custom_column| custom_column.fetch("title") == "CustomColumn3" }
      expect(col).to be_nil
    end

    it "excludes hidden custom columns" do
      @course.custom_gradebook_columns.create!({ title: "CustomColumn3", workflow_state: :hidden })
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,CustomColumn3,Assignment 1",
        ",#{@student.id},,test 1,test 2,test 3,10"
      )
      col = @gi.upload.gradebook.fetch("custom_columns").find { |custom_column| custom_column.fetch("title") == "CustomColumn3" }
      expect(col).to be_nil
    end

    GradebookImporter::GRADEBOOK_IMPORTER_RESERVED_NAMES.each do |reserved_column|
      it "excludes custom columns with reserved importer column #{reserved_column}" do
        # The custom columns have a validation to prevent this, but since this was allowed for a long time, we will skip
        # the validation that blocks us from creating bad column names.
        build_col = @course.custom_gradebook_columns.build({ title: reserved_column, read_only: false })
        build_col.save!(validate: false)

        importer_with_rows(
          "Student,ID,Section,CustomColumn1,CustomColumn2,#{reserved_column},Assignment 1",
          ",#{@student.id},,test 1,test 2,test 3,10"
        )
        col = @gi.upload.gradebook.fetch("custom_columns").find { |custom_column| custom_column.fetch("title") == reserved_column }
        expect(col).to be_nil
      end
    end

    it "expects custom column datum from non read only columns" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 1,test 2,10"
      )
      col = @gi.upload.gradebook.fetch("students").first.fetch("custom_column_data").map { |custom_column| custom_column.fetch("new_content") }
      expect(col).to eq ["test 1", "test 2"]
    end

    it "does not capture custom columns that are not included in the import" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 2,10"
      )
      expect(uploaded_custom_columns).not_to include(hash_including(title: "CustomColumn1"))
    end

    it "does not attempt to change the values of custom columns that are not included in the import" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn2,Assignment 1",
        ",#{@student.id},,test 2,10"
      )

      column = @course.custom_gradebook_columns.find_by(title: "CustomColumn1")
      expect(uploaded_student_custom_column_data).not_to include(hash_including(column_id: column.id))
    end

    it "captures new values even if custom columns are in different positions" do
      importer_with_rows(
        "Student,ID,Section,CustomColumn2,CustomColumn1,Assignment 1",
        ",#{@student.id},,test 2,test 1,10"
      )

      column = @course.custom_gradebook_columns.find_by(title: "CustomColumn2")
      column_datum = uploaded_student_custom_column_data.detect { |datum| datum["column_id"] == column.id }
      expect(column_datum["new_content"]).to eq "test 2"
    end

    it "gradebook importer does not recognize any changes when the previous cell is empty and empty spaces are added to the cell" do
      @student2 = User.create(name: "Jim", id: 2)
      @course.enroll_student(@student2)
      importer_with_rows(
        "Student,ID,Section,Notes,Assignment 1,Assignment 2",
        "#{@student.name},,,,,",
        "Jim,,,   ,,"
      )
      expect(@gi.instance_variable_get(:@gradebook_importer_custom_columns)[2].empty?).to be true
    end

    it "gradebook importer recognizes any changes to custom column values when the first student has no value in the column" do
      @student2 = User.create(name: "Jim", id: 2)
      @course.enroll_student(@student2)
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        "#{@student.name},,,,,",
        "Jim,,,hello world,,"
      )
      expect(@gi.instance_variable_get(:@gradebook_importer_custom_columns)[2].empty?).to be false
    end

    it "gradebook importer will not mark the first student as changed if only empty spaces are added and there is a change to another student's value in the custom column" do
      @student2 = User.create(name: "Jim", id: 2)
      @course.enroll_student(@student2)
      importer_with_rows(
        "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
        "#{@student.name},,,   ,,",
        "Jim,,,hello world,,"
      )
      column = @course.custom_gradebook_columns.find_by(title: "CustomColumn1")
      column_datum = uploaded_student_custom_column_data.detect { |datum| datum["column_id"] == column.id }
      expect(column_datum["new_content"]).to be_nil
      expect(column_datum["current_content"]).to be_nil
    end

    context "with a deleted custom column" do
      before do
        @course.custom_gradebook_columns.find_by(title: "CustomColumn1").destroy
      end

      it "omits deleted custom columns when they are included in the import" do
        importer_with_rows(
          "Student,ID,Section,CustomColumn1,CustomColumn2,Assignment 1",
          ",#{@student.id},,test 1,test 2,10"
        )

        expect(uploaded_custom_columns.pluck(:title)).not_to include("CustomColumn1")
      end

      it "ignores deleted custom columns when they are not included in the import" do
        importer_with_rows(
          "Student,ID,Section,CustomColumn2,Assignment 1",
          ",#{@student.id},,test 2,10"
        )

        expect(uploaded_custom_columns.pluck(:title)).not_to include("CustomColumn1")
      end

      it "supplies the expected new values for non-deleted columns" do
        importer_with_rows(
          "Student,ID,Section,CustomColumn2,Assignment 1",
          ",#{@student.id},,NewCustomColumnValue,10"
        )

        expect(uploaded_student_custom_column_data.first["new_content"]).to eq "NewCustomColumnValue"
      end

      it "supplies the expected current values for non-deleted columns" do
        active_column = @course.custom_gradebook_columns.find_by(title: "CustomColumn2")
        active_column.custom_gradebook_column_data.create!(user_id: @student.id, content: "OldCustomColumnValue")

        importer_with_rows(
          "Student,ID,Section,CustomColumn2,Assignment 1",
          ",#{@student.id},,NewCustomColumnValue,10"
        )

        expect(uploaded_student_custom_column_data.first["current_content"]).to eq "OldCustomColumnValue"
      end
    end
  end

  context "to_json" do
    before do
      course_model
    end

    let(:hash) { new_gradebook_importer.as_json }
    let(:student)     { hash[:students].first }
    let(:submission)  { student[:submissions].first }
    let(:assignment)  { hash[:assignments].first }

    describe "simplified json output" do
      let(:top_level_keys) do
        %i[
          assignments
          custom_columns
          missing_objects
          original_submissions
          students
          unchanged_assignments
          warning_messages
        ]
      end

      let(:student_keys) { %i[custom_column_data id last_name_first name previous_id submissions] }

      it "has only the specified keys" do
        expect(hash.keys).to match_array(top_level_keys)
      end

      it "a student only has specified keys" do
        expect(student.keys).to match_array(student_keys)
      end

      context "importing override scores" do
        before do
          @course.enable_feature!(:final_grades_override)
          @course.allow_final_grade_override = true
          @course.save!
        end

        it "includes the override_scores key at the top level" do
          expect(hash.keys).to match_array(top_level_keys + [:override_scores] + [:override_statuses])
        end

        it "include the override_scores key for students" do
          expect(student.keys).to match_array(student_keys + [:override_scores] + [:override_statuses])
        end
      end

      it "a submission only has specified keys" do
        keys = %w[assignment_id grade gradeable original_grade]
        expect(submission.keys.sort).to eql(keys)
      end

      it "an assignment only has specified keys" do
        keys = %i[grading_type
                  id
                  points_possible
                  previous_id
                  title]
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

    before do
      @existing_moderated_assignment = Assignment.create!(
        context: course,
        name: "An Assignment",
        moderated_grading: true,
        grader_count: 1
      )
    end

    it "allows importing grades of assignments when user is final grader" do
      @existing_moderated_assignment.update!(final_grader: user)
      upload = GradebookUpload.create!(course:, user:, progress:)
      new_gradebook_importer(
        attachment_with_rows(
          "Student;ID;Section;An Assignment",
          "A Student;1;Section 13;2",
          "Another Student;2;Section 13;10"
        ),
        upload,
        user,
        progress
      )
      expect(upload.gradebook["students"][1]["submissions"][0]["gradeable"]).to be true
    end

    it "does not allow importing grades of assignments when user is not final grader" do
      upload = GradebookUpload.create!(course:, user:, progress:)
      new_gradebook_importer(
        attachment_with_rows(
          "Student;ID;Section;An Assignment",
          "A Student;1;Section 13;2",
          "Another Student;2;Section 13;10"
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
      @section_one = @course.course_sections.create!(name: "Section One")
      @section_two = @course.course_sections.create!(name: "Section Two")

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

    it "ignores submissions for students that are not assigned" do
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

    it "includes submissions for students that are assigned but do not have visibility (deactivated students)" do
      @assignment_one.grade_student(@student_one, grade: "3", grader: @teacher)
      @course.student_enrollments.find_by(user: @student_one).deactivate
      importer_with_rows(
        "Student,ID,Section,a1,a2",
        ",#{@student_one.id},#{@section_one.id},7,"
      )
      json = @gi.as_json
      expect(json[:students][0][:submissions][0]["grade"]).to eq "7"
    end

    it "does not break the creation of new assignments" do
      importer_with_rows(
        "Student,ID,Section,a1,a2,a3",
        "#{@student_one.name},#{@student_one.id},,1,2,3"
      )
      expect(@gi.assignments.last.title).to eq "a3"
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
            ",#{@student.id},,5,5"
          )
          assignment_ids = assignments.pluck(:id)
          expect(assignment_ids).to_not include @closed_assignment.id
        end

        it "includes assignments if there is at least one submission in the assignment being uploaded" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5"
          )
          assignment_ids = assignments.pluck(:id)
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
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.pluck("assignment_id")
            expect(assignment_ids).to_not include @closed_assignment.id
          end

          it "includes submissions that do not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.pluck("assignment_id")
            expect(assignment_ids).to include @open_assignment.id
          end
        end

        context "submissions do not already exist" do
          it "does not include submissions that will fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            expect(student_submissions.pluck("assignment_id")).to_not include @closed_assignment.id
          end

          it "includes submissions that will not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            expect(student_submissions.pluck("assignment_id")).to include @open_assignment.id
          end

          it "does not grade submissions that had no grade and were marked with '-' in the import" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,-,-"
            )
            expect(@gi.as_json[:students]).to be_empty
          end
        end

        it "marks excused submission as 'EX' even if 'ex' is not capitalized" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,,eX"
          )
          expect(student_submissions.first.fetch("grade")).to eq "EX"
        end
      end

      context "assignments with overrides" do
        before(:once) do
          section_one = @course.course_sections.create!(name: "Section One")
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
          assignment_ids = assignments.pluck(:id)
          expect(assignment_ids).not_to include @closed_assignment.id
        end

        it "includes assignments if there is at least one submission in the assignment" \
           "being uploaded that is gradeable (it does not fall in a closed grading period)" do
          importer_with_rows(
            "Student,ID,Section,Assignment in closed period,Assignment in open period",
            ",#{@student.id},,5,5"
          )
          assignment_ids = assignments.pluck(:id)
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
            assignment_ids = student_submissions.pluck("assignment_id")
            expect(assignment_ids).not_to include @open_assignment.id
          end

          it "includes submissions that do not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.pluck("assignment_id")
            expect(assignment_ids).to include @closed_assignment.id
          end
        end

        context "submissions do not already exist" do
          it "does not include submissions that will fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.pluck("assignment_id")
            expect(assignment_ids).to_not include @open_assignment.id
          end

          it "includes submissions that will not fall in closed grading periods" do
            importer_with_rows(
              "Student,ID,Section,Assignment in closed period,Assignment in open period",
              ",#{@student.id},,5,5"
            )
            assignment_ids = student_submissions.pluck("assignment_id")
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
          ",#{@student.id},,5"
        )
        expect(assignments.count).to eq(0)
      end

      it "creates a new assignment if the last grading period is not closed" do
        importer_with_rows(
          "Student,ID,Section,Some new assignment",
          ",#{@student.id},,5"
        )
        expect(assignments.count).to eq(1)
      end
    end
  end

  describe "#translate_pass_fail" do
    let(:account) { Account.default }
    let(:course) { Course.create! account: }
    let(:student) do
      student = User.create
      student
    end
    let(:assignment) do
      course.assignments.create!(name: "Assignment 1",
                                 grading_type: "pass_fail",
                                 points_possible: 6)
    end
    let(:assignments) { [assignment] }
    let(:students) { [student] }
    let(:progress) { Progress.create tag: "test", context: student }
    let(:gradebook_upload) { GradebookUpload.create!(course:, user: student, progress:) }
    let(:importer) { GradebookImporter.new(gradebook_upload, "", student, progress) }

    it "translates positive score in gradebook_importer_assignments grade to complete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "3", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "complete"
    end

    it "translates positive grade in gradebook_importer_assignments original_grade to complete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "5" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first["original_grade"]

      expect(original_grade).to eq "complete"
    end

    it "translates 0 grade in gradebook_importer_assignments grade to incomplete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "0", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "incomplete"
    end

    it "translates 0 grade in gradebook_importer_assignments original_grade to incomplete" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "0" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first["original_grade"]

      expect(original_grade).to eq "incomplete"
    end

    it "doesn't change empty string grade in gradebook_importer_assignments grade" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq ""
    end

    it "doesn't change empty string grade in gradebook_importer_assignments original_grade" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      original_grade = gradebook_importer_assignments.fetch(student.id).first["original_grade"]

      expect(original_grade).to eq ""
    end
  end

  describe "importing submissions as excused from CSV" do
    let(:account) { Account.default }
    let(:course) { Course.create! account: }
    let(:student) { User.create! }
    let(:teacher) do
      teacher = User.create!
      course.enroll_teacher(teacher).accept!
      teacher
    end
    let(:assignment) do
      course.assignments.create!(
        name: "Assignment 1",
        grading_type: "pass_fail",
        points_possible: 10
      )
    end
    let(:assignments) { [assignment] }
    let(:students) { [student] }
    let(:progress) { Progress.create! tag: "test", context: student }
    let(:gradebook_upload) { GradebookUpload.create!(course:, user: student, progress:) }
    let(:importer) { GradebookImporter.new(gradebook_upload, "", student, progress) }

    it "changes incomplete submission to excused when marked as 'EX' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "EX", "original_grade" => "incomplete" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes complete submission to excused when marked as 'EX' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "EX", "original_grade" => "complete" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes empty string grade to excused when marked as 'EX' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "EX", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes 0 grade to complete when marked as positive" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "8", "original_grade" => "0" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "complete"
    end

    it "changes points assignment to excused when marked as 'EX' in CSV" do
      course.assignments.create!(
        name: "Assignment 2",
        grading_type: "points",
        points_possible: 10
      )
      gradebook_importer_assignments = { student.id => [{ "grade" => "EX", "original_grade" => "8" }] }
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes incomplete submission to excused when marked as 'ex' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "ex", "original_grade" => "incomplete" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes complete submission to excused when marked as 'eX' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "eX", "original_grade" => "complete" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes empty string grade to excused when marked as 'ex' in CSV" do
      gradebook_importer_assignments = { student.id => [{ "grade" => "ex", "original_grade" => "" }] }
      importer.translate_pass_fail(assignments, students, gradebook_importer_assignments)
      grade = gradebook_importer_assignments.fetch(student.id).first["grade"]

      expect(grade).to eq "EX"
    end

    it "changes points assignment to excused when marked as 'Ex' in CSV" do
      course.assignments.create!(
        name: "Assignment 3",
        grading_type: "points",
        points_possible: 10
      )
      course.enroll_student(student, enrollment_state: "active")
      upload = GradebookUpload.create!(course:, user: teacher, progress:)
      importer = new_gradebook_importer(
        attachment_with_rows(
          "Student;ID;Section;Assignment 3",
          "A Student;#{student.id};Section 13;Ex"
        ),
        upload,
        teacher,
        progress
      )
      json = importer.as_json
      expect(json[:students][0][:submissions][0]["grade"]).to eq "EX"
    end
  end

  describe "student last and first names" do
    it "does not import when not allowed" do
      course = course_model
      user = user_model
      progress = Progress.create!(tag: "test", context: @user)
      upload = GradebookUpload.create!(course:, user: @user, progress:)
      importer = GradebookImporter.new(
        upload, valid_gradebook_contents_with_last_and_first_names, user, progress
      )

      expect { importer.parse! }.not_to raise_error
      expect(progress.message).to eq("Invalid header row")
      expect(progress.workflow_state).to eq("failed")
    end

    context "when allowed" do
      before(:once) do
        Account.site_admin.enable_feature!(:gradebook_show_first_last_names)
        course_model
        @course.account.settings[:allow_gradebook_show_first_last_names] = true
        @course.account.save!
      end

      it "handles students which do not already exist" do
        importer_with_rows(
          "LastName,FirstName,ID,Section,Assignment 1,Final Score",
          '"Blend","Bill",6,My Course,-,',
          "Points Possible,,,,10,",
          '"","Todd",4,My Course,-,',
          '"Cooper","",4,My Course,-,'
        )
        expect(@gi.assignments.length).to eq 1
        expect(@gi.assignments.first.points_possible).to eq 10
        expect(@gi.students.length).to eq 3
        expect(@gi.students[0].name).to eq "Bill Blend"
        expect(@gi.students[1].name).to eq "Todd"
        expect(@gi.students[2].name).to eq "Cooper"
      end

      context "enrolled students" do
        let(:student0) { User.create!(name: "Victor McDade") }
        let(:student1) { User.create!(name: "Jack Jarvis") }
        let(:student2) { User.create!(name: "Winston") }
        let(:student3) { User.create!(name: "Isa") }

        before do
          @course.enroll_student(student0, enrollment_state: "active")
          @course.enroll_student(student1, enrollment_state: "active")
          @course.enroll_student(student2, enrollment_state: "active")
          @course.enroll_student(student3, enrollment_state: "active")
        end

        it "recognizes last and first name columns" do
          importer = importer_with_rows(
            "LastName,FirstName,ID,Section,Assignment 1,Final Score",
            "Points Possible,,,,10,",
            "'McDade','Victor;,#{student0.id},My Course,-,60",
            "'Jarvis','Jack',#{student1.id},My Course,-,70",
            "'','Winston',#{student2.id},My Course,-,80",
            "'Isa','',#{student3.id},My Course,-,90"
          )

          output = importer.as_json

          aggregate_failures do
            expect(output[:students].length).to eq 4
            expect(output[:students][0][:name]).to eq "Victor McDade"
            expect(output[:students][0][:id]).to eq student0.id
            expect(output[:students][1][:name]).to eq "Jack Jarvis"
            expect(output[:students][1][:id]).to eq student1.id
            expect(output[:students][2][:name]).to eq "Winston"
            expect(output[:students][2][:id]).to eq student2.id
            expect(output[:students][3][:name]).to eq "Isa"
            expect(output[:students][3][:id]).to eq student3.id

            expect(output[:assignments].length).to eq 1
            expect(output[:assignments].first[:points_possible]).to eq 10
            expect(output[:assignments].first[:title]).to eq "Assignment 1"
          end
        end
      end
    end
  end

  describe "override score changes" do
    before(:once) do
      course_model
      @course.enable_feature!(:final_grades_override)
      @course.allow_final_grade_override = true
      @course.save!
    end

    let(:student_with_override) { User.create!(name: "Cyrus") }
    let(:student_without_override) { User.create!(name: "Ophilia") }

    before do
      @course.enroll_student(student_with_override, enrollment_state: "active")
      @course.enroll_student(student_without_override, enrollment_state: "active")

      # Run the grade calculator so Score objects get created
      @course.recompute_student_scores(run_immediately: true)
      student_with_override.enrollments.first.find_score.update!(override_score: 50.54)
    end

    it "recognizes changes to override scores" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,60"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students].length).to eq 1
        expect(output[:students].first.dig(:override_scores, 0, :current_score)).to eq "50.54"
        expect(output[:students].first.dig(:override_scores, 0, :new_score)).to eq "60"
        expect(output[:students].first.dig(:override_scores, 0, :grading_period_id)).to be_nil
      end
    end

    it "recognizes newly-added override scores" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Ophilia,#{student_without_override.id},My Course,0,70"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students].length).to eq 1
        expect(output[:students].first.dig(:override_scores, 0, :current_score)).to be_nil
        expect(output[:students].first.dig(:override_scores, 0, :new_score)).to eq "70"
        expect(output[:students].first.dig(:override_scores, 0, :grading_period_id)).to be_nil
      end
    end

    it "recognizes when override scores are removed" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students].length).to eq 1
        expect(output[:students].first.dig(:override_scores, 0, :current_score)).to eq "50.54"
        expect(output[:students].first.dig(:override_scores, 0, :new_score)).to be_nil
        expect(output[:students].first.dig(:override_scores, 0, :grading_period_id)).to be_nil
      end
    end

    it "compares scores with a maximum precision of two decimal places" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,50.5432"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students]).to be_empty
      end
    end

    it "returns no records when there are no override score changes" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,50.54"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students]).to be_empty
      end
    end

    it "returns records for all students if at least one student's grade changed" do
      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,50.54",
        "Ophilia,#{student_without_override.id},My Course,0,60"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students].length).to eq 2

        expect(output[:students].first.dig(:override_scores, 0, :current_score)).to eq "50.54"
        expect(output[:students].first.dig(:override_scores, 0, :new_score)).to eq "50.54"
        expect(output[:students].first.dig(:override_scores, 0, :grading_period_id)).to be_nil

        expect(output[:students].second.dig(:override_scores, 0, :current_score)).to be_nil
        expect(output[:students].second.dig(:override_scores, 0, :new_score)).to eq "60"
        expect(output[:students].second.dig(:override_scores, 0, :grading_period_id)).to be_nil
      end
    end

    it "ignores students with concluded enrollments" do
      student_with_override.enrollments.first.conclude

      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,10"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students]).to be_empty
      end
    end

    it "produces an empty result if there are no students" do
      student_with_override.enrollments.first.conclude

      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students]).to be_empty
      end
    end

    it "ignores the 'Override Grade' column even if a grading scheme is active" do
      @course.grading_standard_enabled = true
      @course.save!

      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Grade",
        "Cyrus,#{student_with_override.id},My Course,0,A+"
      )

      output = importer.as_json
      expect(output[:students]).to be_empty
    end

    context "for a course with grading periods" do
      before do
        enrollment_term = @course.root_account.enrollment_terms.create!
        @course.update!(enrollment_term:)

        grading_period_group = @course.root_account.grading_period_groups.create!
        grading_period_group.enrollment_terms << enrollment_term

        now = Time.zone.now
        grading_period_group.grading_periods.create!(
          close_date: now,
          end_date: now,
          start_date: 1.week.ago(now),
          title: "First GP"
        )
        grading_period_group.grading_periods.create!(
          close_date: 1.week.from_now(now),
          end_date: 1.week.from_now(now),
          start_date: now,
          title: "Second GP"
        )
      end

      let(:first_grading_period) { @course.root_account.grading_period_groups.first.grading_periods.first }
      let(:second_grading_period) { @course.root_account.grading_period_groups.first.grading_periods.second }

      it "handles override score changes for specific grading periods" do
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (First GP)",
          "Cyrus,#{student_with_override.id},My Course,0,70"
        )

        output = importer.as_json
        overrides = output[:students].first[:override_scores]

        aggregate_failures do
          expect(overrides.length).to eq 1
          expect(overrides.first[:grading_period_id]).to eq first_grading_period.id
          expect(overrides.first[:new_score]).to eq "70"
        end
      end

      it "handles multiple grading periods and course scores in the same input" do
        first_grading_period_score = student_with_override.enrollments.first.find_score({ grading_period_id: first_grading_period.id })
        first_grading_period_score.update!(override_score: 40.0)

        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (First GP),Override Score (Second GP),Override Score",
          "Cyrus,#{student_with_override.id},My Course,0,70,60,100"
        )
        output = importer.as_json
        overrides = output[:students].first[:override_scores]

        aggregate_failures do
          expect(overrides.length).to eq 3

          course_change = overrides.detect { |override| override[:grading_period_id].nil? }
          expect(course_change[:current_score]).to eq "50.54"
          expect(course_change[:new_score]).to eq "100"

          first_period_change = overrides.detect { |override| override[:grading_period_id] == first_grading_period.id }
          expect(first_period_change[:current_score]).to eq "40.0"
          expect(first_period_change[:new_score]).to eq "70"

          second_period_change = overrides.detect { |override| override[:grading_period_id] == second_grading_period.id }
          expect(second_period_change[:current_score]).to be_nil
          expect(second_period_change[:new_score]).to eq "60"
        end
      end

      it "filters out any grading periods with no changed override scores" do
        first_grading_period_score = student_with_override.enrollments.first.find_score({ grading_period_id: first_grading_period.id })
        first_grading_period_score.update!(override_score: 40.0)

        # Make changes to First GP and the course score; leave second GP alone
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (First GP),Override Score (Second GP),Override Score",
          "Cyrus,#{student_with_override.id},My Course,0,70,,100",
          "Ophilia,#{student_without_override.id},My Course,0,70,,"
        )
        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 2

          student1_overrides = output[:students].first[:override_scores]
          expect(student1_overrides.length).to eq 2

          student1_course_change = student1_overrides.detect { |override| override[:grading_period_id].nil? }
          expect(student1_course_change[:current_score]).to eq "50.54"
          expect(student1_course_change[:new_score]).to eq "100"

          student1_gp_change = student1_overrides.detect { |override| override[:grading_period_id] == first_grading_period.id }
          expect(student1_gp_change[:current_score]).to eq "40.0"
          expect(student1_gp_change[:new_score]).to eq "70"

          student2_overrides = output[:students].second[:override_scores]
          expect(student2_overrides.length).to eq 2

          student2_course_change = student2_overrides.detect { |override| override[:grading_period_id].nil? }
          expect(student2_course_change[:current_score]).to be_nil
          expect(student2_course_change[:new_score]).to be_nil

          student2_gp_change = student2_overrides.detect { |override| override[:grading_period_id] == first_grading_period.id }
          expect(student2_gp_change[:current_score]).to be_nil
          expect(student2_gp_change[:new_score]).to eq "70"
        end
      end

      it "ignores grading periods whose title it does not recognize" do
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (Unknown GP)",
          "Cyrus,#{student_with_override.id},My Course,0,40"
        )
        output = importer.as_json

        expect(output[:students]).to be_empty
      end

      it "ignores malformed 'Override Score' headers" do
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (zzzzzz",
          "Cyrus,#{student_with_override.id},My Course,0,40"
        )
        output = importer.as_json

        expect(output[:students]).to be_empty
      end

      it "treats an 'empty' grading period title as a course score" do
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score ()",
          "Cyrus,#{student_with_override.id},My Course,0,50"
        )
        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 1
          expect(output[:students].first.dig(:override_scores, 0, :current_score)).to eq "50.54"
          expect(output[:students].first.dig(:override_scores, 0, :new_score)).to eq "50"
          expect(output[:students].first.dig(:override_scores, 0, :grading_period_id)).to be_nil
        end
      end
    end

    context "when custom grading statuses exists" do
      before do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        @custom_grade_status = CustomGradeStatus.create!(name: "old status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
        @student_score = student_with_override.enrollments.first.find_score({ course_score: true })

        enrollment_term = @course.root_account.enrollment_terms.create!
        @course.update!(enrollment_term:)
        grading_period_group = @course.root_account.grading_period_groups.create!
        grading_period_group.enrollment_terms << enrollment_term

        now = Time.zone.now
        grading_period_group.grading_periods.create!(
          close_date: now,
          end_date: now,
          start_date: 1.week.ago(now),
          title: "First GP"
        )
      end

      let(:first_grading_period) { @course.root_account.grading_period_groups.first.grading_periods.first }

      it "recognizes a new override statuses" do
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,POTATO"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 1
          expect(output[:students].first.dig(:override_statuses, 0, :current_grade_status)).to be_nil
          expect(output[:students].first.dig(:override_statuses, 0, :new_grade_status)).to eq "POTATO"
          expect(output[:students].first.dig(:override_statuses, 0, :grading_period_id)).to be_nil
        end
      end

      it "recognizes a change to existing override statuses" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,POTATO"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 1
          expect(output[:students].first.dig(:override_statuses, 0, :current_grade_status)).to eq "old status"
          expect(output[:students].first.dig(:override_statuses, 0, :new_grade_status)).to eq "POTATO"
          expect(output[:students].first.dig(:override_statuses, 0, :grading_period_id)).to be_nil
        end
      end

      it "recognizes a change to existing override statuses with grading period" do
        first_grading_period_score = student_with_override.enrollments.first.find_score({ grading_period_id: first_grading_period.id })
        first_grading_period_score.update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status (#{first_grading_period.title})",
          "Cyrus,#{student_with_override.id},My Course,0,POTATO"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:override_statuses][:grading_periods].pluck(:id)).to contain_exactly(first_grading_period.id)
          expect(output[:students].length).to eq 1
          expect(output[:students].first.dig(:override_statuses, 0, :current_grade_status)).to eq "old status"
          expect(output[:students].first.dig(:override_statuses, 0, :new_grade_status)).to eq "POTATO"
          expect(output[:students].first.dig(:override_statuses, 0, :grading_period_id)).to eq first_grading_period.id
        end
      end

      it "recognizes setting a custom status to nil" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:override_statuses][:includes_course_score_status]).to be true
          expect(output[:students].length).to eq 1
          expect(output[:students].first.dig(:override_statuses, 0, :current_grade_status)).to eq "old status"
          expect(output[:students].first.dig(:override_statuses, 0, :new_grade_status)).to be_nil
          expect(output[:students].first.dig(:override_statuses, 0, :grading_period_id)).to be_nil
        end
      end

      it "does not output override statuses when custom statuses FF is OFF" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,POTATO"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when custom statuses FF is OFF and override status or grade columns not existing" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score",
          "Cyrus,#{student_with_override.id},My Course,0"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when custom statuses FF is OFF and override status column not existing" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score (First GP)",
          "Cyrus,#{student_with_override.id},My Course,0,70"
        )

        output = importer.as_json
        overrides = output[:students].first[:override_scores]

        aggregate_failures do
          expect(overrides.length).to eq 1
          expect(overrides.first[:grading_period_id]).to eq first_grading_period.id
          expect(overrides.first[:new_score]).to eq "70"
        end
      end

      it "does not output override statuses when allow_override_scores is false" do
        @course.allow_final_grade_override = false
        @course.save!
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,POTATO"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when there is no change" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,old status"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when there is no change and previous status was nil" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: nil)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when there is no change with case insensitive match" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,Old Status"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].length).to eq 0
        end
      end

      it "does not output override statuses when there is only a change to override score" do
        @student_score.update!(final_score: 0, override_score: 100, custom_grade_status: nil)
        importer = importer_with_rows(
          "Student,ID,Section,Final Score,Override Score,Override Status",
          "Cyrus,#{student_with_override.id},My Course,0,90,"
        )

        output = importer.as_json

        aggregate_failures do
          expect(output[:students].first[:override_statuses].length).to eq 0
        end
      end
    end

    it "handles changes to assignments and override scores in the same file" do
      importer = importer_with_rows(
        "Student,ID,Section,Assignment 1,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,20,0,60",
        "Ophilia,#{student_without_override.id},My Course,40,0,"
      )

      output = importer.as_json

      aggregate_failures do
        expect(output[:students].length).to eq 2

        student_with_override_data = output[:students].detect { |student| student[:id] == student_with_override.id }
        expect(student_with_override_data[:submissions].length).to eq 1
        expect(student_with_override_data.dig(:submissions, 0, "grade")).to eq "20"
        expect(student_with_override_data[:override_scores].length).to eq 1
        expect(student_with_override_data.dig(:override_scores, 0, :new_score)).to eq "60"

        student_without_override_data = output[:students].detect { |student| student[:id] == student_without_override.id }
        expect(student_without_override_data[:submissions].length).to eq 1
        expect(student_without_override_data.dig(:submissions, 0, "grade")).to eq "40"
        expect(student_without_override_data[:override_scores].length).to eq 1
        expect(student_without_override_data.dig(:override_scores, 0, :new_score)).to be_nil
      end
    end

    it "ignores changes to override scores if the course does not allow override grades" do
      @course.allow_final_grade_override = false
      @course.save!

      importer = importer_with_rows(
        "Student,ID,Section,Final Score,Override Score",
        "Cyrus,#{student_with_override.id},My Course,0,60"
      )

      output = importer.as_json

      expect(output[:students]).to be_empty
    end

    describe "override score json" do
      let(:grading_period_group) do
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.account)
        Factories::GradingPeriodHelper.new.create_presets_for_group(group, :past, :current)
        group
      end
      let(:grading_period_1) { grading_period_group.grading_periods.first }
      let(:grading_period_2) { grading_period_group.grading_periods.second }

      before do
        @course.enrollment_term.update!(grading_period_group:)
      end

      describe "top-level override score content" do
        it "sets 'includes_course_scores' to true if course-level override scores have changed" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score",
            "Cyrus,#{student_with_override.id},My Course,20,0,60",
            "Ophilia,#{student_without_override.id},My Course,40,0,"
          )

          output = importer.as_json
          expect(output[:override_scores][:includes_course_scores]).to be true
        end

        it "sets 'includes_course_scores' to false if no course-level override scores have changed" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score",
            "Cyrus,#{student_with_override.id},My Course,20,0,50.54",
            "Ophilia,#{student_without_override.id},My Course,40,0,"
          )

          output = importer.as_json
          expect(output[:override_scores][:includes_course_scores]).to be false
        end

        it "includes JSON for all grading periods with changes" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score (#{grading_period_1.title})",
            "Cyrus,#{student_with_override.id},My Course,20,0,99",
            "Ophilia,#{student_without_override.id},My Course,40,0,98"
          )

          output = importer.as_json
          expect(output[:override_scores][:grading_periods].pluck(:id)).to contain_exactly(grading_period_1.id)
        end

        it "is not included if importing override grades is not enabled" do
          @course.allow_final_grade_override = false
          @course.save!

          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score",
            "Cyrus,#{student_with_override.id},My Course,20,0,100",
            "Ophilia,#{student_without_override.id},My Course,40,0,100"
          )

          output = importer.as_json
          expect(output).not_to have_key(:override_scores)
        end
      end

      describe "per-student override score changes" do
        it "includes all course-level override scores if any course score has changed" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score",
            "Cyrus,#{student_with_override.id},My Course,20,0,50.54",
            "Ophilia,#{student_without_override.id},My Course,40,0,80.23"
          )

          output = importer.as_json

          changed_record = output[:students].detect { |student| student[:id] == student_without_override.id }
          unchanged_record = output[:students].detect { |student| student[:id] == student_with_override.id }

          aggregate_failures do
            expect(changed_record[:override_scores].length).to eq 1
            expect(changed_record[:override_scores].first[:current_score]).to be_nil
            expect(changed_record[:override_scores].first[:new_score]).to eq "80.23"
            expect(changed_record[:override_scores].first[:grading_period_id]).to be_nil

            expect(unchanged_record[:override_scores].length).to eq 1
            expect(unchanged_record[:override_scores].first[:current_score]).to eq "50.54"
            expect(unchanged_record[:override_scores].first[:new_score]).to eq "50.54"
            expect(unchanged_record[:override_scores].first[:grading_period_id]).to be_nil
          end
        end

        it "omits course-level override scores if there are no changes" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score",
            "Cyrus,#{student_with_override.id},My Course,20,0,50.54",
            "Ophilia,#{student_without_override.id},My Course,40,0,"
          )

          output = importer.as_json
          override_scores_by_student = output[:students].pluck(:override_scores)
          expect(override_scores_by_student).to all(be_empty)
        end

        it "includes all override scores for a grading period if any score has changed" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score (#{grading_period_2.title})",
            "Cyrus,#{student_with_override.id},My Course,20,0,",
            "Ophilia,#{student_without_override.id},My Course,40,0,90"
          )

          output = importer.as_json
          changed_record = output[:students].detect { |student| student[:id] == student_without_override.id }
          unchanged_record = output[:students].detect { |student| student[:id] == student_with_override.id }

          aggregate_failures do
            expect(changed_record[:override_scores].length).to eq 1
            expect(changed_record[:override_scores].first[:current_score]).to be_nil
            expect(changed_record[:override_scores].first[:new_score]).to eq "90"
            expect(changed_record[:override_scores].first[:grading_period_id]).to eq grading_period_2.id

            expect(unchanged_record[:override_scores].length).to eq 1
            expect(unchanged_record[:override_scores].first[:current_score]).to be_nil
            expect(unchanged_record[:override_scores].first[:new_score]).to be_nil
            expect(unchanged_record[:override_scores].first[:grading_period_id]).to eq grading_period_2.id
          end
        end

        it "omits override scores for a grading period if there are no changes" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score (#{grading_period_2.title})",
            "Cyrus,#{student_with_override.id},My Course,20,0,",
            "Ophilia,#{student_without_override.id},My Course,40,0,"
          )

          output = importer.as_json
          override_scores_by_student = output[:students].pluck(:override_scores)
          expect(override_scores_by_student).to all(be_empty)
        end

        it "keeps all scores if there is an unknown student in the CSV" do
          importer = importer_with_rows(
            "Student,ID,Section,Assignment 1,Final Score,Override Score (#{grading_period_2.title})",
            "Cyrus,#{student_with_override.id},My Course,20,0,",
            "Ophilia,#{student_without_override.id},My Course,40,0,",
            "Olberic,#{student_without_override.id},My Course,40,0,99"
          )

          output = importer.as_json
          override_scores_by_student = output[:students].pluck(:override_scores)
          aggregate_failures do
            expect(override_scores_by_student.length).to eq 3
            expect(override_scores_by_student.map(&:length)).to all(eq(1))
          end
        end

        it "works as expected if no override score column is included in the import" do
          expect do
            importer_with_rows(
              "Student,ID,Section,Assignment 1,Final Score",
              "Cyrus,#{student_with_override.id},My Course,20,0",
              "Ophilia,#{student_without_override.id},My Course,40,0"
            )
          end.not_to raise_error
        end
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
    attachment_with_file(File.join(File.dirname(__FILE__), %w[.. fixtures gradebooks basic_course.csv]))
  end

  def valid_gradebook_contents_with_last_and_first_names
    attachment_with_file(File.join(File.dirname(__FILE__), %w[.. fixtures gradebooks valid_gradebook_contents_with_last_and_first_names.csv]))
  end

  def valid_gradebook_contents_with_sis_login_id
    attachment_with_file(File.join(File.dirname(__FILE__), %w[.. fixtures gradebooks basic_course_with_sis_login_id.csv]))
  end

  def invalid_gradebook_contents
    attachment_with_file(File.join(File.dirname(__FILE__), %w[.. fixtures gradebooks wat.csv]))
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
