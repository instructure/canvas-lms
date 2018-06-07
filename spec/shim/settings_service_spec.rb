require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "The SettingsService" do
  describe 'toggling sequence control' do
    it 'updates enrollment settings' do
      allow(SettingsService::Repository).to receive(:create_table)
      expect(SettingsService::Repository).to receive(:put).with(:table_name=>"test_suite-enrollment_settings", :id=>1, :setting=>"sequence_control", :value=>"true")
      SettingsService::Enrollment.canvas_domain = 'test_suite'
      SettingsService.update_enrollment_setting(
        id:      1,
        setting: 'sequence_control',
        value:   'true'
      )
    end
  end
end
