require_relative '../../../rails_helper'

RSpec.describe SettingsService::Commands::UpdateEnrollmentSetting do
  before do
    SettingsService.settings_table_prefix = 'somedomain.com'
  end
  subject do
    SettingsService::Commands::UpdateEnrollmentSetting.new(
      id: 1,
      setting: 'foo',
      value: 'bar'
    )
  end

  describe '#call' do
    it 'saves the setting to the repository' do
      allow(SettingsService::Repository).to receive(:create_table)
      expect(SettingsService::Repository).to receive(:put).with(
        :table_name=>"somedomain.com-enrollment_settings",
        :id=>1,
        :setting=>"foo",
        :value=>"bar"
      )
      subject.call
    end
  end
end
