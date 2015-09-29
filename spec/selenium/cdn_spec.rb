# Why are these in spec/selenium?
# ===============================
# Although these tests don't use selenium at all, they need to be have assets
# compiled in order to work. eg: `gulp rev` and `brandable_css` need to run first.
# By putting them in spec/selenium, our build server will run them with the rest
# of the browser specs, after it has compiled assets.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RE_SHORT_MD5 = /\A[a-f0-9]{10}\z/ # 10 chars of an MD5

EXAMPLE_CDN_HOST = 'https://somecdn.example.com'

describe 'Stuff related to how we load stuff from CDN and use brandable_css' do

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

          msg = "all variants should outupt the same css if a bundle doesn't pull in
                 the variables file. If it does, there should be some that are different"
          unique_fingerprints = fingerprints.map{ |f| f[:combinedChecksum] }.uniq
          expect(unique_fingerprints.length).to(includes_no_variables ? eq(1): (be > 1), msg)
        end
      end
    end
  end


  def check_css(bundle_name)
    fingerprint = BrandableCSS.cache_for(bundle_name, 'legacy_normal_contrast')[:combinedChecksum]
    expect(fingerprint).to match(RE_SHORT_MD5)
    assert_tag(tag: 'link', attributes: {
      rel: 'stylesheet',
      href: "#{EXAMPLE_CDN_HOST}/dist/brandable_css/legacy_normal_contrast/#{bundle_name}-#{fingerprint}.css"
    })
  end

  def check_asset(tag, asset_path)
    revved_path = Canvas::Cdn::RevManifest.url_for(asset_path)
    expect(revved_path).to be_present
    attributes = {}
    attributes[(tag == 'link') ? :href : :src] = "#{EXAMPLE_CDN_HOST}#{revved_path}"
    assert_tag(tag: tag, attributes: attributes)
  end

  describe 'urls for script tag and stylesheets on actual pages', :type => :request do

    it 'has the right stuff on the login page' do
      Canvas::Cdn.config.expects(:host).at_least_once.returns(EXAMPLE_CDN_HOST)
      get '/login/canvas'

      ['bundles/common', 'bundles/login'].each { |bundle| check_css(bundle) }
      ['images/favicon-yellow.ico', 'images/apple-touch-icon.png'].each { |i| check_asset('link', i) }
      js_base_url = ENV['USE_OPTIMIZED_JS'] == 'true' ? '/optimized' : '/javascripts'
      ['vendor/require.js', 'compiled/bundles/login.js'].each { |s| check_asset('script', "#{js_base_url}/#{s}") }
    end

    it "loads custom js 'raw' on mobile login screen" do
      js_url = 'https://example.com/path/to/some/file.js'
      Account.default.settings[:global_includes] = true
      Account.default.settings[:global_javascript] = js_url
      Account.default.save!

      get '/login/canvas', {}, { 'HTTP_USER_AGENT' => 'iphone' }
      # match /optimized/vendor/jquery-1.7.2.js?1440111591 or /optimized/vendor/jquery-1.7.2.js
      assert_tag(tag: 'script', attributes: { src: /^\/optimized\/vendor\/jquery-1.7.2.js(\?\d+)*$/})
      assert_tag(tag: 'script', attributes: { src: js_url})
    end
  end
end