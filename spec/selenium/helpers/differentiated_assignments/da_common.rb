#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../../common'
require_relative 'da_module'

shared_context 'differentiated assignments' do
  include DifferentiatedAssignments
  include_context 'in-process server selenium tests'

  before(:once) { DifferentiatedAssignments.short_list_initialize }

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
