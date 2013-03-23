require File.expand_path(File.dirname(__FILE__) + '/common')

describe "plugins ui" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    site_admin_logged_in
  end

  after(:each) do
    truncate_table PluginSetting
  end

  it 'should have plugins default to disabled when no plugin_setting exits' do
    get '/plugins/etherpad'
    is_checked('#plugin_setting_disabled').should be_true

    expect_new_page_load { submit_form("#new_plugin_setting") }
    PluginSetting.all.count.should == 1
    PluginSetting.first.tap do |ps|
      ps.name.should == "etherpad"
      ps.disabled.should be_true
    end
    get '/plugins/etherpad'
    is_checked('#plugin_setting_disabled').should be_true
  end

  it 'should have plugin settings not disabled when set' do
    get '/plugins/etherpad'
    is_checked('#plugin_setting_disabled').should be_true
    f('#plugin_setting_disabled').click
    expect_new_page_load { submit_form("#new_plugin_setting") }
    PluginSetting.all.count.should == 1
    PluginSetting.first.tap do |ps|
      ps.name.should == "etherpad"
      ps.disabled.should be_false
    end
    get '/plugins/etherpad'
    is_checked('#plugin_setting_disabled').should be_false
  end
end

