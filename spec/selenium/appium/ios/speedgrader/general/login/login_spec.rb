require_relative '../../../helpers/login_common'

describe 'user logging into speedgrader app' do
  include_examples 'in-process server selenium tests'
  include_examples 'appium mobile specs', 'speedgrader_ios'
  let(:app_login_message){ 'SpeedGrader' }
  let(:app_access_message){ 'SpeedGrader is requesting access to your account.' }
  let(:app_login_success){ 'CSGSlideMenuView' }

  # examples located in: spec/selenium/appium/ios/helpers/login_common.rb
  it_behaves_like 'icanvas and speedgrader login credentials', 'speedgrader_ios'
end
