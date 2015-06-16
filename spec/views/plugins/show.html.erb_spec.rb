require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "plugins/show" do
  it "renders without exploding" do
    plugin = stub(
      id: 'some_plugin',
      name: "Some Plugin",
      settings_partial: "settings_header"
    )
    plugin_setting = PluginSetting.new()

    assigns[:plugin] = plugin
    assigns[:plugin_setting] = plugin_setting
    view.stubs(:plugin_path).returns("/some/path")
    view.stubs(:params).returns({id: 'some_plugin'})
    render 'plugins/show'
    expect(response.body).to match("Return to plugins list")
  end
end
