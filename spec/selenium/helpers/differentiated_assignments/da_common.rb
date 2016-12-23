require_relative '../../common'
require_relative 'da_module'

shared_context 'differentiated assignments' do
  include DifferentiatedAssignments
  include_context 'in-process server selenium tests'

  before(:once) { DifferentiatedAssignments.initialize }

  let(:assignments) { DifferentiatedAssignments::Homework::Assignments }
  let(:discussions) { DifferentiatedAssignments::Homework::Discussions }
  let(:quizzes)     { DifferentiatedAssignments::Homework::Quizzes }
  let(:users)       { DifferentiatedAssignments::Users }
  let(:urls)        { DifferentiatedAssignments::URLs }

  def login_as(user)
    user_session(user)
  end

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
