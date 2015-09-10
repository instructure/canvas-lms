require File.expand_path(File.dirname(__FILE__) + '/common')

describe "brandableCss JS integration specs" do
  include_context "in-process server selenium tests"

  EXAMPLE_CDN_HOST = 'https://somecdn.example.com'

  it "sets ENV.asset_host correctly" do
    Canvas::Cdn.config.expects(:host).at_least_once.returns(EXAMPLE_CDN_HOST)
    get "/login/canvas"
    expect(driver.execute_script("return ENV.ASSET_HOST")).to eq(EXAMPLE_CDN_HOST)
  end

  it "loads css from handlebars correctly" do
    admin_logged_in
    get "/accounts/#{Account.default.id}/permissions?account_roles=1"

    css_bundle = 'jst/roles/rolesOverrideIndex'
    fingerprint = BrandableCSS.fingerprint_for(css_bundle, 'legacy_normal_contrast')
    css_url = "#{Canvas::Cdn.config.host}/dist/brandable_css/legacy_normal_contrast/#{css_bundle}-#{fingerprint}.css"
    expect(fj("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='#{css_bundle}']")['href']).to match(css_url)

    driver.execute_script("window.ENV.ASSET_HOST = '#{EXAMPLE_CDN_HOST}'")
    EXAMPLE_CSS_BUNDLE = 'jst/some/css/bundle-12345.css'
    require_exec('compiled/util/brandableCss', "brandableCss.loadStylesheet('#{EXAMPLE_CSS_BUNDLE}')")
    css_url = "#{EXAMPLE_CDN_HOST}/dist/brandable_css/legacy_normal_contrast/#{EXAMPLE_CSS_BUNDLE}.css"
    expect(fj("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='jst/some/css/bundle']")['href']).to eq(css_url)
  end

end

