require_relative '../../rails_helper'

RSpec.describe SettingsService::StudentAssignmentRepository do
  describe "#call" do
    let(:assignment) { double('Assignment', migration_id: 12312, id: 1) }
    let(:dynamodb) { double('Dynamodb', query: result) }
    let(:result) { double('result', items: [{'setting' => 'animal', 'value' => 'dog'}]) }

    before do
      allow(Assignment).to receive(:find).and_return(assignment)
      allow(SettingsService::StudentAssignmentRepository.instance).to receive(:dynamodb).and_return(dynamodb)
    end

    describe '#get' do
      it 'returns the result from dynamodb' do
        expect(
          described_class.get(table_name: 'cat', id: { assignment_id: 1 })
        ).to eq({'animal' => 'dog'})
      end
    end
  end
end