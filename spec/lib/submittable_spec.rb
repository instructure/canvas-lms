# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

shared_examples_for "submittable" do
  describe "visible_ids_by_user" do
    before :once do
      @course = course_factory(active_course: true)

      @item_without_assignment = submittable_without_assignment
      @item_with_assignment_and_only_vis, @assignment = submittable_and_assignment(only_visible_to_overrides: true)
      @item_with_assignment_and_visible_to_all, @assignment2 = submittable_and_assignment(only_visible_to_overrides: false)
      @item_with_override_for_section_with_no_students, @assignment3 = submittable_and_assignment(only_visible_to_overrides: true)
      @item_with_no_override, @assignment4 = submittable_and_assignment(only_visible_to_overrides: true)

      @course_section = @course.course_sections.create
      @student1, @student2, @student3 = create_users(3, return_type: :record)
      @course.enroll_student(@student2, enrollment_state: "active")
      @section = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "second test section")
      student_in_section(@section, user: @student1)
      create_section_override_for_assignment(@assignment, { course_section: @section })
      create_section_override_for_assignment(@assignment3, { course_section: @section2 })
      @course.reload
      @vis_hash = submittable_class.visible_ids_by_user(course_id: @course.id, user_id: [@student1, @student2, @student3].map(&:id))
    end

    it "returns both topics for a student with an override" do
      expect(@vis_hash[@student1.id].sort).to eq [
        @item_without_assignment.id,
        @item_with_assignment_and_only_vis.id,
        @item_with_assignment_and_visible_to_all.id
      ].sort
    end

    it "does not return differentiated topics to a student with no overrides" do
      expect(@vis_hash[@student2.id].sort).to eq [
        @item_without_assignment.id,
        @item_with_assignment_and_visible_to_all.id
      ].sort
    end
  end

  describe "#update_assignment" do
    context "with course paces" do
      before do
        @course = course_factory(active_course: true)
        @item_without_assignment = submittable_without_assignment
        @item_with_assignment, @assignment = submittable_and_assignment

        @course.root_account.enable_feature!(:course_paces)
        @course.enable_course_paces = true
        @course.save!
        @course_pace = course_pace_model(course: @course)
        @module = @course.context_modules.create!(name: "some module")
        @module.add_item(type: @item_without_assignment.model_name.param_key, id: @item_without_assignment.id)
        @module.add_item(type: @item_with_assignment.model_name.param_key, id: @item_with_assignment.id)
        @module.save!
        # #update_assignment is only called if conditional_release is enabled
        if submittable_class == WikiPage
          @course.conditional_release = true
          @course.save!
        end
        # Reset progresses to verify progresses are added during tests
        Progress.destroy_all
      end

      it "runs update_course_pace_module_items on content tags when an assignment is created" do
        expect(Progress.last).to be_nil
        @item_without_assignment.update(assignment: @course.assignments.create!)
        expect(Progress.last.context).to eq(@course_pace)
      end

      it "runs update_course_pace_module_items on content tags when an assignment is removed" do
        expect(Progress.last).to be_nil
        @item_with_assignment.update(assignment: nil)
        expect(Progress.last.context).to eq(@course_pace)
      end
    end
  end
end

describe DiscussionTopic do
  let(:submittable_class) { DiscussionTopic }

  include_examples "submittable" do
    def submittable_without_assignment
      discussion_topic_model(user: @teacher)
    end

    def submittable_and_assignment(opts = {})
      assignment = @course.assignments.create!({
        title: "some discussion assignment",
        submission_types: "discussion_topic"
      }.merge(opts))
      [assignment.discussion_topic, assignment]
    end
  end
end

describe WikiPage do
  let(:submittable_class) { WikiPage }

  include_examples "submittable" do
    def submittable_without_assignment
      wiki_page_model(course: @course)
    end

    def submittable_and_assignment(opts = {})
      assignment = @course.assignments.create!({
        title: "glorious page assignment",
        submission_types: "wiki_page"
      }.merge(opts))
      page = submittable_without_assignment
      page.assignment_id = assignment.id
      page.save!
      [page, assignment]
    end
  end
end

describe "section specific topic" do
  def add_section_to_topic(topic, section)
    topic.is_section_specific = true
    topic.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        discussion_topic: topic,
        course_section: section,
        workflow_state: "active"
      )
    topic.save!
  end

  it "filters section specific topics properly" do
    course = course_factory(active_course: true)
    section1 = course.course_sections.create!(name: "test section")
    section2 = course.course_sections.create!(name: "second test section")
    section_specific_topic1 = course.discussion_topics.create!(title: "section specific topic 1")
    section_specific_topic2 = course.discussion_topics.create!(title: "section specific topic 2")
    add_section_to_topic(section_specific_topic1, section1)
    add_section_to_topic(section_specific_topic2, section2)
    student = create_users(1, return_type: :record).first
    course.enroll_student(student, section: section1)
    course.reload
    vis_hash = DiscussionTopic.visible_ids_by_user(course_id: course.id, user_id: [student.id], item_type: :discussion)
    expect(vis_hash[student.id].length).to eq(1)
    expect(vis_hash[student.id].first).to eq(section_specific_topic1.id)
  end

  it "filters section specific topics properly for multiple users" do
    course = course_factory(active_all: true)
    section1 = course.course_sections.create!(name: "section 1")
    section2 = course.course_sections.create!(name: "section 2")
    topic1 = course.discussion_topics.create!(title: "topic 1 (for section 1)")
    topic2 = course.discussion_topics.create!(title: "topic 2 (for section 2)")
    topic3 = course.discussion_topics.create!(title: "topic 3 (for all sections)")
    topic4 = course.discussion_topics.create!(title: "topic 4 (for section 2)")
    add_section_to_topic(topic1, section1)
    add_section_to_topic(topic2, section2)
    add_section_to_topic(topic4, section2)
    student = user_factory(active_all: true)
    teacher = user_factory(active_all: true)
    course.enroll_student(student, section: section2)
    course.enroll_teacher(teacher, section: section1)
    course.reload

    vis_hash = DiscussionTopic.visible_ids_by_user(course_id: course.id, user_id: [student.id, teacher.id], item_type: :discussion)
    expect(vis_hash[student.id]).to contain_exactly(topic2.id, topic3.id, topic4.id)
    expect(vis_hash[teacher.id]).to contain_exactly(topic1.id, topic3.id)
  end

  it "properly filters section specific topics for deleted section visibilities" do
    course = course_factory(active_course: true)
    section1 = course.course_sections.create!(name: "section for student")
    section_specific_topic1 = course.discussion_topics.create!(title: "section specific topic 1")
    add_section_to_topic(section_specific_topic1, section1)
    student = create_users(1, return_type: :record).first
    course.enroll_student(student, section: section1)
    course.reload
    section_specific_topic1.destroy
    vis_hash = DiscussionTopic.visible_ids_by_user(course_id: course.id, user_id: [student.id], item_type: :discussion)
    expect(vis_hash[student.id].length).to eq(0)
  end

  it "handles sections that don't have any discussion topics" do
    course = course_factory(active_all: true)
    section1 = course.course_sections.create!(name: "section 1")
    section2 = course.course_sections.create!(name: "section 2")
    topic1 = course.discussion_topics.create!(title: "topic 1 (for section 1)")
    add_section_to_topic(topic1, section1)
    student = user_factory(active_all: true)
    course.enroll_student(student, section: section2)
    course.reload

    vis_hash = DiscussionTopic.visible_ids_by_user(course_id: course.id, user_id: [student.id], item_type: :discussion)
    expect(vis_hash[student.id].length).to be(0)
  end

  it "handles user not enrolled in any sections" do
    course = course_factory(active_all: true)
    section1 = course.course_sections.create!(name: "section 1")
    topic1 = course.discussion_topics.create!(title: "topic 1 (for section 1)")
    add_section_to_topic(topic1, section1)
    student = user_factory(active_all: true)
    course.reload

    vis_hash = DiscussionTopic.visible_ids_by_user(course_id: course.id, user_id: [student.id], item_type: :discussion)
    expect(vis_hash[student.id].length).to be(0)
  end
end
