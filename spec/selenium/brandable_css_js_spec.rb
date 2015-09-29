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
    data = BrandableCSS.all_fingerprints_for(css_bundle).values.first
    expect(data[:includesNoVariables]).to be_truthy
    expect(data[:combinedChecksum]).to match(/\A[a-f0-9]{10}\z/), '10 chars of an MD5'
    url = "#{Canvas::Cdn.config.host || app_host}/dist/brandable_css/no_variables/#{css_bundle}-#{data[:combinedChecksum]}.css"
    expect(fj("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='#{css_bundle}']")['href']).to eq(url)

    driver.execute_script("window.ENV.ASSET_HOST = '#{EXAMPLE_CDN_HOST}'")
    require_exec('compiled/util/brandableCss', "brandableCss.loadStylesheet('jst/some/css/bundle', {combinedChecksum: 'abcde12345'})")
    url = "#{EXAMPLE_CDN_HOST}/dist/brandable_css/legacy_normal_contrast/jst/some/css/bundle-abcde12345.css"
    expect(fj("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='jst/some/css/bundle']")['href']).to eq(url)
  end

  it "loads css from handlebars with variables correctly" do
    Account.default.enable_feature!(:use_new_styles)
    course_with_teacher_logged_in
    get '/calendar'
    data = BrandableCSS.cache_for('jst/calendar/calendarApp', 'new_styles_normal_contrast')
    expect(data[:includesNoVariables]).to be_falsy
    expect(data[:combinedChecksum]).to match(/\A[a-f0-9]{10}\z/), '10 chars of an MD5'
    url = "#{Canvas::Cdn.config.host || app_host}/dist/brandable_css/new_styles_normal_contrast/jst/calendar/calendarApp-#{data[:combinedChecksum]}.css"
    expect(fj("head link[rel='stylesheet'][data-loaded-by-brandableCss][href*='calendarApp']")['href']).to eq(url)
  end
end
