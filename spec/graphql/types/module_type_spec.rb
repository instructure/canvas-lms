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
require_relative "../graphql_spec_helper"

describe Types::ModuleType do
  let_once(:course) { course_with_student(active_all: true); @course }
  let_once(:mod) { course.context_modules.create! name: "module", unlock_at: 1.week.from_now }
  let(:module_type) { GraphQLTypeTester.new(mod, current_user: @student) }

  it "works" do
    expect(module_type.resolve("name")).to eq mod.name
    expect(module_type.resolve("unlockAt")).to eq mod.unlock_at.iso8601
  end

  it "has module items" do
    a1 = assignment_model({context: course})
    a2 = assignment_model({context: course})
    item1 = mod.add_item({type: 'Assignment', id: a1.id}, nil, position: 1)
    item2 = mod.add_item({type: 'Assignment', id: a2.id}, nil, position: 2)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item1.id.to_s, item2.id.to_s]
  end

  it "requires read permissions to view module items" do
    a1 = assignment_model({context: course})
    a2 = assignment_model({context: course})
    a1.workflow_state = "unpublished"
    a1.save!
    item1 = mod.add_item({type: 'Assignment', id: a1.id}, nil, position: 1)
    item2 = mod.add_item({type: 'Assignment', id: a2.id}, nil, position: 2)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item2.id.to_s]
  end

  it "orders module items by position" do
    a1 = assignment_model({context: course, name: 'zzz'})
    a2 = assignment_model({context: course, name: 'aaa'})
    item2 = mod.add_item({type: 'Assignment', id: a2.id}, nil, position: 2)
    item1 = mod.add_item({type: 'Assignment', id: a1.id}, nil, position: 1)
    expect(module_type.resolve("moduleItems { _id }")).to eq [item1.id.to_s, item2.id.to_s]
  end
end
