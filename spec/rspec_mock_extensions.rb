#
# Copyright (C) 2011 - present Instructure, Inc.
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

# allows setting up mocks/stubs that will be automatically applied any time
# this AR instance is instantiated, through find or whatever
# the record must be saved before calling any_instantiation, so that it has an id
module RspecMockAnyInstantiation
  def allow_any_instantiation_of(ar_object)
    ActiveRecord::Base.add_any_instantiation(ar_object)
    allow(ar_object)
  end

  def expect_any_instantiation_of(ar_object)
    ActiveRecord::Base.add_any_instantiation(ar_object)
    expect(ar_object)
  end
end

RSpec::Mocks::ExampleMethods.include(RspecMockAnyInstantiation)
unless ENV['NO_MOCHA']
  RSpec::Core::ExampleGroup.include(RspecMockAnyInstantiation)
end
