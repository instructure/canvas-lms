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

describe RubricImport do
  before :once do
    account_model
    course_model(account: @account)
    user_factory
  end

  def create_import(attachment = nil, context = @account)
    RubricImport.create_with_attachment(context, attachment, @user)
  end

  it "should create a new rubric import" do
    import = create_import(stub_file_data("test.csv", "abc", "text"))
    expect(import.workflow_state).to eq("created")
    expect(import.progress).to eq(0)
    expect(import.error_count).to eq(0)
    expect(import.error_data).to eq([])
    expect(import.account_id).to eq(@account.id)
    expect(import.attachment_id).to eq(Attachment.last.id)
  end

  it "should create a new rubric import at the course level" do
    import = create_import(stub_file_data("test.csv", "abc", "text"), @course)
    expect(import.workflow_state).to eq("created")
    expect(import.progress).to eq(0)
    expect(import.error_count).to eq(0)
    expect(import.error_data).to eq([])
    expect(import.course_id).to eq(@course.id)
    expect(import.attachment_id).to eq(Attachment.last.id)
  end

  describe "run import" do
    let(:rubric_headers) do
      [
        "Rubric Name",
        "Criteria Name",
        "Criteria Description",
        "Criteria Enable Range",
        "Rating Name 1",
        "Rating Description 1",
        "Rating Points 1",
        "Rating Name 2",
        "Rating Description 2",
        "Rating Points 2",
        "Rating Name 3",
        "Rating Description 3",
        "Rating Points 3",
        "Rating Name 4",
        "Rating Description 4",
        "Rating Points 4",
        "Rating Name 5",
        "Rating Description 5",
        "Rating Points 5"
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
      RubricImport.create!(
        context: @account,
        root_account: @account,
        progress: 0,
        workflow_state: :created,
        user: @user,
        error_count: 0,
        error_data: [],
        attachment:
      )
    end

    def full_csv
      generate_csv([["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1"]])
    end

    def multiple_rubrics_csv
      generate_csv([
                     ["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating A1", "Description A1", "3", "Rating A2", "Description A2", "2"],
                     ["Rubric 1", "Criteria 2", "Criteria 2 Description", "false", "Rating B1", "Description B1", "5", "Rating B2", "Description B2", "4", "Rating B3", "Description B3", "3"],
                     ["Rubric 2", "Criteria 1", "Criteria 1 Description", "false", "Rating C1", "Description C1", "2"],
                     ["Rubric 2", "Criteria 2", "Criteria 2 Description", "false", "Rating D1", "Description D1", "4", "Rating D2", "Description D2", "3", "Rating D3", "Description D3", "2", "Rating D4", "Description D4", "1"]
                   ])
    end

    def varying_ratings_csv
      generate_csv([
                     ["Rubric 1", "Criterion 1", "Description 1", "false", "Rating 1", "Description 1", "5"],
                     ["Rubric 1", "Criterion 2", "Description 2", "false", "Rating 1", "Description 1", "4", "Rating 2", "Description 2", "3"],
                     ["Rubric 1", "Criterion 3", "Description 3", "false", "Rating 1", "Description 1", "5", "Rating 2", "Description 2", "4", "Rating 3", "Description 3", "3"],
                     ["Rubric 1", "Criterion 4", "Description 4", "false", "Rating 1", "Description 1", "5", "Rating 2", "Description 2", "4", "Rating 3", "Description 3", "3", "Rating 4", "Description 4", "2"]
                   ])
    end

    def multiple_criteria_ratings_csv
      generate_csv([
                     ["Rubric 1", "Criterion 1", "Description 1", "false", "Rating 1", "Description 1", "5", "Rating 2", "Description 2", "4", "Rating 3", "Description 3", "3"],
                     ["Rubric 1", "Criterion 2", "Description 2", "false", "Rating 1", "Description 1", "4", "Rating 2", "Description 2", "3"],
                     ["Rubric 1", "Criterion 3", "Description 3", "false", "Rating 1", "Description 1", "5"]
                   ])
    end

    def decimal_points_csv
      generate_csv([
                     ["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1,75", "Rating 2", "Rating 2 Description", "1", "Rating 3", "Rating 3 Description", "0.0"],
                     ["Rubric 2", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1.5", "Rating 2", "Rating 2 Description", "1.0", "Rating 3", "Rating 3 Description", "0"],
                   ])
    end

    def missing_rubric_name_csv
      generate_csv([["", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1"]])
    end

    def missing_criteria_name_csv
      generate_csv([["Rubric 1", "", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1"]])
    end

    def missing_ratings_csv
      generate_csv([["Rubric 1", "Criteria 1", "Criteria 1 Description", "false"]])
    end

    def valid_invalid_csv
      generate_csv([
                     ["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "2", "Rating 2", "Rating 2 Description", "1"],
                     ["", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "1"]
                   ])
    end

    def invalid_csv
      StringIO.new("invalid csv")
    end

    describe "succeeded" do
      it "should run the import with single rubric and criteria" do
        allow(InstStatsd::Statsd).to receive(:distributed_increment).and_call_original
        expect(InstStatsd::Statsd).to receive(:distributed_increment).with("account.rubrics.csv_imported").at_least(:once)
        import = create_import_manually(full_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(0)
        expect(import.error_data).to eq([])
        rubric = Rubric.find_by(rubric_imports_id: import.id)
        expect(rubric.title).to eq("Rubric 1")
        expect(rubric.context_id).to eq(@account.id)
        expect(rubric.data.length).to eq(1)
        expect(rubric.data[0][:description]).to eq("Criteria 1")
        expect(rubric.data[0][:long_description]).to eq("Criteria 1 Description")
        expect(rubric.data[0][:points]).to eq(1.0)
        expect(rubric.data[0][:criterion_use_range]).to be false
        expect(rubric.data[0][:ratings].length).to eq(1)
        expect(rubric.data[0][:ratings][0][:description]).to eq("Rating 1")
        expect(rubric.data[0][:ratings][0][:long_description]).to eq("Rating 1 Description")
        expect(rubric.data[0][:ratings][0][:points]).to eq(1.0)
      end

      it "should run the import with multiple rubrics, multiple criteria, and varying ratings" do
        import = create_import_manually(multiple_rubrics_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(0)
        expect(import.error_data).to eq([])

        rubrics = Rubric.where(rubric_imports_id: import.id)
        expect(rubrics.length).to eq(2)

        # Checking Rubric 1
        rubric1 = rubrics.find_by(title: "Rubric 1")
        expect(rubric1.context_id).to eq(@account.id)
        expect(rubric1.data.length).to eq(2)

        # Rubric 1, Criteria 1
        criterion1 = rubric1.data[0]
        expect(criterion1[:description]).to eq("Criteria 1")
        expect(criterion1[:long_description]).to eq("Criteria 1 Description")
        expect(criterion1[:points]).to eq(3.0)
        expect(criterion1[:ratings].length).to eq(2)
        expect(criterion1[:ratings][0][:description]).to eq("Rating A1")
        expect(criterion1[:ratings][0][:points]).to eq(3.0)
        expect(criterion1[:ratings][1][:description]).to eq("Rating A2")
        expect(criterion1[:ratings][1][:points]).to eq(2.0)

        # Rubric 1, Criteria 2
        criterion2 = rubric1.data[1]
        expect(criterion2[:description]).to eq("Criteria 2")
        expect(criterion2[:long_description]).to eq("Criteria 2 Description")
        expect(criterion2[:points]).to eq(5.0)
        expect(criterion2[:ratings].length).to eq(3)
        expect(criterion2[:ratings][0][:description]).to eq("Rating B1")
        expect(criterion2[:ratings][0][:points]).to eq(5.0)
        expect(criterion2[:ratings][1][:description]).to eq("Rating B2")
        expect(criterion2[:ratings][1][:points]).to eq(4.0)
        expect(criterion2[:ratings][2][:description]).to eq("Rating B3")
        expect(criterion2[:ratings][2][:points]).to eq(3.0)

        # Checking Rubric 2
        rubric2 = rubrics.find_by(title: "Rubric 2")
        expect(rubric2.context_id).to eq(@account.id)
        expect(rubric2.data.length).to eq(2)

        # Rubric 2, Criteria 1
        criterion1 = rubric2.data[0]
        expect(criterion1[:description]).to eq("Criteria 1")
        expect(criterion1[:long_description]).to eq("Criteria 1 Description")
        expect(criterion1[:points]).to eq(2.0)
        expect(criterion1[:ratings].length).to eq(1)
        expect(criterion1[:ratings][0][:description]).to eq("Rating C1")
        expect(criterion1[:ratings][0][:points]).to eq(2.0)

        # Rubric 2, Criteria 2
        criterion2 = rubric2.data[1]
        expect(criterion2[:description]).to eq("Criteria 2")
        expect(criterion2[:long_description]).to eq("Criteria 2 Description")
        expect(criterion2[:points]).to eq(4.0)
        expect(criterion2[:ratings].length).to eq(4)
        expect(criterion2[:ratings][0][:description]).to eq("Rating D1")
        expect(criterion2[:ratings][0][:points]).to eq(4.0)
        expect(criterion2[:ratings][1][:description]).to eq("Rating D2")
        expect(criterion2[:ratings][1][:points]).to eq(3.0)
        expect(criterion2[:ratings][2][:description]).to eq("Rating D3")
        expect(criterion2[:ratings][2][:points]).to eq(2.0)
        expect(criterion2[:ratings][3][:description]).to eq("Rating D4")
        expect(criterion2[:ratings][3][:points]).to eq(1.0)
      end

      it "should run the import with a single rubric having multiple criteria with varying numbers of ratings" do
        import = create_import_manually(varying_ratings_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(0)
        expect(import.error_data).to eq([])

        rubrics = Rubric.where(rubric_imports_id: import.id)
        expect(rubrics.length).to eq(1)

        rubric = rubrics.first
        expect(rubric.title).to eq("Rubric 1")
        expect(rubric.data.length).to eq(4)

        # Criterion 1
        criterion1 = rubric.data[0]
        expect(criterion1[:description]).to eq("Criterion 1")
        expect(criterion1[:ratings].length).to eq(1)

        # Criterion 2
        criterion2 = rubric.data[1]
        expect(criterion2[:description]).to eq("Criterion 2")
        expect(criterion2[:ratings].length).to eq(2)

        # Criterion 3
        criterion3 = rubric.data[2]
        expect(criterion3[:description]).to eq("Criterion 3")
        expect(criterion3[:ratings].length).to eq(3)

        # Criterion 4
        criterion4 = rubric.data[3]
        expect(criterion4[:description]).to eq("Criterion 4")
        expect(criterion4[:ratings].length).to eq(4)
      end

      it "should run the import with multiple criteria having different numbers of ratings" do
        import = create_import_manually(multiple_criteria_ratings_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(0)
        expect(import.error_data).to eq([])

        rubrics = Rubric.where(rubric_imports_id: import.id)
        expect(rubrics.length).to eq(1)

        rubric = rubrics.first
        expect(rubric.title).to eq("Rubric 1")
        expect(rubric.data.length).to eq(3)

        # Criterion 1
        criterion1 = rubric.data[0]
        expect(criterion1[:description]).to eq("Criterion 1")
        expect(criterion1[:ratings].length).to eq(3)

        # Criterion 2
        criterion2 = rubric.data[1]
        expect(criterion2[:description]).to eq("Criterion 2")
        expect(criterion2[:ratings].length).to eq(2)

        # Criterion 3
        criterion3 = rubric.data[2]
        expect(criterion3[:description]).to eq("Criterion 3")
        expect(criterion3[:ratings].length).to eq(1)
      end
    end

    it "should run the import with decimal points in ratings" do
      import = create_import_manually(decimal_points_csv)
      import.run

      expect(import.workflow_state).to eq("succeeded")
      expect(import.progress).to eq(100)
      expect(import.error_count).to eq(0)
      expect(import.error_data).to eq([])

      rubrics = Rubric.where(rubric_imports_id: import.id)
      expect(rubrics.length).to eq(2)

      rubric1 = rubrics.find_by(title: "Rubric 1")
      expect(rubric1.data.length).to eq(1)
      criterion1 = rubric1.data[0]
      expect(criterion1[:ratings].length).to eq(3)
      expect(criterion1[:ratings][0][:points]).to eq(1.75)
      expect(criterion1[:ratings][1][:points]).to eq(1.0)
      expect(criterion1[:ratings][2][:points]).to eq(0.0)

      rubric2 = rubrics.find_by(title: "Rubric 2")
      expect(rubric2.data.length).to eq(1)
      criterion1 = rubric2.data[0]
      expect(criterion1[:ratings].length).to eq(3)
      expect(criterion1[:ratings][0][:points]).to eq(1.5)
      expect(criterion1[:ratings][1][:points]).to eq(1.0)
      expect(criterion1[:ratings][2][:points]).to eq(0.0)
    end

    describe "succeeded_with_errors" do
      it "should succeed with errors if rubric name is missing" do
        import = create_import_manually(missing_rubric_name_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded_with_errors")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(1)
        expect(import.error_data).to eq([{ "message" => "Missing 'Rubric Name' in some rows." }])
        expect(Rubric.all.length).to eq(0)
      end

      it "should succeed with errors if criteria name is missing" do
        import = create_import_manually(missing_criteria_name_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded_with_errors")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(1)
        expect(import.error_data).to eq([{ "message" => "Missing 'Criteria Name' for Rubric 1" }])
        expect(Rubric.all.length).to eq(0)
      end

      it "should succeed with errors if ratings are missing" do
        import = create_import_manually(missing_ratings_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded_with_errors")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(1)
        expect(import.error_data).to eq([{ "message" => "Missing ratings for Criteria 1" }])
        expect(Rubric.all.length).to eq(0)
      end

      it "should succeed with errors if some rubrics are invalid and create the valid ones" do
        import = create_import_manually(valid_invalid_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded_with_errors")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(1)
        expect(import.error_data).to eq([{ "message" => "Missing 'Rubric Name' in some rows." }])
        expect(Rubric.all.length).to eq(1)
        expect(Rubric.first.title).to eq("Rubric 1")
      end
    end

    describe "failed" do
      it "should fail the import if the file does not have valid CSV data" do
        import = create_import_manually(invalid_csv)
        import.run

        expect(import.workflow_state).to eq("failed")
        expect(import.progress).to eq(0)
        expect(import.error_count).to eq(1)
        expect(import.error_data).to eq([{ "message" => I18n.t("The file is empty or does not contain valid rubric data.") }])
      end
    end
  end
end
