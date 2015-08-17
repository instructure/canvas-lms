require_relative '../../../helpers/landing_page_common'

describe 'icanvas landing page' do
  include_examples 'in-process server selenium tests'
  include_examples 'appium mobile specs', 'icanvas'

  it_behaves_like 'icanvas and speedgrader landing page', 'icanvas'
end
