require_relative '../../../helpers/landing_page_common'

describe 'speedgrader for android landing page' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'speedgrader_android'
  let(:default_url){ 'myschool.instructure.com' }

  # examples located in: spec/selenium/appium/android/helpers/landing_page_common.rb
  it_behaves_like 'candroid and speedgrader landing page', 'speedgrader_android'
end
