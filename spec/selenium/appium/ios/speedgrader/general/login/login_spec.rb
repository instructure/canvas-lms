require_relative '../../../helpers/login_common'

describe 'user logging into speedgrader app' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'speedgrader_ios'
  let(:app_login_message){ 'SpeedGrader' }
  let(:app_access_message){ 'SpeedGrader is requesting access to your account.' }
  let(:app_login_success){ 'CSGSlideMenuView' }

  # examples located in: spec/selenium/appium/ios/helpers/login_common.rb
  it_behaves_like 'icanvas and speedgrader login credentials', 'speedgrader_ios'
end
