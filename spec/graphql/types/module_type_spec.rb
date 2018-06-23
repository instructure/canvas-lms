#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::ModuleType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:mod) { course.context_modules.create! name: "module", unlock_at: 1.week.from_now }
  let(:module_type) { GraphQLTypeTester.new(Types::ModuleType, mod) }

  it "works" do
    expect(module_type.name).to eq mod.name
    expect(module_type.unlockAt).to eq mod.unlock_at
  end
end
