require_relative '../../../rails_helper'

RSpec.describe SettingsService::Commands::UpdateSettings do
  before do
    SettingsService.settings_table_prefix = 'somedomain.com'
  end
  subject do
    described_class.new(
      id: 1,
      setting: 'foo',
      value: 'bar',
      object: 'assignment'
    )
  end

  describe '#call' do
    it 'saves the setting to the repository' do
      allow(SettingsService::AssignmentRepository).to receive(:create_table)
      expect(SettingsService::AssignmentRepository).to receive(:put).with(
        :table_name=>"somedomain.com-assignment_settings",
        :id=>1,
        :setting=>"foo",
        :value=>"bar"
      )
      subject.call
    end
  end
end
