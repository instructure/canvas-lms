require_relative '../../rails_helper'

RSpec.describe SettingsService::Assignment do
  subject {
    described_class.new
  }

  let(:table_name) { 'integration.example.com-assignment_settings' }

  before do
    SettingsService.settings_table_prefix = 'integration.example.com'
  end

  describe '#create_table' do
    it 'creates a table' do
      expect(SettingsService::AssignmentRepository).to receive(:create_table)
        .with(name: table_name)

      described_class.create_table
    end
  end

  describe '#get' do
    it 'fetches the settings for enrollment' do
      expect(SettingsService::AssignmentRepository).to receive(:get).with(
        id: 1,
        table_name: table_name
      )

      described_class.get(id: 1)
    end
  end

  describe '#put' do
    it 'calls put on the repository' do
      expect(SettingsService::AssignmentRepository).to receive(:put).with(
        id:         1,
        setting:    'max_attempts',
        value:      13,
        table_name: table_name
      )
      described_class.put(id: 1, setting: 'max_attempts', value: 13)
    end
  end
end
