require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')


describe 'Canvadoc' do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  before :once do
    PluginSetting.create! :name => 'canvadocs',
      :settings => {"api_key" => "blahblahblahblahblah",
                    "base_url" => "http://example.com",
                    "annotations_supported" => "1"}
  end

  def turn_on_plugin_settings
    get '/plugins/canvadocs'
    # whee different UI for plugins
    if element_exists?('#accounts_select')
      f("#accounts_select option:nth-child(2)").click
      if !f(".save_button").enabled?
        f(".copy_settings_button").click
      end
      if f("#plugin_setting_disabled")[:checked]
        f("#plugin_setting_disabled").click
      end
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

    it "embed canvadocs in page", priority: "1", test_id: 126836 do
      turn_on_plugin_settings
      f('.save_button').click
      course_with_teacher_logged_in :account => @account, :active_all => true
      @course.wiki.wiki_pages.create!(title: 'Page1')
      file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/pages/Page1/edit"
      ff(".ui-tabs-anchor")[1].click
      ff(".name.text")[0].click
      wait_for_ajaximations
      ff(".name.text")[1].click
      wait_for_ajaximations
      ff(".name.text")[2].click
      wait_for_ajaximations
      f(".btn-primary").click
      expect(f(".scribd_file_preview_link")).to be_present
    end
  end
end
