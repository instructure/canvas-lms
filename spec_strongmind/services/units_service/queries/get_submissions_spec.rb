require_relative '../../../rails_helper'

RSpec.describe UnitsService::Queries::GetSubmissions do
  include_context "stubbed_network"

  context 'when item is a discussion topic' do
    before do
      @student                   = student_in_course(:active_all => true).user
      @discussion_course         = @course
      @discussion_course         = course_factory
      @discussion_topic          = discussion_topic_model(context: @course, workflow_state: 'active')
      @discussion_context_module = @discussion_course.context_modules.create!(name: "Module 2")
      @discussion_assignment     = @discussion_course.assignments.create!(title: "Assignment 2", workflow_state: 'published')
      @discussion_assignment.update discussion_topic: @discussion_topic
      @discussion_submission     = @discussion_assignment.submit_homework(@student)
      @discussion_content_tag    = @discussion_context_module.add_item({id: @discussion_topic.id, type: 'discussion_topic'})
      @get_submissions_query = UnitsService::Queries::GetSubmissions.new(student: @student, course: @discussion_course)
    end

    it 'returns the submission from the related assignment' do
      result = {}
      result[@discussion_context_module] = [@discussion_submission]
      expect(@get_submissions_query.query).to eq result
    end
  end

  context 'when content is an assignment' do
    before do
      @student            = student_in_course(:active_all => true).user
      @course1            = @course
      @context_module     = @course1.context_modules.create!(name: "Module 1") # unit
      @assignment         = @course1.assignments.create!(title: "Assignment 1", workflow_state: 'published')
      @content_tag        = @context_module.add_item({id: @assignment.id, type: 'assignment'}) # item
      @submission         = @assignment.submit_homework(@student)

      @get_submissions_query = UnitsService::Queries::GetSubmissions.new(student: @student, course: @course1)
    end

    it 'returns the unit and its submissions' do
      result = {}
      result[@context_module] = [@submission]
      expect(@get_submissions_query.query).to eq result
    end

    context "with excused submission" do
      before do
        @assignment2         = @course1.assignments.create!(title: "Assignment 2", workflow_state: 'published')
        @content_tag2        = @context_module.add_item({id: @assignment2.id, type: 'assignment'}) # item
        @submission2         = @assignment2.submit_homework(@student)

        @excused_submission = @assignment.submit_homework(@student)
        @excused_submission.update excused: true
      end

      it 'will not return the excused submission' do
        expect(@get_submissions_query.query[@context_module]).to_not include(@excused_submission)
      end
    end
  end
end
