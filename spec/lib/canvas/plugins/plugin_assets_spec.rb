require File.expand_path(File.dirname(__FILE__) + '/../../../../lib/canvas/plugins/plugin_assets')

describe PluginAssets do

  let(:plugin_assets) { PluginAssets.new }
  let(:fixture_assets) { PluginAssets.new( :asset_matcher => 'spec/fixtures/asset_files/*.yml', :plugin_matcher => %r{(\w+)\.yml$} ) }

  describe '#initialize' do

    describe 'with no options' do
      subject { plugin_assets }

      its(:anchors){ should == { 'stylesheets' => {} } }
      its(:asset_matcher){ should == 'vendor/plugins/*/config/assets.yml' }
      its(:plugin_matcher) { should == %r{^vendor/plugins/(.*)/config/assets\.yml$} }
    end

    describe 'with an options hash' do
      let(:options) { {:asset_matcher => 'test/*/file.yml', :plugin_matcher => %r{(\w+)} } }
      subject { PluginAssets.new options }

      its(:asset_matcher) { should == options[:asset_matcher] }
      its(:plugin_matcher) { should == options[:plugin_matcher] }
    end

  end

  describe '#bundle_yml' do
    subject { fixture_assets.bundle_yml }

    it { should =~ %r{plugin_assets_1:\s+stylesheets:} }
    it { should =~ %r{plugin_assets_2:\s+stylesheets:} }
    it { should =~ %r{plugins/plugin_assets_1/first_plugin\.css} }
    it { should =~ %r{plugins/plugin_assets_1/first_plugin_alt\.css} }
    it { should =~ %r{plugins/plugin_assets_2/second_plugin\.css} }
    it { should =~ %r{plugins/plugin_assets_2/second_plugin_alt\.css} }
  end

  describe '#anchors_yml' do
    subject { fixture_assets.anchors_yml }

    it { should =~ %r{plugins_plugin_assets_1_first_plugin: \*stylesheets_plugins_plugin_assets_1_first_plugin} }
    it { should =~ %r{plugins_plugin_assets_1_first_plugin_alt: \*stylesheets_plugins_plugin_assets_1_first_plugin_alt} }
    it { should =~ %r{plugins_plugin_assets_2_second_plugin: \*stylesheets_plugins_plugin_assets_2_second_plugin} }
    it { should =~ %r{plugins_plugin_assets_2_second_plugin_alt: \*stylesheets_plugins_plugin_assets_2_second_plugin_alt} }

    #check indent depth
    it { should =~ %r{^  plugins} }
    it { should_not =~ %r{^    plugins} }

    describe 'with overriden indent' do
      subject { fixture_assets.anchors_yml(:indent_depth => 4) }

      it { should =~ %r{plugins_plugin_assets_1_first_plugin: \*stylesheets_plugins_plugin_assets_1_first_plugin} }
      it { should =~ %r{^    plugins} }
      it { should_not =~ %r{^  plugins} }
    end
  end


  describe '#for_each_plugin' do

    before do
      @yield_values = []
      fixture_assets.for_each_plugin { |name, yaml| @yield_values << [name, yaml] }
    end

    it 'pulls the plugin names correctly' do
      @yield_values[0][0].should ==  'plugin_assets_1'
      @yield_values[1][0].should ==  'plugin_assets_2'
    end

    it 'parses the yaml files' do
      @yield_values[0][1]["stylesheets"].keys.sort.should == ['first_plugin', 'first_plugin_alt']
      @yield_values[1][1]["stylesheets"].keys.sort.should == ['second_plugin', 'second_plugin_alt']
    end
  end

  describe '#format_bundle_entry' do
    let(:plugin) { "plugin_name" }

    def formatted(path)
      fixture_assets.format_bundle_entry( path, plugin )
    end

    it 'tacks a plugin path onto a compiled css path' do
      formatted('public/stylesheets/compiled/something.css').should == "public/stylesheets/compiled/plugins/#{plugin}/something.css"
    end

    it 'expands a simple path with the plugin name' do
      formatted( 'public/jellyfish/sting.txt').should == "public/plugins/#{plugin}/jellyfish/sting.txt"
    end

    it 'moves plugin_name from before the path into the middle of the path for a compiled css path' do
      new_path = formatted( 'other_plugin_name:public/stylesheets/compiled/something.css' )
      new_path.should == "public/stylesheets/compiled/plugins/other_plugin_name/something.css"
    end

    it 'moves the plugin_name forward on a simiple path' do
      formatted( 'other_plugin:public/simple/path.css' ).should == "public/plugins/other_plugin/simple/path.css"
    end
  end

  describe '#plugin_name_for' do
    it 'pulls the plugin name out of well formed paths' do
      plugin_assets.plugin_name_for('vendor/plugins/analytics/config/assets.yml').should == 'analytics'
    end

    it 'errors on badly formed paths' do
      lambda { plugin_assets.plugin_name_for('bogus/path/blargh.yml') }.should raise_error(ArgumentError, 'must provide a valid plugin asset.yml path')
    end
  end

  describe '#plugin_assets' do
    it 'builds a hash for dumping to yaml' do
      fixture_assets.plugin_assets.should == {
        "plugin_assets_2" => {
          "stylesheets" => {
            "plugins/plugin_assets_2/stylesheets/second_plugin" => ["public/stylesheets/compiled/plugins/plugin_assets_2/second_plugin.css"],
            "plugins/plugin_assets_2/stylesheets/second_plugin_alt" => ["public/stylesheets/compiled/plugins/plugin_assets_2/second_plugin_alt.css"]
          }
        },
        "plugin_assets_1" => {
          "stylesheets" => {
            "plugins/plugin_assets_1/stylesheets/first_plugin_alt" => ["public/stylesheets/compiled/plugins/plugin_assets_1/first_plugin_alt.css"],
            "plugins/plugin_assets_1/stylesheets/first_plugin" => ["public/stylesheets/compiled/plugins/plugin_assets_1/first_plugin.css"]
          }
        }
      }
    end
  end

end
