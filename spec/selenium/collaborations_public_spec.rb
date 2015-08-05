require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "collaborations for a public course" do
  include_examples "in-process server selenium tests"
  include_context "public course as a logged out user"

  #this is currently broken - logged out users should not be able to access this page
  it "should display collaborations list" do
    PluginSetting.new(:name => 'etherpad', :settings => {}).save!
    get "/courses/#{public_course.id}/collaborations"
    expect(f('#collaborations')).to be_displayed
  end
end