require_relative '../../../helpers/landing_page_common'

describe 'candroid landing page' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'candroid'
  let(:default_url){ 'Find your school or district' }

  # examples located in: spec/selenium/appium/android/helpers/landing_page_common.rb
  it_behaves_like 'candroid and speedgrader landing page', 'candroid'
end
