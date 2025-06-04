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

describe Loaders::UserLoaders::GroupMembershipsLoader do
  before do
    # Set up test data
    account = Account.create!
    @course1 = account.courses.create!(name: "Test Course 1")
    @course2 = account.courses.create!(name: "Test Course 2")

    # Create users
    @user1 = User.create!(name: "User 1")
    @user2 = User.create!(name: "User 2")
    @user3 = User.create!(name: "User 3")

    # Enroll users in courses
    @course1.enroll_student(@user1, enrollment_state: "active")
    @course1.enroll_student(@user2, enrollment_state: "active")
    @course1.enroll_student(@user3, enrollment_state: "active")
    @course2.enroll_student(@user1, enrollment_state: "active")

    # Create group categories
    @group_category1 = @course1.group_categories.create!(name: "Category 1")
    @group_category2 = @course1.group_categories.create!(name: "Category 2")
    @group_category3 = @course2.group_categories.create!(name: "Category 3")

    # Create groups
    @group1 = @course1.groups.create!(name: "Group 1", group_category: @group_category1)
    @group2 = @course1.groups.create!(name: "Group 2", group_category: @group_category1)
    @group3 = @course1.groups.create!(name: "Group 3", group_category: @group_category2)
    @group4 = @course2.groups.create!(name: "Group 4", group_category: @group_category3)

    # Create group memberships with different states
    @membership1 = @group1.add_user(@user1)
    @membership2 = @group2.add_user(@user2)
    @membership3 = @group3.add_user(@user1)
    @membership4 = @group4.add_user(@user1)

    # Set some groups to be inactive
    @group2.workflow_state = "deleted"
    @group2.save!
  end

  it "loads all group memberships for multiple users" do
    GraphQL::Batch.batch do
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for

      loader.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 3
        expect(memberships.map(&:group_id)).to include(@group1.id, @group3.id, @group4.id)
      end

      loader.load(@user2.id).then do |memberships|
        expect(memberships.length).to eq 1
        expect(memberships.first.group_id).to eq @group2.id
      end

      loader.load(@user3.id).then do |memberships|
        expect(memberships).to be_empty
      end
    end
  end

  it "filters memberships by state" do
    @membership4.workflow_state = "deleted"
    @membership4.save!
    GraphQL::Batch.batch do
      # Filter to only get accepted memberships
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for(filter: { state: "deleted" })

      loader.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 1
        expect(memberships.first.group_id).to eq @group4.id
        expect(memberships.first.workflow_state).to eq "deleted"
      end
    end
  end

  it "filters memberships by group state" do
    GraphQL::Batch.batch do
      # Filter to only get memberships in active groups
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for(filter: { group_state: "available" })

      loader.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 3
        expect(memberships.map(&:group_id)).to include(@group1.id, @group3.id, @group4.id)
      end

      loader.load(@user2.id).then do |memberships|
        expect(memberships).to be_empty # User2 is only in a deleted group
      end
    end
  end

  it "filters memberships by group course ID" do
    GraphQL::Batch.batch do
      # Filter to only get memberships in course1
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for(filter: { group_course_id: @course1.id })

      loader.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 2
        expect(memberships.map(&:group_id)).to include(@group1.id, @group3.id)
      end

      # Now filter for course2
      loader2 = Loaders::UserLoaders::GroupMembershipsLoader.for(filter: { group_course_id: @course2.id })

      loader2.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 1
        expect(memberships.first.group_id).to eq @group4.id
      end
    end
  end

  it "combines multiple filters" do
    # Change membership states to be different
    @membership1.workflow_state = "accepted"
    @membership1.save!
    @membership3.workflow_state = "accepted"
    @membership3.save!

    GraphQL::Batch.batch do
      # Filter by state AND course ID
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for(filter: {
                                                                  state: "accepted",
                                                                  group_course_id: @course1.id
                                                                })

      loader.load(@user1.id).then do |memberships|
        expect(memberships.length).to eq 2
        expect(memberships.map(&:group_id)).to include(@group1.id, @group3.id)
        memberships.each do |membership|
          expect(membership.workflow_state).to eq "accepted"
          expect(membership.group.context_id).to eq @course1.id
        end
      end
    end
  end

  it "returns empty array for non-existent users" do
    non_existent_user_id = 9999

    GraphQL::Batch.batch do
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for

      loader.load(non_existent_user_id).then do |memberships|
        expect(memberships).to be_empty
      end
    end
  end

  it "batches database queries efficiently" do
    query_count = 0
    counter = ActiveSupport::Notifications.subscribe("sql.active_record") do
      query_count += 1
    end

    GraphQL::Batch.batch do
      loader = Loaders::UserLoaders::GroupMembershipsLoader.for

      # Load for multiple users in the same batch
      loader.load(@user1.id)
      loader.load(@user2.id)
      loader.load(@user3.id)
    end

    # There should only be 1 query to fetch group memberships, plus any needed joins
    expect(query_count).to be <= 2

    ActiveSupport::Notifications.unsubscribe(counter)
  end
end
