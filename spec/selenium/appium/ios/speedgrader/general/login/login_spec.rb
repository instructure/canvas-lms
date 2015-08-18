require_relative '../../../helpers/login_common'

describe 'user logging into speedgrader app' do
  include_examples 'in-process server selenium tests'
  include_examples 'appium mobile specs', 'speedgrader_ios'

  it_behaves_like 'icanvas and speedgrader login credentials', 'speedgrader_ios'
end
