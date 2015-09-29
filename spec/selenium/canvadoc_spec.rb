require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe 'Canvadoc' do
  include_context "in-process server selenium tests"
  before :all do
    PluginSetting.create! :name => 'canvadocs',
      :settings => {"api_key" => "blahblahblahblahblah",
                    "base_url" => "http://example.com",
                    "annotations_supported" => "1"}
  end

  def turn_on_plugin_settings
    get '/plugins/canvadocs'
    if element_exists('#accounts_select')
        f("#accounts_select option:nth-child(2)").click
        f("#plugin_setting_disabled").click
        wait_for_ajaximations
    end
  end

  context 'as an admin' do
    before :each do
      site_admin_logged_in
      Canvadocs::API.any_instance.stubs(:upload).returns "id" => 1234
    end

    it 'should have the annotations checkbox in plugin settings', priority: "1", test_id: 345729 do
      turn_on_plugin_settings
      expect(fj('#settings_annotations_supported:visible')).to be_displayed
    end

    it 'should allow annotations settings to be saved', priority: "1", test_id: 345730 do
      turn_on_plugin_settings
      fj('#settings_annotations_supported').click
      f('.save_button').click
      assert_flash_notice_message('Plugin settings successfully updated.')
    end
  end
end