require_relative '../../common'
require_relative 'selective_release_module'

shared_context 'selective release' do
  include SelectiveRelease
  include_context 'in-process server selenium tests'

  before(:once) { SelectiveRelease.initialize }

  def go_to(url)
    get url
  end

  def list_of_assignments
    find('.assignment-list')
  end

  def list_of_modules
    find('#context_modules')
  end
end
