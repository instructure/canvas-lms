# frozen_string_literal: true

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

require_relative "../graphql_spec_helper"

describe Mutations::CreateGroupInSet do
  before(:once) do
    student_in_course(active_all: true)
    @gc = @course.group_categories.create! name: "asdf"
  end

  def mutation_str(name: "zxcv", group_set_id: nil, non_collaborative: false)
    group_set_id ||= @gc.id
    <<~GQL
      mutation {
        createGroupInSet(input: {
          name: "#{name}"
          groupSetId: "#{group_set_id}"
          nonCollaborative: #{non_collaborative}
        }) {
          group {
            _id
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  it "works" do
    result = CanvasSchema.execute(mutation_str, context: { current_user: @teacher })

    new_group_id = result.dig(*%w[data createGroupInSet group _id])
    expect(Group.find(new_group_id).name).to eq "zxcv"

    expect(result.dig(*%w[data createGroupInSet errors])).to be_nil
  end

  it "fails gracefully for invalid group sets" do
    invalid_group_set_id = 111_111_111_111_111_111
    result = CanvasSchema.execute(mutation_str(group_set_id: invalid_group_set_id), context: { current_user: @student })
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createGroupInSet])).to be_nil
  end

  it "requires permission" do
    result = CanvasSchema.execute(mutation_str, context: { current_user: @student })
    expect(result["errors"]).not_to be_nil
    expect(result.dig(*%w[data createGroupInSet])).to be_nil
  end

  context "validation errors" do
    it "returns validation errors" do
      result = CanvasSchema.execute(
        mutation_str(name: "!" * (Group.maximum_string_length + 1)),
        context: { current_user: @teacher }
      )

      # top-level errors are nil since this is a user error
      expect(result["errors"]).to be_nil

      validation_errors = result.dig(*%w[data createGroupInSet errors])
      expect(validation_errors.size).to eq 1
      expect(validation_errors[0]["attribute"]).to eq "name"
      expect(validation_errors[0]["message"]).to_not be_nil

      expect(result.dig("data", "createGroupInSet", "group")).to be_nil
    end
  end

  context "non_collaborative groups" do
    before do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      @gc_non_colab = @course.group_categories.create! name: "non collaborative group category", non_collaborative: true
    end

    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createGroupInSet", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    def group_id(result)
      result.dig("data", "createGroupInSet", "group", "_id")
    end

    def run_mutation(name: "non collaborative group", group_set_id: @gc_non_colab.id, non_collaborative: true, current_user: @teacher)
      CanvasSchema.execute(mutation_str(name:, group_set_id:, non_collaborative:), context: { current_user: })
    end

    it "creates non-collaborative group" do
      result = run_mutation
      expect(Group.find(group_id(result)).name).to eq "non collaborative group"
      expect(result.dig("data", "createGroupInSet", "errors")).to be_nil
    end

    context "permissions" do
      it "returns error when user does not have manage_tags_add permission" do
        @course.account.role_overrides.create!(permission: :manage_tags_add, role: teacher_role, enabled: false)
        result = run_mutation
        expect_error(result, "insufficient permissions to create non-collaborative groups")
      end
    end

    context "validation errors" do
      it "returns error if collaborative group and non-collaborative group set" do
        result = run_mutation(non_collaborative: false)
        expect(group_id(result)).to be_nil
        expect_error(result, "cannot create collaborative groups in a non-collaborative group set")
      end

      it "returns error if non-collaborative group and collaborative group set" do
        result = run_mutation(group_set_id: @gc.id)
        expect(group_id(result)).to be_nil
        expect_error(result, "Group non_collaborative status must match its category")
      end

      it "returns error if the differentiation tags FF is disabled" do
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
        @course.account.save!
        @course.account.reload
        result = run_mutation
        expect(group_id(result)).to be_nil
        expect_error(result, "cannot create non-collaborative groups when the differentiation tags feature flag is disabled")
      end
    end
  end
end
