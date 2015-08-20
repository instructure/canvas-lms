require_relative '../../../helpers/login_common'

describe 'speedgrader login credentials' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'speedgrader_android'
  let(:app_login_message){ /(Canvas for Android)/ } # TODO: ask dev team to modify this for Speedgrader
  let(:app_access_message){ /Canvas for Android is requesting access.*/ } # TODO: ask dev team to modify this for Speedgrader

  # examples located in: spec/selenium/appium/android/helpers/login_common.rb
  it_behaves_like 'login credentials for candroid and speedgrader', 'speedgrader_android'
end
