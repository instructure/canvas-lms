# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe OutcomeImport do
  before :once do
    account_model
  end

  describe "associations" do
    it { is_expected.to belong_to(:context).required }
    it { is_expected.to belong_to(:attachment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:outcome_import_errors) }
  end

  def create_import
    OutcomeImport.create_with_attachment(@account, "instructure_csv", stub_file_data("test.csv", "abc", "text"), user_factory)
  end

  it "keeps the import in initializing state during create_with_attachment" do
    import = create_import do |imp|
      expect(imp.attachment).not_to be_new_record
      expect(imp.workflow_state).to eq "initializing"
    end

    expect(import.workflow_state).to eq "created"
    expect(import).not_to be_new_record
    expect(import).not_to be_changed
  end

  it "uses instfs for attachment during create_with_attachment if instfs is enabled" do
    uuid = "1234-abcd"
    allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)
    import = create_import
    expect(import.attachment.instfs_uuid).to eq uuid
  end

  it "saves as latest outcome import" do
    import = create_import
    expect(@account.latest_outcome_import).to be_nil
    import.job_started
    expect(@account.latest_outcome_import).to eq import
  end

  it "generates expected json" do
    import = create_import
    import.outcome_import_errors.create(message: "Fail!", row: 100)
    json = import.as_json
    expect(json["id"]).to eq import.id
    expect(json["created_at"]).to eq import.created_at
    expect(json["ended_at"]).to eq import.ended_at
    expect(json["updated_at"]).to eq import.updated_at
    expect(json["progress"]).to eq import.progress
    expect(json["workflow_state"]).to eq import.workflow_state
    expect(json["data"]).to eq import.data
    expect(json["processing_errors"]).to eq [[100, "Fail!"]]
  end

  it "limits to 25 processing errors" do
    import = create_import
    100.times do
      import.outcome_import_errors.create(message: "Fail!")
    end
    json = import.as_json
    expect(json["processing_errors"].length).to eq 25
  end

  describe ".run handles outcome import" do
    def mock_importer(updates)
      importer = instance_double(Outcomes::CSVImporter)
      expect(importer).to receive(:run) do |&block|
        updates.each do |up|
          block.call(up)
        end
      end
      expect(Outcomes::CSVImporter).to receive(:new).and_return(importer)
    end

    def mock_importer_error(msg)
      importer = instance_double(Outcomes::CSVImporter)
      expect(importer).to receive(:run).and_raise(Outcomes::Import::DataFormatError, msg)
      expect(Outcomes::CSVImporter).to receive(:new).and_return(importer)
    end

    def fake_file
      instance_double(File).tap do |file_double|
        expect(file_double).to receive(:close)
      end
    end

    def fake_attachment(file)
      instance_double(Attachment).tap do |attachment_double|
        allow(attachment_double).to receive(:open).and_return(file)
      end
    end

    def fake_import(attachment)
      OutcomeImport.create!(context: @account).tap do |import|
        import.update!(workflow_state: "created")
        allow(import).to receive(:attachment).and_return(attachment)
      end
    end

    it "sets proper workflow_state on successful completion" do
      mock_importer([
                      { progress: 0, errors: [] },
                      { progress: 100, errors: [] }
                    ])

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      expect(import).to receive(:job_started!).and_call_original
      import.run

      expect(import.outcome_import_errors.all.to_a).to eq([])
      expect(import.progress).to eq(100)
      expect(import.workflow_state).to eq("succeeded")
    end

    it "emails user on successful completion" do
      mock_importer([
                      { progress: 0, errors: [] },
                      { progress: 100, errors: [] }
                    ])

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      import.user = user_factory
      import.save!
      message = Message.new
      expect(message).to receive(:communication_channel=).with(import.user.email_channel).and_call_original
      expect(message).to receive(:user=).with(import.user).and_call_original
      expect(Message).to receive(:new).with({
                                              to: import.user.email,
                                              from: "notifications@instructure.com",
                                              subject: "Outcomes Import Completed",
                                              body: "Hello #{import.user.name},

          Your outcomes were successfully imported. You can now manage them at http://localhost/accounts/#{@account.id}/outcomes

          Thank you,
          Instructure".gsub(/^ +/, ""),
                                              delay_for: 0,
                                              context: nil,
                                              path_type: "email",
                                              from_name: "Instructure Canvas"
                                            }).and_return(message)
      expect(message).to receive(:deliver)
      import.run
    end

    it "emails user on successful completion but with warnings" do
      mock_importer([
                      { progress: 0, errors: [] },
                      { progress: 50, errors: [[2, 'The "title" field is required']] },
                      { progress: 100, errors: [] }
                    ])

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      import.user = user_factory
      import.save!
      message = Message.new
      expect(message).to receive(:communication_channel=).with(import.user.email_channel).and_call_original
      expect(message).to receive(:user=).with(import.user).and_call_original
      expect(Message).to receive(:new).with({
                                              to: import.user.email,
                                              from: "notifications@instructure.com",
                                              subject: "Outcomes Import Completed",
                                              body: "Hello #{import.user.name},

          Your outcomes were successfully imported, but with the following issues (up to the first 100 warnings):

          Row 2: The \"title\" field is required

          You can now manage them at http://localhost/accounts/#{@account.id}/outcomes

          Thank you,
          Instructure".gsub(/^ +/, ""),
                                              delay_for: 0,
                                              context: nil,
                                              path_type: "email",
                                              from_name: "Instructure Canvas"
                                            }).and_return(message)
      expect(message).to receive(:deliver)
      import.run
    end

    it "emails user on failed completion" do
      mock_importer_error("Very Bad Error")

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      import.user = user_factory
      import.save!
      message = Message.new
      expect(message).to receive(:communication_channel=).with(import.user.email_channel).and_call_original
      expect(message).to receive(:user=).with(import.user).and_call_original
      expect(Message).to receive(:new).with({
                                              to: import.user.email,
                                              from: "notifications@instructure.com",
                                              subject: "Outcomes Import Failed",
                                              body: "Hello #{import.user.name},

          Your outcomes import failed due to an error with your import. Please examine your file and attempt the upload again at http://localhost/accounts/#{@account.id}/outcomes

          The following error occurred:
          Row 1: Very Bad Error

          To view the proper import format, please review the Canvas API Docs at http://localhost/doc/api/file.outcomes_csv.html

          Thank you,
          Instructure".gsub(/^ +/, ""),
                                              delay_for: 0,
                                              context: nil,
                                              path_type: "email",
                                              from_name: "Instructure Canvas"
                                            }).and_return(message)
      expect(message).to receive(:deliver)
      import.run
    end

    it "sets outcome_import_errors" do
      mock_importer_error("Very Bad Error")

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      import.run

      errors = import.outcome_import_errors.all.to_a
      expect(errors.pluck(:row, :message)).to eq([
                                                   [1, "Very Bad Error"]
                                                 ])
      expect(import.progress).to be_nil
      expect(import.workflow_state).to eq("failed")
    end

    it "has a catch-all for unexpected errors" do
      expect(Outcomes::CSVImporter).to receive(:new).and_return(nil)

      attachment = fake_attachment(fake_file)
      import = fake_import(attachment)
      expect(import).to receive(:job_started!).and_call_original
      import.run

      errors = import.outcome_import_errors.all.to_a
      expect(errors.length).to eq 1
      expect(errors[0]).to have_attributes(row: 1, message: /An unexpected error has .*/, failure: true)

      error_report_id = errors[0].message.match(/error report (\d+)/)[1]
      expect(ErrorReport.find(error_report_id).message).to match(/undefined method/)
    end
  end
end
