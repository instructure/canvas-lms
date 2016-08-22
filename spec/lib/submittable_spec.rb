require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

shared_examples_for "submittable" do
  describe "visible_ids_by_user" do
    before :once do
      @course = course(active_course: true)

      @item_without_assignment = submittable_without_assignment
      @item_with_assignment_and_only_vis, @assignment = submittable_and_assignment(only_visible_to_overrides: true)
      @item_with_assignment_and_visible_to_all, @assignment2 = submittable_and_assignment(only_visible_to_overrides: false)
      @item_with_override_for_section_with_no_students, @assignment3 = submittable_and_assignment(only_visible_to_overrides: true)
      @item_with_no_override, @assignment4 = submittable_and_assignment(only_visible_to_overrides: true)

      @course_section = @course.course_sections.create
      @student1, @student2, @student3 = create_users(3, return_type: :record)
      @course.enroll_student(@student2, enrollment_state: 'active')
      @section = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "second test section")
      student_in_section(@section, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section})
      create_section_override_for_assignment(@assignment3, {course_section: @section2})
      @course.reload
      @vis_hash = submittable_class.visible_ids_by_user(course_id: @course.id, user_id: [@student1, @student2, @student3].map(&:id))
    end

    it "should return both topics for a student with an override" do
      expect(@vis_hash[@student1.id].sort).to eq [
        @item_without_assignment.id,
        @item_with_assignment_and_only_vis.id,
        @item_with_assignment_and_visible_to_all.id
      ].sort
    end

    it "should not return differentiated topics to a student with no overrides" do
      expect(@vis_hash[@student2.id].sort).to eq [
        @item_without_assignment.id,
        @item_with_assignment_and_visible_to_all.id
      ].sort
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
        submission_types: 'discussion_topic'
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
        submission_types: 'wiki_page'
      }.merge(opts))
      page = submittable_without_assignment
      page.assignment_id = assignment.id
      page.save!
      [page, assignment]
    end
  end
end
