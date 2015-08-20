require_relative '../../../helpers/landing_page_common'

describe 'speedgrader for ios landing page' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'speedgrader_ios'

  it_behaves_like 'icanvas and speedgrader landing page', 'speedgrader_ios'
end
