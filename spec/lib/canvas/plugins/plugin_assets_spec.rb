require File.expand_path(File.dirname(__FILE__) + '/../../../../lib/canvas/plugins/plugin_assets')

describe PluginAssets do

  let(:plugin_assets) { PluginAssets.new }
  let(:fixture_assets) { PluginAssets.new( :asset_matcher => 'spec/fixtures/asset_files/*.yml', :plugin_matcher => %r{(\w+)\.yml$} ) }

  describe '#initialize' do

    describe 'with no options' do
      subject { plugin_assets }

      describe '#anchors' do
        subject { super().anchors }
        it { is_expected.to eq({ 'stylesheets' => {} }) }
      end

      describe '#asset_matcher' do
        subject { super().asset_matcher }
        it { is_expected.to eq '{gems,vendor}/plugins/*/config/assets.yml' }
      end

      describe '#plugin_matcher' do
        subject { super().plugin_matcher }
        it { is_expected.to eq %r{^(?:gems|vendor)/plugins/(.*)/config/assets\.yml$} }
      end
    end

    describe 'with an options hash' do
      let(:options) { {:asset_matcher => 'test/*/file.yml', :plugin_matcher => %r{(\w+)} } }
      subject { PluginAssets.new options }

      describe '#asset_matcher' do
        subject { super().asset_matcher }
        it { is_expected.to eq options[:asset_matcher] }
      end

      describe '#plugin_matcher' do
        subject { super().plugin_matcher }
        it { is_expected.to eq options[:plugin_matcher] }
      end
    end

  end

  describe '#bundle_yml' do
    subject { fixture_assets.bundle_yml }

    it { is_expected.to match %r{plugin_assets_1:\s+stylesheets:} }
    it { is_expected.to match %r{plugin_assets_2:\s+stylesheets:} }
    it { is_expected.to match %r{plugins/plugin_assets_1/first_plugin\.css} }
    it { is_expected.to match %r{plugins/plugin_assets_1/first_plugin_alt\.css} }
    it { is_expected.to match %r{plugins/plugin_assets_2/second_plugin\.css} }
    it { is_expected.to match %r{plugins/plugin_assets_2/second_plugin_alt\.css} }
  end

  describe '#anchors_yml' do
    subject { fixture_assets.anchors_yml }

    it { is_expected.to match %r{plugins_plugin_assets_1_first_plugin: \*stylesheets_plugins_plugin_assets_1_first_plugin} }
    it { is_expected.to match %r{plugins_plugin_assets_1_first_plugin_alt: \*stylesheets_plugins_plugin_assets_1_first_plugin_alt} }
    it { is_expected.to match %r{plugins_plugin_assets_2_second_plugin: \*stylesheets_plugins_plugin_assets_2_second_plugin} }
    it { is_expected.to match %r{plugins_plugin_assets_2_second_plugin_alt: \*stylesheets_plugins_plugin_assets_2_second_plugin_alt} }

    #check indent depth
    it { is_expected.to match %r{^  plugins} }
    it { is_expected.not_to match %r{^    plugins} }

    describe 'with overriden indent' do
      subject { fixture_assets.anchors_yml(:indent_depth => 4) }

      it { is_expected.to match %r{plugins_plugin_assets_1_first_plugin: \*stylesheets_plugins_plugin_assets_1_first_plugin} }
      it { is_expected.to match %r{^    plugins} }
      it { is_expected.not_to match %r{^  plugins} }
    end
  end


  describe '#for_each_plugin' do

    before do
      @yield_values = []
      fixture_assets.for_each_plugin { |name, yaml| @yield_values << [name, yaml] }
    end

    it 'pulls the plugin names correctly' do
      expect(@yield_values[0][0]).to eq  'plugin_assets_1'
      expect(@yield_values[1][0]).to eq  'plugin_assets_2'
    end

    it 'parses the yaml files' do
      expect(@yield_values[0][1]["stylesheets"].keys.sort).to eq ['first_plugin', 'first_plugin_alt']
      expect(@yield_values[1][1]["stylesheets"].keys.sort).to eq ['second_plugin', 'second_plugin_alt']
    end
  end

  describe '#format_bundle_entry' do
    let(:plugin) { "plugin_name" }

    def formatted(path)
      fixture_assets.format_bundle_entry( path, plugin )
    end

    it 'tacks a plugin path onto a compiled css path' do
      expect(formatted('public/stylesheets/compiled/something.css')).to eq "public/stylesheets/compiled/plugins/#{plugin}/something.css"
    end

    it 'expands a simple path with the plugin name' do
      expect(formatted( 'public/jellyfish/sting.txt')).to eq "public/plugins/#{plugin}/jellyfish/sting.txt"
    end

    it 'moves plugin_name from before the path into the middle of the path for a compiled css path' do
      new_path = formatted( 'other_plugin_name:public/stylesheets/compiled/something.css' )
      expect(new_path).to eq "public/stylesheets/compiled/plugins/other_plugin_name/something.css"
    end

    it 'moves the plugin_name forward on a simiple path' do
      expect(formatted( 'other_plugin:public/simple/path.css' )).to eq "public/plugins/other_plugin/simple/path.css"
    end
  end

  describe '#plugin_name_for' do
    it 'pulls the plugin name out of well formed vendor/plugin paths' do
      expect(plugin_assets.plugin_name_for('vendor/plugins/analytics/config/assets.yml')).to eq 'analytics'
    end

    it 'pulls the plugin name out of well formed gems/plugin paths' do
      expect(plugin_assets.plugin_name_for('gems/plugins/analytics/config/assets.yml')).to eq 'analytics'
    end

    it 'errors on badly formed paths' do
      expect { plugin_assets.plugin_name_for('bogus/path/blargh.yml') }.to raise_error(ArgumentError, 'must provide a valid plugin asset.yml path')
    end
  end

  describe '#plugin_assets' do
    it 'builds a hash for dumping to yaml' do
      expect(fixture_assets.plugin_assets).to eq({
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
      })
    end
  end

end
