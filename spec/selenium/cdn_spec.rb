# Why are these in spec/selenium?
# ===============================
# Although these tests don't use selenium at all, they need to be have assets
# compiled in order to work. eg: `gulp rev` and `brandable_css` need to run first.
# By putting them in spec/selenium, our build server will run them with the rest
# of the browser specs, after it has compiled assets.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/common')

RE_SHORT_MD5 = /\A[a-f0-9]{10}\z/ # 10 chars of an MD5

EXAMPLE_CDN_HOST = 'https://somecdn.example.com'

describe 'Stuff related to how we load stuff from CDN and use brandable_css' do
  include_context "in-process server selenium tests"

  describe BrandableCSS do

    describe 'cache_for' do

      it 'finds the right fingerprints for normal bundles, plugins & handlebars' do
        sample_bundles = {
          'bundles/common' => false,
          'plugins/analytics/analytics' => false, # to test that it works with plugins
          'jst/tinymce/EquationEditorView' => true # to test that it works with handlebars-loaded css
        }
        sample_bundles.each do |bundle_name, includes_no_variables|
          fingerprints = BrandableCSS.variants.map do |variant|
            data = BrandableCSS.cache_for(bundle_name, variant)
            expect(data[:combinedChecksum]).to match(RE_SHORT_MD5)
            expect(!!(data[:includesNoVariables])).to eq(includes_no_variables)
            data
          end

          expect(fingerprints.length).to eq(4), 'We have 4 variants'
          msg = 'make sure the conbined results match the result of all_fingerprints_for'
          expect(fingerprints).to eq(BrandableCSS.all_fingerprints_for(bundle_name).values), msg

          if includes_no_variables
            msg = "all variants should outupt the same css if a bundle doesn't pull in the variables file"
            unique_fingerprints = fingerprints.map{ |f| f[:combinedChecksum] }.uniq
            expect(unique_fingerprints.length).to eq(1), msg
          end
        end
      end
    end
  end

  def assert_tag(tag, attribute, value)
    selector = "#{tag}[#{attribute}='#{value}']"
    expect(f(selector)).to be_present
  end

  def check_css(bundle_name)
    variant = ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? 'new_styles_normal_contrast' : 'legacy_normal_contrast'
    fingerprint = BrandableCSS.cache_for(bundle_name, variant)[:combinedChecksum]
    expect(fingerprint).to match(RE_SHORT_MD5)
    url = "#{EXAMPLE_CDN_HOST}/dist/brandable_css/#{variant}/#{bundle_name}-#{fingerprint}.css"
    assert_tag('link', 'href', url)
  end

  def check_asset(tag, asset_path)
    revved_path = Canvas::Cdn::RevManifest.url_for(asset_path)
    expect(revved_path).to be_present
    attribute = (tag == 'link') ? 'href' : 'src'
    url = "#{EXAMPLE_CDN_HOST}#{revved_path}"
    assert_tag(tag, attribute, url)
  end

  it 'has the right urls for script tag and stylesheets on the login page' do
    Canvas::Cdn.config.expects(:host).at_least_once.returns(EXAMPLE_CDN_HOST)
    get '/login/canvas'

    ['bundles/common', 'bundles/login'].each { |bundle| check_css(bundle) }
    ['images/favicon-yellow.ico', 'images/apple-touch-icon.png'].each { |i| check_asset('link', i) }
    optimized_js_flag = ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
    js_base_url =  optimized_js_flag ? '/optimized' : '/javascripts'
    expected_js_bundles = ['vendor/require.js', 'compiled/bundles/login.js']
    if CANVAS_WEBPACK
      js_base_url =  optimized_js_flag ? '/webpack-dist-optimized' : '/webpack-dist'
      expected_js_bundles = ['vendor.bundle.js', 'instructure-common.bundle.js', 'login.bundle.js']
    end
    expected_js_bundles.each { |s| check_asset('script', "#{js_base_url}/#{s}") }
  end
end
