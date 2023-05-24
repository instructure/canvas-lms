# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../support/boolean_translator"

module GroupCategories
  MockGroupCategory = Struct.new(:name,
                                 :self_signup,
                                 :auto_leader,
                                 :group_limit,
                                 :create_group_count,
                                 :create_group_member_count,
                                 :assign_unassigned_members,
                                 :group_by_section)

  describe ParamsPolicy do
    let(:populate_options) do
      { boolean_translator: BooleanTranslator }
    end

    describe "intializer" do
      it "accepts a category and context" do
        category = double("group_category")
        context = double("course")
        policy = ParamsPolicy.new(category, context)
        expect(policy.group_category).to eq category
        expect(policy.context).to eq context
      end
    end

    describe "#populate_with" do
      let(:category) { MockGroupCategory.new }
      let(:context) { double("course") }
      let(:policy) { ParamsPolicy.new(category, context) }

      it "configures the self_signup accoring to the params" do
        policy.populate_with({ enable_self_signup: true }, populate_options)
        expect(category.self_signup).to eq "enabled"
      end

      it "sets up the autoleader value" do
        policy.populate_with({ enable_auto_leader: "1", auto_leader_type: "RANDOM" }, populate_options)
        expect(category.auto_leader).to eq("random")
      end

      it "can null out an existing autoleader value" do
        category.auto_leader = "FIRST"
        policy.populate_with({ enable_auto_leader: "0", auto_leader_type: "RANDOM" }, populate_options)
        expect(category.auto_leader).to be_nil
      end

      it "lets you override the name" do
        policy.populate_with({ name: "SomeGroupCategory" }, populate_options)
        expect(category.name).to eq "SomeGroupCategory"
      end

      it "passes through group limit" do
        policy.populate_with({ group_limit: 3 }, populate_options)
        expect(category.group_limit).to eq 3
      end

      describe "when context is a course" do
        let(:context) { Course.new }

        it "populates group count" do
          policy.populate_with({ enable_self_signup: "1", create_group_count: 2 }, populate_options)
          expect(category.create_group_count).to eq 2
        end

        it "populates group member count" do
          policy.populate_with({ split_groups: "2", create_group_member_count: 5 }, populate_options)
          expect(category.create_group_member_count).to eq 5
        end
      end
    end
  end
end
