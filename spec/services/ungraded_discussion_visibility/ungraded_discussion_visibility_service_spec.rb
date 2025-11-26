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

require_relative "../../models/student_visibility/student_visibility_common"

describe "UngradedDiscussionVisibility" do
  include StudentVisibilityCommon

  def assignment_ids_visible_to_user(user)
    AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(course_ids: @course.id, user_ids: user.id).map(&:assignment_id)
  end

  before :once do
    course_factory(active_all: true)
    @section1 = @course.default_section
    @section2 = @course.course_sections.create!(name: "Section 2")
    @student1 = student_in_course(active_all: true, section: @section1).user
    @student2 = student_in_course(active_all: true, section: @section2).user
    @discussion1 = DiscussionTopic.create!(context: @course, title: "Page 1")
    @discussion2 = DiscussionTopic.create!(context: @course, title: "Page 2")
  end

  context "ungraded discussion topic visibility" do
    let(:learning_object1) { @discussion1 }
    let(:learning_object2) { @discussion2 }
    let(:learning_object_type) { "discussion_topic" }

    it_behaves_like "learning object visibilities with modules" do
      before :once do
        Account.site_admin.disable_feature!(:visibility_performance_improvements)
      end
    end
    it_behaves_like "learning object visibilities with modules" do
      before :once do
        Account.site_admin.enable_feature!(:visibility_performance_improvements)
      end
    end
    it_behaves_like "learning object visibilities"

    it "does not include unpublished discussion topics" do
      @discussion1.workflow_state = "unpublished"
      @discussion1.save!
      expect(ids_visible_to_user(@student1, "discussion_topic")).to contain_exactly(@discussion2.id)
    end
  end

  context "graded discussion topic visibility" do
    # graded discussion topics must use assignment_student_visibility as their
    # assignment overrides are on the assignment, not the discussion topic
    before :once do
      @discussion1_assignment = @course.assignments.create!
      @discussion2_assignment = @course.assignments.create!

      @discussion1.update!(assignment: @discussion1_assignment)
      @discussion2.update!(assignment: @discussion2_assignment)
    end

    it "ungraded_discussion_student_visibilities does not include graded discussion's assignment overrides" do
      @discussion1_assignment.only_visible_to_overrides = true
      @discussion1_assignment.save!

      @discussion1.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @section2.id)

      # The overrides are on the assignment, not the discussion topic, so discussion visibilities will not be affected
      expect(ids_visible_to_user(@student1, "discussion_topic")).to contain_exactly(@discussion1.id, @discussion2.id)
    end

    it "assignment_ids_visible_to_user shows correct visibilities for graded discussion topic's assignment" do
      @discussion1_assignment.only_visible_to_overrides = true
      @discussion1_assignment.save!

      @discussion1.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @section2.id)

      expect(assignment_ids_visible_to_user(@student1)).to contain_exactly(@discussion2.assignment.id)
      expect(assignment_ids_visible_to_user(@student2)).to contain_exactly(@discussion1.assignment.id, @discussion2.assignment.id)
    end

    it "gets module overrides from graded discussion topic's assignment" do
      @module1 = @course.context_modules.create!(name: "Module 1")
      @module2 = @course.context_modules.create!(name: "Module 2")
      @discussion1.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"

      override = @module1.assignment_overrides.create!
      override.assignment_override_students.create!(user: @student1)
      expect(ids_visible_to_user(@student1, "discussion_topic")).to contain_exactly(@discussion1.id, @discussion2.id)
      expect(ids_visible_to_user(@student2, "discussion_topic")).to contain_exactly(@discussion2.id)

      expect(assignment_ids_visible_to_user(@student1)).to contain_exactly(@discussion1.assignment.id, @discussion2.assignment.id)
      expect(assignment_ids_visible_to_user(@student2)).to contain_exactly(@discussion2.assignment.id)
    end
  end

  describe ".invalidate_cache" do
    it "raises an error when neither course_ids nor discussion_topic_ids are provided" do
      expect do
        UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.invalidate_cache(user_ids: [@student1.id])
      end.to raise_error(ArgumentError, "at least one non nil course_id or discussion_topic_id is required (for query performance reasons)")
    end

    it "deletes the cache when called with course_ids" do
      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.discussion_topics_visible(
        course_ids: [@course.id],
        user_ids: [@student1.id],
        discussion_topic_ids: [@discussion1.id]
      )

      expect(Rails.cache).to receive(:delete).and_call_original

      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.invalidate_cache(
        course_ids: [@course.id],
        user_ids: [@student1.id],
        discussion_topic_ids: [@discussion1.id]
      )
    end

    it "deletes the cache when called with discussion_topic_ids only" do
      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.discussion_topics_visible(
        discussion_topic_ids: [@discussion1.id, @discussion2.id]
      )

      expect(Rails.cache).to receive(:delete).and_call_original

      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.invalidate_cache(
        discussion_topic_ids: [@discussion1.id, @discussion2.id]
      )
    end

    it "accepts include_concluded parameter" do
      expect do
        UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.invalidate_cache(
          course_ids: [@course.id],
          include_concluded: false
        )
      end.not_to raise_error
    end

    it "works with multiple user_ids" do
      expect(Rails.cache).to receive(:delete).and_call_original

      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.invalidate_cache(
        course_ids: [@course.id],
        user_ids: [@student1.id, @student2.id],
        discussion_topic_ids: [@discussion1.id]
      )
    end
  end
end
