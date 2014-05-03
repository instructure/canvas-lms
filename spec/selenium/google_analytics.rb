require File.expand_path(File.dirname(__FILE__) + '/common')

describe "google analytics" do
  include_examples "in-process server selenium tests"

  it "should not include tracking script if not asked to" do
    get "/"
    fj('script[src$="google-analytics.com/ga.js"]').should be_nil
  end
  
  it "should include tracking script if google_analytics_key is configured" do
    Setting.set('google_analytics_key', 'testing123')
    get "/"
    fj('script[src$="google-analytics.com/ga.js"]').should_not be_nil
  end
end
