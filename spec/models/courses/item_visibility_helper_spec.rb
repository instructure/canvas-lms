require_relative '../../spec_helper'

describe Courses::ItemVisibilityHelper do
  before :once do
    course_factory
  end

  it "should load (and cache) visibilities for each model" do
    expect(AssignmentStudentVisibility).to receive(:visible_assignment_ids_in_course_by_user).and_return({}).once
    expect(DiscussionTopic).to receive(:visible_ids_by_user).and_return({}).once
    expect(WikiPage).to receive(:visible_ids_by_user).and_return({}).once
    expect(Quizzes::QuizStudentVisibility).to receive(:visible_quiz_ids_in_course_by_user).and_return({}).once

    Courses::ItemVisibilityHelper::ITEM_TYPES.each do |item_type|
      2.times do
        expect(@course.visible_item_ids_for_users(item_type, [2])).to eq []
      end
    end
  end

  it "should preload visibilities if desired" do
    assignment_model(course: @course, submission_types: "online_url", workflow_state: "published", only_visible_to_overrides: false)

    enrolls = []
    2.times { enrolls << student_in_course(:course => @course) }

    expect(AssignmentStudentVisibility).to receive(:visible_assignment_ids_in_course_by_user).once.and_call_original
    @course.cache_item_visibilities_for_user_ids(enrolls.map(&:user_id)) # should call once and cache

    enrolls.map(&:user_id).each do |user_id|
      expect(@course.visible_item_ids_for_users(:assignment, [user_id])).to eq [@assignment.id]
    end
  end
end
