require File.expand_path(File.dirname(__FILE__) + '/common')

describe "google analytics" do
  include_context "in-process server selenium tests"

  it "should not include tracking script if not asked to" do
    get "/"
    expect(f("#content")).not_to contain_jqcss('script[src$="google-analytics.com/ga.js"]')
  end
  
  it "should include tracking script if google_analytics_key is configured" do
    Setting.set('google_analytics_key', 'testing123')
    get "/"
    expect(fj('script[src$="google-analytics.com/ga.js"]')).not_to be_nil
  end
end
