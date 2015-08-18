require_relative '../../../helpers/login_common'

describe 'user logging into icanvas app' do
  include_examples 'in-process server selenium tests'
  include_examples 'appium mobile specs', 'icanvas'

  it_behaves_like 'icanvas and speedgrader login credentials', 'icanvas'
end
