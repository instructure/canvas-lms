require_relative '../../../helpers/landing_page_common'

describe 'icanvas landing page' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'icanvas'

  it_behaves_like 'icanvas and speedgrader landing page', 'icanvas'
end
