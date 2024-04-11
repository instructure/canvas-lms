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
      UngradedDiscussionStudentVisibility.where(course_id: @course.id, user_id: user.id).pluck(:discussion_topic_id)
    when "wiki_page"
      WikiPageStudentVisibility.where(course_id: @course.id, user_id: user.id).pluck(:wiki_page_id)
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

  shared_examples_for "learning object visiblities" do
    it "includes all objects by default" do
      expect(ids_visible_to_user(@student1, learning_object_type)).to contain_exactly(learning_object1.id, learning_object2.id)
    end

    context "with only_visible_to_overrides set to true" do
      before :once do
        learning_object1.update!(only_visible_to_overrides: true)
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

  shared_examples_for "learning object visiblities with modules" do
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
    end
  end
end
