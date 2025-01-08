# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe RubricAssessmentImport do
  before :once do
    account_model
    course_model(account: @account)
    assignment_model(course: @course)

    criterion1 = {
      description: "Criterion 1",
      points: 10,
      id: "crit1",
      ignore_for_scoring: true,
      ratings: [
        { description: "Exceed", points: 4, id: "rat1", criterion_id: "crit1" },
        { description: "Meets", points: 3, id: "rat2", criterion_id: "crit1" }
      ]
    }

    criterion2 = {
      description: "Criterion 2",
      points: 10,
      id: "crit2",
      ignore_for_scoring: true,
      ratings: [
        { description: "Exceed", points: 4, id: "rat3", criterion_id: "crit2" },
        { description: "Meets", points: 3, id: "rat4", criterion_id: "crit2" }
      ]
    }

    rubric_model({ context: @course, title: "Test Rubric", data: [criterion1, criterion2] })
    rubric_association_model(user: @user, context: @course, association_object: @assignment, purpose: "grading", rubric: @rubric)
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user
  end

  def create_import(attachment = nil, assignment = @assignment)
    RubricAssessmentImport.create_with_attachment(assignment, attachment, @user)
  end

  it "should create a new rubric assessment import" do
    import = create_import(stub_file_data("test.csv", "abc", "text"))
    expect(import.workflow_state).to eq("created")
    expect(import.progress).to eq(0)
    expect(import.error_count).to eq(0)
    expect(import.error_data).to eq([])
    expect(import.assignment_id).to eq(@assignment.id)
    expect(import.course_id).to eq(@course.id)
    expect(import.attachment_id).to eq(Attachment.last.id)
  end

  describe "run import" do
    let(:rubric_headers) do
      [
        "Student Id",
        "Student Name",
        "Criterion 1 - Rating",
        "Criterion 1 - Points",
        "Criterion 1 - Comments",
        "Criterion 2 - Rating",
        "Criterion 2 - Points",
        "Criterion 2 - Comments",
      ]
    end

    def generate_csv(rubric_data)
      uploaded_csv = CSV.generate do |csv|
        csv << rubric_headers
        rubric_data.each do |rubric|
          csv << rubric
        end
      end
      StringIO.new(uploaded_csv)
    end

    def create_import_manually(uploaded_data)
      attachment = Attachment.create!(context: @account, filename: "test.csv", uploaded_data:)
      RubricAssessmentImport.create!(
        root_account: @assignment.root_account,
        progress: 0,
        workflow_state: :created,
        user: @teacher,
        error_count: 0,
        error_data: [],
        attachment:,
        assignment: @assignment,
        course: @course
      )
    end

    def full_csv
      generate_csv([
                     [@student1.id, "Test Student", "Exceed", "4.0", "", "Meets", "3.0", "Good job"],
                     [@student2.id, "Test Student", "Exceed", "4.0", "test comment", "Meets", "3.0", "Great!"],
                   ])
    end

    def csv_with_only_ratings
      generate_csv([
                     [@student1.id, "Test Student", "Exceed", "", "", "Meets", "", "Good job"],
                     [@student2.id, "Test Student", "Exceed", "", "test comment", "Meets", "", "Great!"],
                   ])
    end

    def csv_with_mixmatch_points_and_ratings
      generate_csv([
                     [@student1.id, "Test Student", "Meets", "4.0", "", "Exceeds", "3.0", "Good job"],
                     [@student2.id, "Test Student", "Bad Job", "4.0", "test comment", "Poor", "3.0", "Great!"],
                   ])
    end

    it "should fail if the file is empty" do
      import = create_import_manually(StringIO.new("invalid csv"))
      import.run

      expect(import.workflow_state).to eq("failed")
      expect(import.error_data).to eq([{ "message" => "The file is empty or does not contain valid assessment data." }])
    end

    it "should assess students" do
      import = create_import_manually(full_csv)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.error_count).to eq(0)
      expect(import.progress).to eq(100)

      student1_assessment = RubricAssessment.find_by(user_id: @student1.id)
      student1_first_assessment = student1_assessment.data[0]
      expect(student1_first_assessment[:points]).to eq(4.0)
      expect(student1_first_assessment[:description]).to eq("Exceed")
      expect(student1_first_assessment[:comments]).to eq("")
      student1_second_assessment = student1_assessment.data[1]
      expect(student1_second_assessment[:points]).to eq(3.0)
      expect(student1_second_assessment[:description]).to eq("Meets")
      expect(student1_second_assessment[:comments]).to eq("Good job")

      student2_assessment = RubricAssessment.find_by(user_id: @student2.id)
      student2_first_assessment = student2_assessment.data[0]
      expect(student2_first_assessment[:points]).to eq(4.0)
      expect(student2_first_assessment[:description]).to eq("Exceed")
      expect(student2_first_assessment[:comments]).to eq("test comment")
      student2_second_assessment = student2_assessment.data[1]
      expect(student2_second_assessment[:points]).to eq(3.0)
      expect(student2_second_assessment[:description]).to eq("Meets")
      expect(student2_second_assessment[:comments]).to eq("Great!")
    end

    it "should assess rubric criteria without ratings if free_form_criterion_comments is enabled" do
      @rubric.update!(free_form_criterion_comments: true)
      import = create_import_manually(full_csv)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.error_count).to eq(0)
      expect(import.progress).to eq(100)

      student1_assessment = RubricAssessment.find_by(user_id: @student1.id)
      student1_first_assessment = student1_assessment.data[0]
      expect(student1_first_assessment[:points]).to eq(4.0)
      expect(student1_first_assessment[:comments]).to eq("")
      student1_second_assessment = student1_assessment.data[1]
      expect(student1_second_assessment[:points]).to eq(3.0)
      expect(student1_second_assessment[:comments]).to eq("Good job")

      student2_assessment = RubricAssessment.find_by(user_id: @student2.id)
      student2_first_assessment = student2_assessment.data[0]
      expect(student2_first_assessment[:points]).to eq(4.0)
      expect(student2_first_assessment[:comments]).to eq("test comment")
      student2_second_assessment = student2_assessment.data[1]
      expect(student2_second_assessment[:points]).to eq(3.0)
      expect(student2_second_assessment[:comments]).to eq("Great!")
    end

    it "should assess rubrics without points when hide_points is enabled" do
      @rubric_association.update!(hide_points: true)
      import = create_import_manually(full_csv)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.error_count).to eq(0)
      expect(import.progress).to eq(100)

      student1_assessment = RubricAssessment.find_by(user_id: @student1.id)
      student1_first_assessment = student1_assessment.data[0]
      expect(student1_first_assessment[:points]).to be_nil
      expect(student1_first_assessment[:description]).to eq("Exceed")
      expect(student1_first_assessment[:comments]).to eq("")
      student1_second_assessment = student1_assessment.data[1]
      expect(student1_second_assessment[:points]).to be_nil
      expect(student1_second_assessment[:description]).to eq("Meets")
      expect(student1_second_assessment[:comments]).to eq("Good job")

      student2_assessment = RubricAssessment.find_by(user_id: @student2.id)
      student2_first_assessment = student2_assessment.data[0]
      expect(student2_first_assessment[:points]).to be_nil
      expect(student2_first_assessment[:description]).to eq("Exceed")
      expect(student2_first_assessment[:comments]).to eq("test comment")
      student2_second_assessment = student2_assessment.data[1]
      expect(student2_second_assessment[:points]).to be_nil
      expect(student2_second_assessment[:description]).to eq("Meets")
      expect(student2_second_assessment[:comments]).to eq("Great!")
    end

    it "should assess rubrics setting points to the matching rating if hide_points is not enabled" do
      @rubric_association.update!(hide_points: false)
      import = create_import_manually(csv_with_only_ratings)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.error_count).to eq(0)
      expect(import.progress).to eq(100)

      student1_assessment = RubricAssessment.find_by(user_id: @student1.id)
      student1_first_assessment = student1_assessment.data[0]
      expect(student1_first_assessment[:points]).to eq(4.0)
      expect(student1_first_assessment[:description]).to eq("Exceed")
      expect(student1_first_assessment[:comments]).to eq("")
      student1_second_assessment = student1_assessment.data[1]
      expect(student1_second_assessment[:points]).to eq(3.0)
      expect(student1_second_assessment[:description]).to eq("Meets")
      expect(student1_second_assessment[:comments]).to eq("Good job")

      student2_assessment = RubricAssessment.find_by(user_id: @student2.id)
      student2_first_assessment = student2_assessment.data[0]
      expect(student2_first_assessment[:points]).to eq(4.0)
      expect(student2_first_assessment[:description]).to eq("Exceed")
      expect(student2_first_assessment[:comments]).to eq("test comment")
      student2_second_assessment = student2_assessment.data[1]
      expect(student2_second_assessment[:points]).to eq(3.0)
      expect(student2_second_assessment[:description]).to eq("Meets")
      expect(student2_second_assessment[:comments]).to eq("Great!")
    end

    it "should assess rubrics with priority of points over ratings if they differ" do
      @rubric_association.update!(hide_points: false)
      import = create_import_manually(csv_with_mixmatch_points_and_ratings)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.error_count).to eq(0)
      expect(import.progress).to eq(100)

      student1_assessment = RubricAssessment.find_by(user_id: @student1.id)
      student1_first_assessment = student1_assessment.data[0]
      expect(student1_first_assessment[:points]).to eq(4.0)
      expect(student1_first_assessment[:description]).to eq("Meets")
      expect(student1_first_assessment[:comments]).to eq("")
      student1_second_assessment = student1_assessment.data[1]
      expect(student1_second_assessment[:points]).to eq(3.0)
      expect(student1_second_assessment[:description]).to eq("Exceeds")
      expect(student1_second_assessment[:comments]).to eq("Good job")

      student2_assessment = RubricAssessment.find_by(user_id: @student2.id)
      student2_first_assessment = student2_assessment.data[0]
      expect(student2_first_assessment[:points]).to eq(4.0)
      expect(student2_first_assessment[:description]).to eq("Bad Job")
      expect(student2_first_assessment[:comments]).to eq("test comment")
      student2_second_assessment = student2_assessment.data[1]
      expect(student2_second_assessment[:points]).to eq(3.0)
      expect(student2_second_assessment[:description]).to eq("Poor")
      expect(student2_second_assessment[:comments]).to eq("Great!")
    end
  end
end
