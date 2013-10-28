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

    multiple_accounts_select
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
    multiple_accounts_select
    f('#plugin_setting_disabled').click
    expect_new_page_load { submit_form("#new_plugin_setting") }
    PluginSetting.all.count.should == 1
    PluginSetting.first.tap do |ps|
      ps.name.should == "etherpad"
      ps.disabled.should be_false
    end
    get '/plugins/etherpad'

    multiple_accounts_select
    is_checked('#plugin_setting_disabled').should be_false
  end

  it "should not overwrite settings that are not shown" do
    get '/plugins/etherpad'

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    expect_new_page_load { submit_form("#new_plugin_setting") }

    plugin_setting = PluginSetting.last
    plugin_setting.settings["other_thingy"] = "dude"
    plugin_setting.save!

    expect_new_page_load { submit_form("#edit_plugin_setting_#{plugin_setting.id}") }

    plugin_setting.reload
    plugin_setting.settings["other_thingy"].should == "dude"
  end

  def multiple_accounts_select
    if !f("#plugin_setting_disabled").displayed?
      f("#accounts_select option:nth-child(2)").click
      keep_trying_until { f("#plugin_setting_disabled").displayed? }
    end
  end

end

