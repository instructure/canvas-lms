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
    let(:rubric_headers) { ["Rubric Name", "Criteria Name", "Criteria Description", "Criteria Enable Range", "Rating Name", "Rating Description", "Rating Points", "Rating Name", "Rating Description", "Rating Points", "Rating Name", "Rating Description", "Rating Points"] }

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
                     ["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "2", "Rating 2", "Rating 2 Description", "1"],
                     ["Rubric 1", "Criteria 2", "Criteria 2 Description", "false", "Rating 1", "Rating 1 Description", "1"],
                     ["Rubric 2", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "3", "Rating 2", "Rating 2 Description", "2", "Rating 3", "Rating 3 Description", "1"]
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
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        expect(InstStatsd::Statsd).to receive(:increment).with("account.rubrics.csv_imported").at_least(:once)
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

      it "should run the import with multiple rubrics and criteria" do
        import = create_import_manually(multiple_rubrics_csv)
        import.run

        expect(import.workflow_state).to eq("succeeded")
        expect(import.progress).to eq(100)
        expect(import.error_count).to eq(0)
        expect(import.error_data).to eq([])

        rubrics = Rubric.where(rubric_imports_id: import.id)
        expect(rubrics.length).to eq(2)

        # checking rubric 1
        rubric1 = rubrics.find_by(title: "Rubric 1")
        expect(rubric1.context_id).to eq(@account.id)
        expect(rubric1.data.length).to eq(2)

        # checking rubric 1 criteria 1
        expect(rubric1.data[0][:description]).to eq("Criteria 1")
        expect(rubric1.data[0][:long_description]).to eq("Criteria 1 Description")
        expect(rubric1.data[0][:points]).to eq(2.0)
        expect(rubric1.data[0][:criterion_use_range]).to be false
        expect(rubric1.data[0][:ratings].length).to eq(2)
        expect(rubric1.data[0][:ratings][0][:description]).to eq("Rating 1")
        expect(rubric1.data[0][:ratings][0][:long_description]).to eq("Rating 1 Description")
        expect(rubric1.data[0][:ratings][0][:points]).to eq(2.0)
        expect(rubric1.data[0][:ratings][1][:description]).to eq("Rating 2")
        expect(rubric1.data[0][:ratings][1][:long_description]).to eq("Rating 2 Description")
        expect(rubric1.data[0][:ratings][1][:points]).to eq(1.0)

        # checking rubric 1 criteria 2
        expect(rubric1.data[1][:description]).to eq("Criteria 2")
        expect(rubric1.data[1][:long_description]).to eq("Criteria 2 Description")
        expect(rubric1.data[1][:points]).to eq(1.0)
        expect(rubric1.data[1][:criterion_use_range]).to be false
        expect(rubric1.data[1][:ratings].length).to eq(1)
        expect(rubric1.data[1][:ratings][0][:description]).to eq("Rating 1")
        expect(rubric1.data[1][:ratings][0][:long_description]).to eq("Rating 1 Description")

        # # checking rubric 2
        rubric2 = rubrics.find_by(title: "Rubric 2")
        expect(rubric2.context_id).to eq(@account.id)
        expect(rubric2.data.length).to eq(1)

        # # checking rubric 2 criteria 1
        expect(rubric2.data[0][:description]).to eq("Criteria 1")
        expect(rubric2.data[0][:long_description]).to eq("Criteria 1 Description")
        expect(rubric2.data[0][:points]).to eq(3.0)
        expect(rubric2.data[0][:ratings][0][:description]).to eq("Rating 1")
        expect(rubric2.data[0][:ratings][0][:long_description]).to eq("Rating 1 Description")
        expect(rubric2.data[0][:ratings][0][:points]).to eq(3.0)
        expect(rubric2.data[0][:ratings][1][:description]).to eq("Rating 2")
        expect(rubric2.data[0][:ratings][1][:long_description]).to eq("Rating 2 Description")
        expect(rubric2.data[0][:ratings][1][:points]).to eq(2.0)
        expect(rubric2.data[0][:ratings][2][:description]).to eq("Rating 3")
        expect(rubric2.data[0][:ratings][2][:long_description]).to eq("Rating 3 Description")
        expect(rubric2.data[0][:ratings][2][:points]).to eq(1.0)
      end
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
