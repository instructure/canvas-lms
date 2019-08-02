require_relative '../../rails_helper'

RSpec.describe SettingsService::User do
  subject {
    described_class.new
  }

  let(:table_name) {'integration.example.com-user_settings'}

  context '' do
    before do
      allow(SettingsService::Repository).to receive(:create_table)
    end

    xit 'blows up if settings_table_prefix not present' do
      expect do
        subject.create_table
      end.to raise_error("missing settings table prefix!")
    end
  end

  context 'settings table prefix present' do
    before do
      SettingsService.settings_table_prefix = 'integration.example.com'
    end

    describe '#create_table' do
      it 'creates a table' do
        expect(SettingsService::Repository).to receive(:create_table)
          .with(name: table_name)
        described_class.create_table
      end
    end

    describe '#get' do
      it 'fetches the settings for user' do
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
          setting:    'accommodation',
          value:      'true',
          table_name: table_name
        )
        described_class.put(id: 1, setting: 'accommodation', value: 'true')
      end
    end
  end

end
