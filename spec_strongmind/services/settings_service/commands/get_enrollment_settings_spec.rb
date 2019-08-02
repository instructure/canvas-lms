require_relative '../../../rails_helper'

RSpec.describe SettingsService::Commands::GetEnrollmentSettings do
  before do
    SettingsService.settings_table_prefix = 'somedomain.com'
  end

  subject do
    SettingsService::Commands::GetEnrollmentSettings.new(
      id: 1
    )
  end

  describe '#call' do
    it 'gets the settings from the repository' do
      allow(SettingsService::Repository).to receive(:create_table)
      expect(SettingsService::Repository).to receive(:get).with(
        :table_name=>"somedomain.com-enrollment_settings",
        :id=>1
      )
      subject.call
    end
  end
end
