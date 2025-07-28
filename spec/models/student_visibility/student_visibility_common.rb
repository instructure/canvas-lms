# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module StudentVisibilityCommon
  def ids_visible_to_user(user, learning_object_type)
    case learning_object_type
    when "discussion_topic"
      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.discussion_topics_visible(course_ids: @course.id, user_ids: user.id).map(&:discussion_topic_id)
    when "wiki_page"
      WikiPageVisibility::WikiPageVisibilityService.wiki_pages_visible_to_students(course_ids: @course.id, user_ids: user.id).map(&:wiki_page_id)
    end
  end

  def ids_visible_to_user_without_course_ids(user, learning_object_type)
    case learning_object_type
    when "discussion_topic"
      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.discussion_topics_visible(course_ids: nil, user_ids: user.id).map(&:discussion_topic_id)
    when "wiki_page"
      WikiPageVisibility::WikiPageVisibilityService.wiki_pages_visible_to_students(course_ids: nil, user_ids: user.id).map(&:wiki_page_id)
    end
  end

  shared_examples_for "student visibility models" do
    context "table" do
      it "returns objects" do
        expect(visibility_object).not_to be_nil
      end

      it "doesnt allow updates" do
        visibility_object.user_id = visibility_object.user_id + 1
        expect { visibility_object.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "doesnt allow new records" do
        expect do
          visibility_object.class.create!(visibility_object.attributes)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "doesnt allow deletion" do
        expect { visibility_object.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end
  end

  shared_examples_for "learning object visibilities" do
    it "includes all objects by default" do
      expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
    end

    # run for all visibility queries
    context "with only_visible_to_overrides set to true" do
      before :once do
        learning_object1.update!(only_visible_to_overrides: true)
      end

      context "non-collaborative group" do
        before do
          @course.account.enable_feature!(:assign_to_differentiation_tags)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @course.account.save!

          # additional student for testing differentiation tags
          @student3 = student_in_course(active_all: true, course: @course, name: "Student 3").user

          @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
          @group_category.create_groups(2)
          @differentiation_tag_group_1 = @group_category.groups[0]
          @differentiation_tag_group_2 = @group_category.groups[1]
        end

        it "does not include objects with a non collaborative override unless the user is in the group" do
          @differentiation_tag_group_1.add_user(@student1)
          @differentiation_tag_group_1.add_user(@student3)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        end

        it "does not include object with a non collaborative group if feature flag is disabled" do
          @differentiation_tag_group_1.add_user(@student1)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          @course.account.disable_feature!(:assign_to_differentiation_tags)
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "does include object with non collaborative group if course_ids is not present" do
          @differentiation_tag_group_1.add_user(@student1)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          expect(ids_visible_to_user_without_course_ids(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user_without_course_ids(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user_without_course_ids(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "does include object with a non collaborative group if account setting is disabled" do
          # Once a learning object is assigned to a non-collaborative group, it should be visible
          # to all students in that group.  If the account setting is disabled, these learning objects should still be visible
          # to all students in the non collaborative group until the instructor has indicated that the learning object should
          # no longer be assigned to a non collaborative group.  This can be done by manually removing the learning object from the
          # group or by selecting to bulk remove all non collaborative groups assigned to learning objects.
          # Please refer to rollback plan for more information
          # https://instructure.atlassian.net/wiki/spaces/EGGWIKI/pages/86942646273/Tech+Plan+Assign+To+Hidden+Groups#Rollback-Plan
          @differentiation_tag_group_1.add_user(@student1)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
          @course.account.save!
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "ignores deleted overrides" do
          @differentiation_tag_group_1.add_user(@student3)
          @differentiation_tag_group_2.add_user(@student1)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          learning_object1.assignment_overrides.create!(set: @differentiation_tag_group_2, workflow_state: "deleted")
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        end
      end

      it "does not include objects with a section override unless the user is in the section" do
        learning_object1.assignment_overrides.create!(set: @section2)
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
      end

      it "does not include objects with an adhoc override unless the user is in the set" do
        override = learning_object1.assignment_overrides.create!
        override.assignment_override_students.create!(user: @student1)
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
      end

      it "ignores deleted overrides" do
        learning_object1.assignment_overrides.create!(set: @section1)
        learning_object1.assignment_overrides.create!(set: @section2, workflow_state: "deleted")
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
      end
    end
  end

  shared_examples_for "learning object visibilities with modules" do
    context "with module overrides" do
      before :once do
        learning_object1.update!(only_visible_to_overrides: false)
        @module1 = @course.context_modules.create!(name: "Module 1")
        @module2 = @course.context_modules.create!(name: "Module 2")
        learning_object1.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"
      end

      it "includes everyone if module has no overrides" do
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
      end

      it "includes unpublished modules" do
        @module1.workflow_state = "unpublished"
        @module1.save!

        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
      end

      it "does not include modules with a section override unless the user is in the section" do
        @module1.assignment_overrides.create!(set: @section2)

        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
      end

      it "does not include modules with an adhoc override unless the user is in the set" do
        override = @module1.assignment_overrides.create!
        override.assignment_override_students.create!(user: @student1)
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
      end

      it "ignores deleted overrides" do
        @module1.assignment_overrides.create!(set: @section2, workflow_state: "deleted")
        expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
        expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
      end

      context "non-collaborative group" do
        before do
          @course.account.enable_feature!(:assign_to_differentiation_tags)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @course.account.save!

          # additional student for testing differentiation tags
          @student3 = student_in_course(active_all: true, course: @course, name: "Student 3").user

          @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
          @group_category.create_groups(2)
          @differentiation_tag_group_1 = @group_category.groups[0]
          @differentiation_tag_group_2 = @group_category.groups[1]
        end

        it "does not include module with a non collaborative override unless the user is in the group" do
          # learning_object1 is in the module1
          # learning_object2 is not in a module
          @differentiation_tag_group_1.add_user(@student3)
          @module1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "does not include module with a non collaborative group if feature flag is disabled" do
          @differentiation_tag_group_1.add_user(@student1)
          @module1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          @course.account.disable_feature!(:assign_to_differentiation_tags)
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "does include module with a non collaborative group if account setting is disabled" do
          # Once a learning object is assigned to a non-collaborative group, it should be visible
          # to all students in that group.  If the account setting is disabled, these learning objects should still be visible
          # to all students in the non collaborative group until the instructor has indicated that the learning object should
          # no longer be assigned to a non collaborative group.  This can be done by manually removing the learning object from the
          # group or by selecting to bulk remove all non collaborative groups assigned to learning objects.
          # Please refer to rollback plan for more information
          # https://instructure.atlassian.net/wiki/spaces/EGGWIKI/pages/86942646273/Tech+Plan+Assign+To+Hidden+Groups#Rollback-Plan
          @differentiation_tag_group_1.add_user(@student1)
          @module1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
          @course.account.save!

          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end

        it "ignores deleted overrides" do
          @differentiation_tag_group_1.add_user(@student1)
          @differentiation_tag_group_2.add_user(@student3)
          @module1.assignment_overrides.create!(set: @differentiation_tag_group_1)
          @module1.assignment_overrides.create!(set: @differentiation_tag_group_2, workflow_state: "deleted")
          expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
          expect(ids_visible_to_user(@student2, learning_object_type)).to contain_exactly(learning_object2.id)
          expect(ids_visible_to_user(@student3, learning_object_type)).to contain_exactly(learning_object2.id)
        end
      end
    end
  end
end
