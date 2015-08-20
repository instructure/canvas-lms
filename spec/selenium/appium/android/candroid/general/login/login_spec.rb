require_relative '../../../helpers/login_common'

describe 'candroid login credentials' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'candroid'
  let(:app_login_message){ /(Canvas for Android)/ }
  let(:app_access_message){ /Canvas for Android is requesting access.*/ }

  # examples located in: spec/selenium/appium/android/helpers/login_common.rb
  it_behaves_like 'login credentials for candroid and speedgrader', 'candroid'
end
