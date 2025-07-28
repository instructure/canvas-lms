# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Mutations::CreateGroupSet do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:admin) { account_admin_user(account: course.account) }
  let_once(:student) { student_in_course(active_all: true, course:).user }
  let_once(:second_student) { student_in_course(active_all: true, course:).user }

  def value_or_null(value)
    return "null" if value.nil?

    value.is_a?(String) ? "\"#{value}\"" : value
  end

  def mutation_str(
    context_id: course.id,
    context_type: :course,
    name: "Test Group Set",
    self_signup: false,
    non_collaborative: nil,
    create_group_count: nil,
    create_group_member_count: nil,
    group_by_section: nil,
    group_limit: nil,
    enable_auto_leader: nil,
    auto_leader_type: nil,
    enable_self_signup: nil,
    restrict_self_signup: nil,
    assign_async: nil,
    assign_unassigned_members: nil
  )
    <<~GQL
      mutation {
        createGroupSet(input: {
          contextId: #{value_or_null(context_id)}
          contextType: #{value_or_null(context_type)}
          name: #{value_or_null(name)}
          selfSignup: #{value_or_null(self_signup)}
          nonCollaborative: #{value_or_null(non_collaborative)}
          createGroupCount: #{value_or_null(create_group_count)}
          createGroupMemberCount: #{value_or_null(create_group_member_count)}
          groupBySection: #{value_or_null(group_by_section)}
          groupLimit: #{value_or_null(group_limit)}
          enableAutoLeader: #{value_or_null(enable_auto_leader)}
          autoLeaderType: #{value_or_null(auto_leader_type)}
          enableSelfSignup: #{value_or_null(enable_self_signup)}
          restrictSelfSignup: #{value_or_null(restrict_self_signup)}
          assignAsync: #{value_or_null(assign_async)}
          assignUnassignedMembers: #{value_or_null(assign_unassigned_members)}
        }) {
          groupSet {
            _id
            id
            name
            selfSignup
            autoLeader
            memberLimit
            nonCollaborative
            groups {
              id
              name
              membersCount
            }
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "allows users to create group sets" do
    result = run_mutation
    expect(result[:data][:createGroupSet][:groupSet]).to include(
      "name" => "Test Group Set",
      "selfSignup" => "disabled"
    )
  end

  it "allows users to create group sets with a max number of members per group" do
    result = run_mutation(create_group_count: 3, group_limit: 20)
    expect(result[:data][:createGroupSet][:groupSet]).to include(
      "name" => "Test Group Set",
      "memberLimit" => 20
    )
  end

  it "must be a valid context type" do
    result = run_mutation(context_type: "Not a context")
    expect(result[:errors].first[:message]).to include("Argument 'contextType' on InputObject 'CreateGroupSetInput' has an invalid value")
  end

  it "errors if the group name is a duplicate" do
    run_mutation(name: "Group Set")
    result = run_mutation(name: "Group Set")
    expect(result[:errors].first[:message]).to eq("Unable to create group set")
  end

  it "respects the max new-category group count" do
    Setting.set("max_groups_in_new_category", "3")
    result = run_mutation(create_group_count: 4)
    expect(result[:data][:createGroupSet][:groupSet][:groups].count).to eq(3)
  end

  context "permissions" do
    it "students cannot create group sets" do
      result = run_mutation({}, student)
      expect(result[:errors].first[:message]).to eq("Insufficient permissions to create group set")
    end

    it "teachers cannot create group sets in course they do not belong to" do
      other_course = course_factory(active_all: true)
      result = run_mutation(context_id: other_course.id, context_type: :course)
      expect(result[:errors].first[:message]).to eq("Insufficient permissions to create group set")
    end

    it "teachers cannot create group sets in account context" do
      result = run_mutation(context_id: course.account.id, context_type: :account)
      expect(result[:errors].first[:message]).to eq("Insufficient permissions to create group set")
    end

    it "admins can create group sets in account context" do
      result = run_mutation(
        {
          context_id: course.account.id,
          context_type: :account
        },
        admin
      )
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "selfSignup" => "disabled"
      )
    end
  end

  context "self signup" do
    it "respects restrict_self_signup" do
      result = run_mutation(self_signup: true, enable_self_signup: true, restrict_self_signup: true)
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "selfSignup" => "restricted"
      )
    end

    it "allows users to create group sets with self-signup enabled" do
      result = run_mutation(self_signup: true, enable_self_signup: true)
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "selfSignup" => "enabled"
      )
    end
  end

  context "auto leader" do
    it "allows users to create group sets with auto-leader enabled" do
      result = run_mutation(auto_leader_type: :first, enable_auto_leader: true)
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "autoLeader" => "first"
      )
    end

    it "allows 'random' auto-leater type" do
      result = run_mutation(auto_leader_type: :random, enable_auto_leader: true)
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "autoLeader" => "random"
      )
    end
  end

  context "creating groups in the group set" do
    it "allows groups to be created when creating a new group set" do
      result = run_mutation(create_group_count: 3)
      expect(result[:data][:createGroupSet][:groupSet][:groups].count).to eq(3)
    end

    it "allows for members to automatically be assigned to groups" do
      result = run_mutation(create_group_count: 2, create_group_member_count: 1)
      expect(result[:data][:createGroupSet][:groupSet][:groups].pluck(:membersCount)).to eq([1, 1])
    end

    it "does not automatically assign users to groups if 'self-signup' is enabled" do
      result = run_mutation(create_group_count: 3, self_signup: true, enable_self_signup: true, assign_unassigned_members: true)
      expect(result[:data][:createGroupSet][:groupSet][:groups].pluck(:membersCount)).to eq([0, 0, 0])
    end

    it "allows for members to be assigned asynchronously" do
      result = run_mutation(create_group_count: 3, assign_async: true)

      # The members count for each group will be 0 because the assignment is asynchronous
      expect(result[:data][:createGroupSet][:groupSet][:groups].pluck(:membersCount)).to eq([0, 0, 0])
    end

    it "allows for unassigned members to be assigned to groups" do
      result = run_mutation(create_group_count: 3, assign_unassigned_members: true)
      expect(result[:data][:createGroupSet][:groupSet][:groups].pluck(:membersCount)).to eq([1, 1, 0])
    end
  end

  context "non-collaborative groups" do
    before do
      Account.default.enable_feature! :assign_to_differentiation_tags
      Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
      Account.default.save!
      Account.default.reload
    end

    it "does not allow users to create non-collaborative groups if they do not have permission" do
      course.account.role_overrides.create!(
        permission: "manage_tags_add",
        role: teacher_role,
        enabled: false
      )

      result = run_mutation(non_collaborative: true)
      expect(result[:errors].first[:message]).to eq("Insufficient permissions to create group set")
    end

    it "allows users to create non-collaborative groups if they have permission" do
      result = run_mutation(non_collaborative: true)
      expect(result[:data][:createGroupSet][:groupSet]).to include(
        "name" => "Test Group Set",
        "nonCollaborative" => true
      )
    end
  end
end
