require_relative '../../../helpers/landing_page_common'

describe 'speedgrader for ios landing page' do
  include_examples 'in-process server selenium tests'
  include_examples 'appium mobile specs', 'speedgrader_ios'

  it_behaves_like 'icanvas and speedgrader landing page', 'speedgrader_ios'
end
