#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::AssignmentGroupRulesType do

  let(:rules) do
    course_with_student(active_all: true)
    group = @course.assignment_groups.create!(name: 'a group')
    @assignment = @course.assignments.create!(name: 'a assignment')
    rules = {
      :drop_highest => 1,
      :drop_lowest => 3,
      :never_drop => [@assignment.id]
    }
    group.rules_hash = rules
  end

  let(:rules_type) { GraphQLTypeTester.new(Types::AssignmentGroupRulesType, rules) }
  context "returns from hash:" do
    it "never drop" do
      expect(rules_type.neverDrop).to eq([@assignment])
    end

    it "drop lowest" do
      expect(rules_type.dropLowest).to eq(rules[:drop_lowest])
    end

    it "drop highest" do
      expect(rules_type.dropHighest).to eq(rules[:drop_highest])
    end
  end
end