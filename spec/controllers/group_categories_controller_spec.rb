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
  end

  describe "POST create" do
    it "requires authorization" do
      user_session(@student)
      @group = @course.groups.create(name: "some groups")
      post "create", params: { course_id: @course.id, category: {} }
      assert_unauthorized
    end

    it "requires teacher default enabled :manage_groups_add (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "My Category" } }
      expect(response).to be_successful
    end

    it "is not authorized without :manage_groups_add enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
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
      user_session(@teacher)
      post "create", params: { course_id: @course.id, category: { name: "Study Groups", enable_self_signup: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).not_to be_nil
      expect(assigns[:group_category]).to be_self_signup
      expect(assigns[:group_category]).to be_unrestricted_self_signup
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
  end

  describe "PUT update" do
    before :once do
      @group_category = @course.group_categories.create(name: "My Category")
    end

    it "requires authorization" do
      put "update", params: { course_id: @course.id, id: @group_category.id, category: {} }
      assert_unauthorized
    end

    it "updates category" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).to eql(@group_category)
      expect(assigns[:group_category].name).to eql("Different Category")
      expect(assigns[:group_category]).to be_self_signup
    end

    it "updates category (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @group_category.id, category: { name: "Different Category", enable_self_signup: "1" } }
      expect(response).to be_successful
      expect(assigns[:group_category]).to eql(@group_category)
      expect(assigns[:group_category].name).to eql("Different Category")
      expect(assigns[:group_category]).to be_self_signup
    end

    it "does not update category if :manage_groups_manage is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
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
      @course.groups.create(name: "some group", group_category: category1)
      @course.groups.create(name: "another group", group_category: category2)
      delete "destroy", params: { course_id: @course.id, id: category1.id }
      expect(response).to be_successful
      @course.reload
      expect(@course.all_group_categories.length).to be(2)
      expect(@course.group_categories.length).to be(1)
      expect(@course.groups.length).to be(2)
      expect(@course.groups.active.length).to be(1)
    end

    it "deletes the category and groups (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
      user_session(@teacher)
      category1 = @course.group_categories.create(name: "Study Groups")
      category2 = @course.group_categories.create(name: "Other Groups")
      @course.groups.create(name: "some group", group_category: category1)
      @course.groups.create(name: "another group", group_category: category2)
      delete "destroy", params: { course_id: @course.id, id: category1.id }
      expect(response).to be_successful
      @course.reload
      expect(@course.all_group_categories.length).to be(2)
      expect(@course.group_categories.length).to be(1)
      expect(@course.groups.length).to be(2)
      expect(@course.groups.active.length).to be(1)
    end

    it "does not delete the category/groups if :manage_groups_delete is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
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

    it "renders progress_json" do
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

    it "initiates import (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
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

    it "does not initiate import if :manage_groups_add is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_groups)
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
  end
end
