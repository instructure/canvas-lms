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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OutcomeImport, type: :model do
  before :once do
    account_model
  end

  describe 'associations' do
    it { is_expected.to belong_to(:context) }
    it { is_expected.to belong_to(:attachment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:outcome_import_errors) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :context_type }
    it { is_expected.to validate_presence_of :context_id }
  end

  def create_import
    OutcomeImport.create_with_attachment(@account, 'instructure_csv', stub_file_data('test.csv', 'abc', 'text'), user_factory)
  end

  it "should keep the import in initializing state during create_with_attachment" do
    import = create_import do |imp|
      expect(imp.attachment).not_to be_new_record
      expect(imp.workflow_state).to eq 'initializing'
    end

    expect(import.workflow_state).to eq 'created'
    expect(import).not_to be_new_record
    expect(import).not_to be_changed
  end

  it "should save as latest outcome import" do
    import = create_import
    expect(@account.latest_outcome_import).to be_nil
    import.job_started
    expect(@account.latest_outcome_import).to eq import
  end

  it 'should generate expected json' do
    import = create_import
    import.outcome_import_errors.create(message: 'Fail!', row: 100)
    json = import.as_json
    expect(json["id"]).to eq import.id
    expect(json["created_at"]).to eq import.created_at
    expect(json["ended_at"]).to eq import.ended_at
    expect(json["updated_at"]).to eq import.updated_at
    expect(json["progress"]).to eq import.progress
    expect(json["workflow_state"]).to eq import.workflow_state
    expect(json["data"]).to eq import.data
    expect(json["processing_errors"]).to eq [[100, 'Fail!']]
  end

  it 'should limit to 25 processing errors' do
    import = create_import
    100.times do
      import.outcome_import_errors.create(message: 'Fail!')
    end
    json = import.as_json
    expect(json["processing_errors"].length).to eq 25
  end
end
