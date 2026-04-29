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

describe Loaders::UserLoaders::DifferentiationTagsLoader do
  before do
    @account = Account.create!
    @other_course = course_factory(account: @account, name: "Other Course")
    @course = course_factory(account: @account, name: "Test Course")

    @user1 = user_factory(name: "User 1")
    @user2 = user_factory(name: "User 2")
    @user3 = user_factory(name: "User 3")
    @current_user = user_factory(name: "Current User")

    student_in_course(course: @course, user: @user1, active_all: true)
    student_in_course(course: @course, user: @user2, active_all: true)
    student_in_course(course: @course, user: @user3, active_all: true)
    teacher_in_course(course: @course, user: @current_user, active_all: true)

    gc1 = @course.group_categories.create!(name: "Levels", non_collaborative: true)
    @tag1 = @course.groups.create!(name: "Beginner", group_category: gc1)
    gc2 = @course.group_categories.create!(name: "Teams", non_collaborative: true)
    @tag2 = @course.groups.create!(name: "Advanced", group_category: gc2)
    gc3 = @course.group_categories.create!(name: "Roles", non_collaborative: true)
    @tag3 = @course.groups.create!(name: "Apprentice", group_category: gc3)
    gc4 = @other_course.group_categories.create!(name: "Others", non_collaborative: true)
    @other_tag = @other_course.groups.create!(name: "Other Tag", group_category: gc4)
    gc5 = @course.group_categories.create!(name: "Collaborative Groups")
    @collab_group = @course.groups.create!(name: "Collab Group", group_category: gc5)

    @tag1.add_user(@user1)
    @tag2.add_user(@user1)
    @tag3.add_user(@user2)
    @collab_group.add_user(@user1)
    @other_tag.add_user(@user1)
  end

  describe "#perform" do
    def fulfills_with_nil_for_user(user_id = @user1.id, course_id = @course.id, current_user = @current_user)
      GraphQL::Batch.batch do
        loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(current_user, course_id)

        loader.load(user_id).then do |tags|
          expect(tags).to be_nil
        end
      end
    end

    context "when prerequisites are not met" do
      it "fulfills with nil when course is not present" do
        fulfills_with_nil_for_user(@user1.id, nil)
      end

      it "fulfills with nil when course ID does not exist" do
        fulfills_with_nil_for_user(@user1.id, 99_999)
      end

      it "fulfills with nil when course is not active" do
        @course.workflow_state = "deleted"
        @course.save!

        fulfills_with_nil_for_user
      end

      it "fulfills with nil when allow_assign_to_differentiation_tags setting is false" do
        @account.settings[:allow_assign_to_differentiation_tags] = { value: false }
        @account.save!

        fulfills_with_nil_for_user
      end

      it "fulfills with nil when user lacks permissions" do
        @account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @account.save!

        # Remove all granular manage tags permissions from the teacher(@current_user)
        RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
          @account.role_overrides.create!(
            permission:,
            role: teacher_role,
            enabled: false
          )
        end

        fulfills_with_nil_for_user
      end
    end

    context "when prerequisites are met" do
      before do
        @account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @account.save!
      end

      it "returns differentiation tag memberships for users with tags" do
        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            expect(tags).not_to be_nil
            expect(tags).to be_an(Array)
            expect(tags.length).to eq 2
            expect(tags).to match_array([
                                          have_attributes(group_id: @tag1.id),
                                          have_attributes(group_id: @tag2.id)
                                        ])
          end

          loader.load(@user2.id).then do |tags|
            expect(tags).not_to be_nil
            expect(tags).to be_an(Array)
            expect(tags.length).to eq 1
            expect(tags.first.group_id).to eq @tag3.id
          end
        end
      end

      it "returns nil for users without differentiation tags" do
        fulfills_with_nil_for_user(@user3.id, @course.id, @current_user)
      end

      it "excludes collaborative groups" do
        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            tag_ids = tags.map(&:group_id)
            expect(tag_ids).not_to include(@collab_group.id)
          end
        end
      end

      it "excludes differentiation tags from other courses" do
        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            tag_ids = tags.map(&:group_id)
            expect(tag_ids).not_to include(@other_tag.id)
          end
        end
      end

      it "excludes deleted differentiation tags" do
        @tag1.workflow_state = "deleted"
        @tag1.save!

        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            expect(tags.length).to eq 1
            expect(tags.first.group_id).to eq @tag2.id
            expect(tags.map(&:group_id)).not_to include(@tag1.id)
          end
        end
      end

      it "excludes inactive group memberships" do
        membership1 = GroupMembership.find_by(user_id: @user1.id, group_id: @tag1.id)
        membership1.workflow_state = "deleted"
        membership1.save!

        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            expect(tags.length).to eq 1
            expect(tags.first.group_id).to eq @tag2.id
            expect(tags.map(&:group_id)).not_to include(@tag1.id)
          end
        end
      end

      it "handles empty list of user IDs" do
        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          expect { loader.perform([]) }.not_to raise_error
        end
      end

      it "handles non-existent user IDs" do
        non_existent_user_id = 99_999

        fulfills_with_nil_for_user(non_existent_user_id, @course.id, @current_user)
      end

      it "returns all tags for a user with multiple tag memberships" do
        gc6 = @course.group_categories.create!(name: "New Category", non_collaborative: true)
        extra_tag = @course.groups.create!(name: "Extra Tag", group_category: gc6)
        extra_tag.add_user(@user1)

        GraphQL::Batch.batch do
          loader = Loaders::UserLoaders::DifferentiationTagsLoader.new(@current_user, @course.id)

          loader.load(@user1.id).then do |tags|
            expect(tags).not_to be_nil
            expect(tags).to be_an(Array)
            expect(tags.length).to eq 3
            expect(tags).to match_array([
                                          have_attributes(group_id: @tag1.id),
                                          have_attributes(group_id: @tag2.id),
                                          have_attributes(group_id: extra_tag.id)
                                        ])
          end
        end
      end
    end
  end
end
