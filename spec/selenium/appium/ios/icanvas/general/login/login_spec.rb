require_relative '../../../helpers/login_common'

describe 'user logging into icanvas app' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'icanvas'
  let(:app_login_message){ 'Canvas for iOS' }
  let(:app_access_message){ 'Canvas for iOS is requesting access to your account.' }
  let(:app_login_success){ 'Profile' }

  # examples located in: spec/selenium/appium/ios/helpers/login_common.rb
  it_behaves_like 'icanvas and speedgrader login credentials', 'icanvas'
end
