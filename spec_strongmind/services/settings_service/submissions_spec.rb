require_relative '../../rails_helper'

RSpec.describe SettingsService::Submission do
  subject {
    described_class.new
  }

  let(:table_name) { 'integration.example.com-submission_settings' }

  before do
    SettingsService.canvas_domain = 'integration.example.com'
  end

  describe '#create_table' do
    it 'creates a table' do
      expect(SettingsService::Repository).to receive(:create_table)
        .with(name: table_name)

      described_class.create_table
    end
  end

  describe '#get' do
    it 'fetches the settings for enrollment' do
      expect(SettingsService::Repository).to receive(:get).with(
        id: 1,
        table_name: table_name
      )

      described_class.get(id: 1)
    end
  end

  describe '#put' do
    it 'calls put on the repository' do
      expect(SettingsService::Repository).to receive(:put).with(
        id:         1,
        setting:    'auto_zero_previous_grade',
        value:      30,
        table_name: table_name
      )
      described_class.put(id: 1, setting: 'auto_zero_previous_grade', value: 30)
    end
  end
end
