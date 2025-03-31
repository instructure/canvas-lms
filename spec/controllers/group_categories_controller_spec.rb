# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe GroupCategoriesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @collaborative_category = @course.group_categories.create!(name: "Collaborative Groups", non_collaborative: false)
    @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Groups", non_collaborative: true)
  end

  def expect_imported_groups
    group_1 = Group.where(name: "group1").first
    expect(group_1).not_to be_nil
    expect(group_1.users.count).to eq 2
    expect(group_1.users).to include(Pseudonym.where(unique_id: "user1").first.user)
    expect(group_1.users).to include(Pseudonym.where(unique_id: "user2").first.user)

    group_2 = Group.where(name: "group2").first
    expect(group_2).not_to be_nil
    expect(group_2.users.count).to eq 2
    expect(group_2.users).to include(Pseudonym.where(unique_id: "user3").first.user)
    expect(group_2.users).to include(Pseudonym.where(unique_id: "user4").first.user)

    group_3 = Group.where(name: "group3").first
    expect(group_3).not_to be_nil
    expect(group_3.users.count).to eq 1
    expect(group_3.users).to include(Pseudonym.where(unique_id: "user5").first.user)
  end

  describe "POST create" do
    it "requires authorization" do
      user_session(@student)
      @group = @course.groups.create(name: "some groups")
      post "create", params: { course_id: @course.id, category: {} }
      assert_unauthorized
      post "create", params: {
        course_id: @course.id,
        category: {
          name: "New Non-Collaborative Group",
          non_collaborative: "1"
        }
      }
      assert_unauthorized
    end

    it "requires teacher default enabled :manage_groups_add" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "My Category" } }
      expect(response).to be_successful
    end

    it "allows teachers to create both types of group categories by default" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      user_session(@teacher)

      # Can create collaborative
      post "create", params: {
        course_id: @course.id,
        category: {
          name: "New Collaborative Group",
        }
      }
      expect(response).to be_successful
      expect(assigns[:group_category].non_collaborative?).to be false

      # Can create non-collaborative
      post "create", params: {
        course_id: @course.id,
        category: {
          name: "New Non-Collaborative Group",
          non_collaborative: "1"
        }
      }
      expect(response).to be_successful
      expect(assigns[:group_category]).to be_non_collaborative
    end

    it "prevents creating non-collaborative groups when manage_tags_add permission is revoked" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      # Explicitly remove the permission
      @course.account.role_overrides.create!(
        permission: :manage_tags_add,
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)

      post "create", params: {
        course_id: @course.id,
        category: {
          name: "New Non-Collaborative Group",
          non_collaborative: "1"
        }
      }
      assert_unauthorized

      # Verify that normal group category permission isn't affected
      post "create", params: {
        course_id: @course.id,
        category: {
          name: "New Collaborative Group",
        }
      }
      expect(response).to be_successful
    end

    it "is not authorized without :manage_groups_add enabled" do
      @course.root_account.role_overrides.create!(
        permission: "manage_groups_add",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "My Category" } }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@teacher)
      @group = @course.groups.create(name: "some groups")
      create_users_in_course(@course, 5) # plus one student in before block
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", split_group_count: 2, split_groups: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      groups = assigns[:group_category].groups
      expect(groups.length).to be(2)
      expect(groups[0].users.length).to be(3)
      expect(groups[1].users.length).to be(3)
    end

    it "gives the new groups the right group_category" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", split_group_count: 1, split_groups: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].groups[0].group_category.name).to eq "Study Groups"
    end

    it "errors if the group name is protected" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Student Groups" } }
      expect(response).not_to be_successful
    end

    it "errors if the group name is already in use" do
      user_session(@teacher)
      @course.group_categories.create(name: "My Category")
      post "create", params: { course_id: @course.id, category: { name: "My Category" } }
      expect(response).not_to be_successful
    end

    it "requires the group name" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: {} }
      expect(response).not_to be_successful
    end

    it "respects enable_self_signup" do
      @course.account.enable_feature!(:self_signup_deadline)
      user_session(@teacher)
      end_date = Time.now.utc
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1", self_signup_end_at: end_date } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category]).to be_self_signup
      expect(assigns[:group_category]).to be_unrestricted_self_signup
      expect(assigns[:group_category].self_signup_end_at).to be_within(1.second).of(end_date)
    end

    it "uses create_group_count when self-signup" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1", create_group_count: "3" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].groups.size).to eq 3
    end

    it "respects auto_leader params" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_auto_leader: "1", auto_leader_type: "RANDOM" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category].auto_leader).to eq "random"
    end

    it "respects the max new-category group count" do
      user_session(@teacher)
      Setting.set("max_groups_in_new_category", "5")
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1", create_group_count: "7" } }
      expect(response).to be_successful
      expect(assigns[:group_category].groups.size).to eq 5
    end

    it "does not distribute students when self-signup" do
      user_session(@teacher)
      create_users_in_course(@course, 3)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1", create_category_count: "2" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      assigns[:group_category].groups.all? { |g| expect(g.users).to be_empty }
    end

    it "respects restrict_self_signup" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1", restrict_self_signup: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category]).to be_restricted_self_signup
    end

    context "differentiation_tags" do
      before do
        @course.account.enable_feature! :assign_to_differentiation_tags
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!
        @course.account.reload
      end

      it "allows teachers with :manage_tags_add to create non_collaborative groups" do
        @course.account.role_overrides.create!({
                                                 role: teacher_role,
                                                 permission: :manage_tags_add,
                                                 enabled: true
                                               })
        user_session(@teacher)

        post "create", params: { course_id: @course.id, category: { name: "Hidden GC", non_collaborative: true } }
        expect(response).to be_successful
        expect(assigns[:group_category]).to be_non_collaborative
      end
    end
  end

  describe "PUT update" do
    before :once do
      @group_category = @course.group_categories.create(name: "My Category")
    end

    it "requires authorization" do
      put "update", params: { course_id: @course.id, id: @group_category.id, category: {} }
      assert_unauthorized
    end

    it "allows teachers to update both types of group categories by default" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      user_session(@teacher)

      # Can update collaborative
      put "update", params: {
        course_id: @course.id,
        id: @collaborative_category.id,
        category: { name: "Updated Collaborative Group" }
      }
      expect(response).to be_successful
      expect(@collaborative_category.reload.name).to eq "Updated Collaborative Group"

      # Can update non-collaborative
      put "update", params: {
        course_id: @course.id,
        id: @non_collaborative_category.id,
        category: { name: "Updated Non-Collaborative Group" }
      }
      expect(response).to be_successful
      expect(@non_collaborative_category.reload.name).to eq "Updated Non-Collaborative Group"
    end

    it "prevents updating non-collaborative groups when manage_tags_manage permission is revoked" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      @course.account.role_overrides.create!(
        permission: :manage_tags_manage,
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)

      put "update", params: {
        course_id: @course.id,
        id: @non_collaborative_category.id,
        category: { name: "Updated Non-Collaborative Group" }
      }
      assert_unauthorized

      # Can still update collaborative
      put "update", params: {
        course_id: @course.id,
        id: @collaborative_category.id,
        category: { name: "Updated Collaborative Group" }
      }
      expect(response).to be_successful
    end

    it "updates category" do
      @course.account.enable_feature!(:self_signup_deadline)
      user_session(@teacher)
      end_date = Time.now.utc
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "1", self_signup_end_at: end_date } }
      expect(response).to be_successful
      expect(assigns[:group_category]).to eql(@group_category)
      expect(assigns[:group_category].name).to eql("Different Category")
      expect(assigns[:group_category]).to be_self_signup
      expect(assigns[:group_category].self_signup_end_at).to be_within(1.second).of(end_date)
    end

    it "does not update category if :manage_groups_manage is not enabled" do
      @course.account.role_overrides.create!(
        permission: "manage_groups_manage",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "1" } }
      assert_unauthorized
    end

    it "leaves the name alone if not given" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: {} }
      expect(response).to be_successful
      expect(assigns[:group_category].name).to eq "My Category"
    end

    it "does not accept a sent but empty name" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "" } }
      expect(response).not_to be_successful
    end

    it "errors if the name is protected" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Student Groups" } }
      expect(response).not_to be_successful
    end

    it "errors if the name is already in use" do
      user_session(@teacher)
      @course.group_categories.create(name: "Other Category")
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Other Category" } }
      expect(response).not_to be_successful
    end

    it "does not error if the name is the current name" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "My Category" } }
      expect(response).to be_successful
      expect(assigns[:group_category].name).to eql("My Category")
    end

    it "errors if restrict_self_signups is specified but the category has heterogenous groups" do
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, "StudentEnrollment").user
      user2 = section2.enroll_user(user_model, "StudentEnrollment").user
      group = @group_category.groups.create(context: @course)
      group.add_user(user1)
      group.add_user(user2)

      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { enable_self_signup: "1", restrict_self_signup: "1" } }
      expect(response).not_to be_successful
    end

    it "clears self_signup_end_at if self_signup is disabled" do
      @course.account.enable_feature!(:self_signup_deadline)
      user_session(@teacher)
      end_date = Time.now.utc
      @group_category.self_signup_end_at = end_date
      @group_category.save!
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "0", self_signup_end_at: end_date } }
      expect(response).to be_successful
      expect(assigns[:group_category].self_signup_end_at).to be_nil
    end

    it "does not set self_signup_end_at if self_signup_deadline FF is disabled" do
      user_session(@teacher)
      end_date = Time.now.utc
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "1", self_signup_end_at: end_date } }
      expect(response).to be_successful
      expect(assigns[:group_category]).to be_self_signup
      expect(assigns[:group_category].self_signup_end_at).to be_nil
    end
  end

  describe "POST bulk_manage_differentiation_tag" do
    before :once do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Category", non_collaborative: true)
      @collaborative_category = @course.group_categories.create!(name: "Collaborative Category", non_collaborative: false)
    end

    context "authorization checks" do
      it "requires add permission to create differentiation tag" do
        user_session(@teacher)
        # Revoke add permission for differentiation tags (non_collaborative)
        @course.account.role_overrides.create!(
          permission: :manage_tags_add,
          role: teacher_role,
          enabled: false
        )

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 create: [{ name: "New Group" }]
               }
             }
        assert_unauthorized
      end

      it "requires manage permission to update differentiation tag" do
        user_session(@teacher)
        # Revoke manage permission
        @course.account.role_overrides.create!(
          permission: :manage_tags_manage,
          role: teacher_role,
          enabled: false
        )

        test_group = @non_collaborative_category.groups.create!(name: "Old Group", context: @course)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 update: [{ id: test_group.id, name: "Updated Group" }]
               }
             }
        assert_unauthorized
      end

      it "requires delete permission to delete differentiation tag" do
        user_session(@teacher)
        # Revoke delete permission
        @course.account.role_overrides.create!(
          permission: :manage_tags_delete,
          role: teacher_role,
          enabled: false
        )

        test_group = @non_collaborative_category.groups.create!(name: "To Be Deleted", context: @course)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 delete: [{ id: test_group.id }]
               }
             }
        assert_unauthorized
      end
    end

    context "with proper permissions" do
      before do
        user_session(@teacher)
        # Assume teacher has all relevant group permissions (manage_tags_add, manage_tags_manage, manage_tags_delete)
      end

      it "creates multiple groups" do
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 create: [
                   { name: "Group A" },
                   { name: "Group B" },
                   { name: "Group C" }
                 ]
               }
             }
        expect(response).to be_successful
        body = response.parsed_body
        expect(body["created"].size).to eq 3
      end

      it "updates groups" do
        group = @non_collaborative_category.groups.create!(name: "Original Name", context: @course)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 update: [{ id: group.id, name: "Updated Name" }]
               }
             }

        expect(response).to be_successful
        body = response.parsed_body
        expect(body["updated"].size).to eq 1
        expect(group.reload.name).to eq "Updated Name"
      end

      it "deletes groups" do
        group = @non_collaborative_category.groups.create!(name: "Delete Me", context: @course)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 delete: [{ id: group.id }]
               }
             }

        expect(response).to be_successful
        body = response.parsed_body
        expect(body["deleted"].size).to eq 1
        expect(@non_collaborative_category.groups.active.map(&:name)).not_to include("Delete Me")
      end

      it "handles create, update, and delete in one request" do
        group1 = @non_collaborative_category.groups.create!(name: "Group1", context: @course)
        group2 = @non_collaborative_category.groups.create!(name: "Group2", context: @course)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 create: [{ name: "New Group" }],
                 update: [{ id: group1.id, name: "Updated Group1" }],
                 delete: [{ id: group2.id }]
               }
             }

        expect(response).to be_successful
        body = response.parsed_body
        expect(body["created"].size).to eq 1
        expect(body["updated"].size).to eq 1
        expect(body["deleted"].size).to eq 1
        expect(@non_collaborative_category.groups.active.map(&:name)).to include("Updated Group1", "New Group")
        expect(@non_collaborative_category.groups.active.map(&:name)).not_to include("Group2")
      end

      it "updates group category name if both id and new name provided" do
        new_name = "Updated Non-Collaborative Category"
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id, name: new_name },
               operations: {
                 create: [{ name: "New Group" }]
               }
             }
        expect(response).to be_successful
        body = response.parsed_body

        expect(body["group_category"]["group_category"]["name"]).to eq new_name
        expect(@non_collaborative_category.reload.name).to eq new_name
      end

      it "creates a new GroupCategory and new Groups at the same time" do
        new_category_name = "New Differentiation Category"
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { name: new_category_name },
               operations: {
                 create: [
                   { name: "Group X" },
                   { name: "Group Y" }
                 ]
               }
             }
        expect(response).to be_successful

        new_category = @course.differentiation_tag_categories.find_by(name: new_category_name)
        expect(new_category).not_to be_nil
        expect(new_category.groups.active.pluck(:name)).to match_array(["Group X", "Group Y"])
      end
    end

    context "with invalid group_category non_collaborative" do
      it "fails when a non-differentiation (collaborative) category id is provided" do
        user_session(@teacher)
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @collaborative_category.id },
               operations: {
                 create: [{ name: "New Group" }]
               }
             }
        expect(response).to have_http_status(:bad_request)
        body = response.parsed_body
        expect(body["errors"]).to eq I18n.t("This endpoint only works for Differentiation Tags")
      end
    end

    context "error conditions" do
      it "fails if a group to update doesn't exist" do
        user_session(@teacher)
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 update: [{ id: 9999, name: "Nonexistent" }]
               }
             }
        expect(response).to have_http_status(:not_found)
      end

      it "fails if a group to delete doesn't exist" do
        user_session(@teacher)
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 delete: [{ id: 9999 }]
               }
             }
        expect(response).to have_http_status(:not_found)
      end

      it "fails if create params are invalid" do
        user_session(@teacher)
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 create: [{ name: "" }]
               }
             }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to be_present
      end

      it "fails when the maximum number of operations is exceeded" do
        user_session(@teacher)
        post "bulk_manage_differentiation_tag",
             params: {
               course_id: @course.id,
               group_category: { id: @non_collaborative_category.id },
               operations: {
                 create: [{ name: "Group" }] * (50 + 1)
               }
             }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to match(/You can only perform a maximum of 50 operations at a time./io)
      end

      it "fails if the GroupCategory id is not part of the given course even if the teacher has permissions" do
        user_session(@teacher)
        course1 = @course
        course2 = course_with_teacher(active_all: true, user: @teacher).course
        other_category = course2.group_categories.create!(name: "Other Category", non_collaborative: true)

        post "bulk_manage_differentiation_tag",
             params: {
               course_id: course1.id,
               group_category: { id: other_category.id },
               operations: {
                 create: [{ name: "Invalid Group" }]
               }
             }
        expect(response).to have_http_status(:bad_request)
        body = response.parsed_body
        expect(body["errors"]).to match(/not part of the course/i)
      end
    end
  end

  describe "DELETE delete" do
    it "requires authorization" do
      group_category = @course.group_categories.create(name: "Study Groups")
      delete "destroy", params: { course_id: @course.id, id: group_category.id }
      assert_unauthorized
    end

    it "deletes the category and groups" do
      user_session(@teacher)
      category1 = @course.group_categories.create(name: "Study Groups")
      category2 = @course.group_categories.create(name: "Other Groups")
      group1 = @course.groups.create(name: "some group", group_category: category1)
      group2 = @course.groups.create(name: "another group", group_category: category2)

      delete "destroy", params: { course_id: @course.id, id: category1.id }
      expect(response).to be_successful

      @course.reload

      expected_all_group_category_ids = [
        @collaborative_category.id,
        category1.id,
        category2.id
      ]

      expected_group_category_ids = [
        @collaborative_category.id,
        category2.id
      ]

      expected_group_ids = [
        group1.id,
        group2.id
      ]

      expected_active_group_ids = [
        group2.id
      ]

      actual_all_group_category_ids = @course.all_group_categories.pluck(:id)
      expect(actual_all_group_category_ids).to match_array(expected_all_group_category_ids)

      actual_group_category_ids = @course.group_categories.pluck(:id)
      expect(actual_group_category_ids).to match_array(expected_group_category_ids)

      actual_group_ids = @course.groups.pluck(:id)
      expect(actual_group_ids).to match_array(expected_group_ids)

      actual_active_group_ids = @course.groups.active.pluck(:id)
      expect(actual_active_group_ids).to match_array(expected_active_group_ids)
    end

    it "allows teachers to delete both types of group categories by default" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      user_session(@teacher)

      # Can delete collaborative
      category1 = @course.group_categories.create(name: "Study Groups")
      delete "destroy", params: {
        course_id: @course.id,
        id: category1.id
      }
      expect(response).to be_successful

      # Can delete non-collaborative
      non_collab = @course.group_categories.create!(name: "Another Non-Collab", non_collaborative: true)
      delete "destroy", params: {
        course_id: @course.id,
        id: non_collab.id
      }
      expect(response).to be_successful
    end

    it "prevents deleting non-collaborative groups when manage_tags_delete permission is revoked" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      @course.account.role_overrides.create!(
        permission: :manage_tags_delete,
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)

      delete "destroy", params: {
        course_id: @course.id,
        id: @non_collaborative_category.id
      }
      assert_unauthorized

      # Can Still delete collaborative group category
      delete "destroy", params: {
        course_id: @course.id,
        id: @collaborative_category.id
      }
      expect(response).to be_successful
    end

    it "does not delete the category/groups if :manage_groups_delete is not enabled" do
      @course.account.role_overrides.create!(
        permission: "manage_groups_delete",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      category1 = @course.group_categories.create(name: "Study Groups")
      category2 = @course.group_categories.create(name: "Other Groups")
      @course.groups.create(name: "some group", group_category: category1)
      @course.groups.create(name: "another group", group_category: category2)
      delete "destroy", params: { course_id: @course.id, id: category1.id }
      assert_unauthorized
    end

    it "fails if category doesn't exist" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: 11_235 }
      expect(response).not_to be_successful
    end

    it "fails if category is protected" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: GroupCategory.student_organized_for(@course).id }
      expect(response).not_to be_successful
    end
  end

  describe "GET users" do
    before do
      @category = @course.group_categories.create(name: "Study Groups")
      group = @course.groups.create(name: "some group", group_category: @category)
      group.add_user(@student)

      assignment = @course.assignments.create({
                                                name: "test assignment",
                                                group_category: @category
                                              })
      file = Attachment.create! context: @student, filename: "homework.pdf", uploaded_data: StringIO.new("blah blah blah")
      @sub = assignment.submit_homework(@student, attachments: [file], submission_type: "online_upload")
    end

    it "allows teachers to view users in both types of group categories by default" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      user_session(@teacher)

      # Can view collaborative
      get "users", params: {
        course_id: @course.id,
        group_category_id: @collaborative_category.id
      }
      expect(response).to be_successful

      # Can view non-collaborative
      get "users", params: {
        course_id: @course.id,
        group_category_id: @non_collaborative_category.id
      }
      expect(response).to be_successful
    end

    it "prevents viewing non-collaborative group users when manage_tags_manage permission is revoked" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload

      @course.account.role_overrides.create!(
        permission: :manage_tags_manage,
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)

      get "users", params: {
        course_id: @course.id,
        group_category_id: @non_collaborative_category.id
      }
      assert_unauthorized

      # Can still view collaborative group category users
      get "users", params: {
        course_id: @course.id,
        group_category_id: @collaborative_category.id
      }
      expect(response).to be_successful
    end

    it "includes group submissions if param is present" do
      user_session(@teacher)
      get "users", params: { course_id: @course.id, group_category_id: @category.id, include: ["group_submissions"] }
      json = response.parsed_body

      expect(response).to be_successful
      expect(json.count).to equal 1
      expect(json[0]["group_submissions"][0]).to equal @sub.id
    end

    it "does not include group submissions if param is absent" do
      user_session(@teacher)
      get "users", params: { course_id: @course.id, group_category_id: @category.id }
      json = response.parsed_body

      expect(response).to be_successful
      expect(json.count).to equal 1
      expect(json[0]["group_submissions"]).to equal nil
    end
  end

  describe "POST import" do
    before :once do
      1.upto(5) do |n|
        @course.enroll_user(user_with_pseudonym(username: "user#{n}"), "StudentEnrollment", enrollment_state: "active")
      end
      @category = @course.group_categories.create(name: "Group Category")
    end

    it "requires authorization" do
      post "import", params: {
        course_id: @course.id,
        group_category_id: @category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      assert_unauthorized
    end

    it "allows teachers to import to both types of group categories by default" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      user_session(@teacher)

      # Can import to collaborative
      post "import", params: {
        course_id: @course.id,
        group_category_id: @collaborative_category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful

      # Can import to non-collaborative
      post "import", params: {
        course_id: @course.id,
        group_category_id: @non_collaborative_category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful
    end

    it "prevents importing to non-collaborative groups when manage_tags_add permission is revoked" do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      @course.account.role_overrides.create!(
        permission: :manage_tags_add,
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)

      post "import", params: {
        course_id: @course.id,
        group_category_id: @non_collaborative_category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      assert_unauthorized

      # Can still import to collaborative group category
      post "import", params: {
        course_id: @course.id,
        group_category_id: @collaborative_category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful
    end

    it "initiates import" do
      user_session(@teacher)
      post "import", params: {
        course_id: @course.id,
        group_category_id: @category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful
      json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
      expect(json["context_type"]).to eq "GroupCategory"
      expect(json["tag"]).to eq "course_group_import"
      expect(json["completion"]).to eq 0
    end

    it "does not initiate import if :manage_groups_add is not enabled" do
      @course.account.role_overrides.create!(
        permission: "manage_groups_add",
        role: teacher_role,
        enabled: false
      )
      user_session(@teacher)
      post "import", params: {
        course_id: @course.id,
        group_category_id: @category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      assert_unauthorized
    end

    it "creates the groups and add users as specified in the csv" do
      user_session(@teacher)
      post "import", params: {
        course_id: @course.id,
        group_category_id: @category.id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful

      run_jobs

      expect_imported_groups
    end

    it "creates the groups for a student organized group" do
      user_session(@teacher)
      post "import", params: {
        course_id: @course.id,
        group_category_id: GroupCategory.student_organized_for(@course).id,
        attachment: fixture_file_upload("group_categories/test_group_categories.csv", "text/csv")
      }
      expect(response).to be_successful

      run_jobs

      expect_imported_groups
    end
  end

  describe "GET index" do
    it "returns only collaborative group categories when differentiation tag FF is off" do
      user_session(@teacher)

      get "index", params: { course_id: @course.id }, format: :json
      json = response.parsed_body

      expect(response).to be_successful
      expect(json.count).to eq 1
      expect(json.pluck("name")).to include("Collaborative Groups")
    end

    it "returns an empty array when no data exists" do
      course_with_teacher(active_all: true)

      user_session(@teacher)

      get "index", params: { course_id: @course.id }, format: :json
      json = response.parsed_body

      expect(response).to be_successful
      expect(json.count).to eq 0
    end

    it "returns unauthorized when user has no permissions" do
      user_session(@student)

      get "index", params: { course_id: @course.id }, format: :json
      assert_forbidden
    end

    it "does not double render" do
      user_session(@student)

      expect(controller).to receive(:render).once.and_call_original
      get :index, params: { course_id: @course.id }, format: :json
      assert_forbidden
    end
  end

  context "Differentiation Tags" do
    before do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      # Assuming @course, @teacher_role, @teacher, @non_collaborative_category, etc., are already set up
    end

    describe "GET #index with collaboration_state" do
      context "when user has both group and tag management permissions" do
        before do
          user_session(@teacher)
        end

        it "fails when invalid Collaborative state is sent" do
          get "index", params: { course_id: @course.id, collaboration_state: "gibberish" }, format: :json
          json = response.parsed_body
          expect(response).to have_http_status(:bad_request)
          expect(json["error"]).to include("Invalid collaboration_state")
        end

        it "defaults to collaborative collaboration_state when send empty string" do
          get "index", params: { course_id: @course.id, collaboration_state: "" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.pluck("name")).to include("Collaborative Groups")
        end

        it "returns both collaborative and non-collaborative group categories when collaboration_state is 'all'" do
          get "index", params: { course_id: @course.id, collaboration_state: "all" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 2
          expect(json.pluck("name")).to include("Collaborative Groups", "Non-Collaborative Groups")
        end

        it "returns only collaborative group categories when collaboration_state is 'collaborative'" do
          get "index", params: { course_id: @course.id, collaboration_state: "collaborative" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Collaborative Groups"
        end

        it "returns only non-collaborative group categories when collaboration_state is 'non_collaborative'" do
          get "index", params: { course_id: @course.id, collaboration_state: "non_collaborative" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Non-Collaborative Groups"
        end

        it "returns only collaborative group categories by default when collaboration_state is not provided" do
          get "index", params: { course_id: @course.id }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Collaborative Groups"
        end
      end

      context "when tag management permissions are revoked" do
        before do
          # Revoke all tag management permissions
          RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
            @course.account.role_overrides.create!(
              permission:,
              role: teacher_role,
              enabled: false
            )
          end

          user_session(@teacher)
        end

        it "returns only collaborative group categories when collaboration_state is 'all' but lacks tag permissions" do
          get "index", params: { course_id: @course.id, collaboration_state: "all" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Collaborative Groups"
        end

        it "returns only collaborative group categories when collaboration_state is 'collaborative'" do
          get "index", params: { course_id: @course.id, collaboration_state: "collaborative" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Collaborative Groups"
        end

        it "returns forbidden when trying to access non-collaborative group categories without permissions" do
          get "index", params: { course_id: @course.id, collaboration_state: "non_collaborative" }, format: :json
          response.parsed_body
          expect(response).to be_forbidden
        end
      end

      context "when group management permissions are revoked" do
        before do
          # Revoke all group management permissions
          RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS.each do |permission|
            @course.account.role_overrides.create!(
              permission:,
              role: teacher_role,
              enabled: false
            )
          end

          user_session(@teacher)
        end

        it "returns only non-collaborative group categories when collaboration_state is 'all' but lacks group permissions" do
          get "index", params: { course_id: @course.id, collaboration_state: "all" }, format: :json
          json = response.parsed_body

          # Since the user lacks group permissions, 'all' should only return non-collaborative categories
          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Non-Collaborative Groups"
        end

        it "returns only non-collaborative group categories when collaboration_state is 'non_collaborative'" do
          get "index", params: { course_id: @course.id, collaboration_state: "non_collaborative" }, format: :json
          json = response.parsed_body

          expect(response).to be_successful
          expect(json.count).to eq 1
          expect(json.first["name"]).to eq "Non-Collaborative Groups"
        end

        it "returns forbidden when trying to access collaborative group categories without permissions" do
          user_session(@student)
          get "index", params: { course_id: @course.id, collaboration_state: "collaborative" }, format: :json
          response.parsed_body

          expect(response).to be_forbidden
        end
      end

      context "with differentiation tags disabled with existing hidden groups" do
        before do
          @course.account.disable_feature! :assign_to_differentiation_tags
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
          @course.account.save!
          @course.account.reload
        end

        it "prevents teachers from creating non_collaborative groups if differentiation_tags is disabled" do
          @course.account.role_overrides.create!({
                                                   role: teacher_role,
                                                   permission: :manage_tags_add,
                                                   enabled: true
                                                 })
          user_session(@teacher)

          post "create", params: { course_id: @course.id, category: { name: "Hidden GC", non_collaborative: true } }

          expect(response).to be_unauthorized
        end

        it "does not allow viewing non-collaborative group category" do
          user_session(@teacher)
          get "users", params: {
            course_id: @course.id,
            group_category_id: @non_collaborative_category.id
          }
          assert_unauthorized
        end

        it "does not allow adding non-collaborative group category" do
          user_session(@teacher)
          post "create", params: {
            course_id: @course.id,
            category: {
              name: "New Non-Collaborative Group",
              non_collaborative: "1"
            }
          }
          assert_unauthorized
        end

        it "does not allow updating non-collaborative group category" do
          user_session(@teacher)
          put "update", params: { course_id: @course.id, id: @non_collaborative_category.id, category: { name: "Updated Non-Collaborative Group" } }
          assert_unauthorized
        end

        it "does not allow deleting non-collaborative group category" do
          user_session(@teacher)
          delete "destroy", params: { course_id: @course.id, id: @non_collaborative_category.id }
          assert_unauthorized
        end
      end
    end
  end
end
