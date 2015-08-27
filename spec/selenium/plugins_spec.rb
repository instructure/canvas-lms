require File.expand_path(File.dirname(__FILE__) + '/common')

describe "plugins ui" do
  include_examples "in-process server selenium tests"

  before(:each) do
    site_admin_logged_in
  end

  after(:each) do
    truncate_table PluginSetting
  end

  it 'should have plugins default to disabled when no plugin_setting exits' do
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy

    multiple_accounts_select
    expect_new_page_load { submit_form("#new_plugin_setting") }
    expect(PluginSetting.all.count).to eq 1
    PluginSetting.first.tap do |ps|
      expect(ps.name).to eq "etherpad"
      expect(ps.disabled).to be_truthy
    end
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy
  end

  it 'should have plugin settings not disabled when set' do
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy
    multiple_accounts_select
    f('#plugin_setting_disabled').click
    expect_new_page_load { submit_form("#new_plugin_setting") }
    expect(PluginSetting.all.count).to eq 1
    PluginSetting.first.tap do |ps|
      expect(ps.name).to eq "etherpad"
      expect(ps.disabled).to be_falsey
    end
    get '/plugins/etherpad'

    multiple_accounts_select
    expect(is_checked('#plugin_setting_disabled')).to be_falsey
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
    expect(plugin_setting.settings["other_thingy"]).to eq "dude"
  end

  def multiple_accounts_select
    if !f("#plugin_setting_disabled").displayed?
      f("#accounts_select option:nth-child(2)").click
      keep_trying_until { f("#plugin_setting_disabled").displayed? }
    end
  end

end

