require_relative '../../../rails_helper'

RSpec.describe UnitsService::Queries::GetItems do
  include_context "stubbed_network"

  let(:empty_result) do
    # {<context_module>: []}
    {}.tap { |hash| hash[@context_module] = [] }
  end

  context 'when content is an assignment' do
    before do
      @student                           = student_in_course(:active_all => true).user
      @course1                           = @course
      @context_module                    = @course1.context_modules.create!(:name => "Module 1")
      @assignment                        = @course1.assignments.create!(title: "Assignment 1", workflow_state: 'published')
      @content_tag                       = @context_module.add_item({:id => @assignment.id, :type => 'assignment'})
      @submission                        = @assignment.submit_homework(@student)
    end

    context 'tags with content' do
      it 'returns a content tag' do
        @get_items_query = UnitsService::Queries::GetItems.new(course: @course1)

        result = {}
        result[@context_module] = [@content_tag]
        expect(@get_items_query.query).to eq(result)
      end
    end

    context 'tags without content' do
      it 'does not return a content tag' do
        @get_items_query = UnitsService::Queries::GetItems.new(course: @course1)
        @context_module.content_tags.each {|ct| ct.content = nil; ct.save }
        expect(@get_items_query.query).to eq(empty_result)
      end
    end

    context 'where assignment is not published' do
      it 'does not return the content tag' do
        @course1.assignments.each(&:destroy)
        @unpublished_assignment = @course1.assignments.create!(title: "Assignment 1", workflow_state: 'unpublished')
        @context_module.content_tags.reload
        @get_items_query = UnitsService::Queries::GetItems.new(course: @course1)

        expect(@get_items_query.query).to eq(empty_result)
      end
    end
  end

  context 'when content is a discussion topic' do
    before do
      @discussion_course         = course_factory
      @discussion_topic          = discussion_topic_model(context: @course, workflow_state: 'active')
      @discussion_context_module = @discussion_course.context_modules.create!(:name => "Module 2")
      @discussion_assignment     = @discussion_course.assignments.create!(title: "Assignment 2", workflow_state: 'published')
      @discussion_assignment.update discussion_topic: @discussion_topic
      @discussion_content_tag    = @discussion_context_module.add_item({:id => @discussion_topic.id, :type => 'discussion_topic'})
      @discussion_course_get_items_query = UnitsService::Queries::GetItems.new(course: @discussion_course)
    end

    it 'returns a content tag' do
      result = {}
      result[@discussion_context_module] = [@discussion_content_tag]
      expect(@discussion_course_get_items_query.query).to eq(result)
    end
  end

  context 'when content without submission or assignment' do
    before do
      @student                           = student_in_course(:active_all => true).user
      @course1                           = @course
      @context_module                    = @course1.context_modules.create!(:name => "Module 1")
      @get_items_query                   = UnitsService::Queries::GetItems.new(course: @course1)
    end

    it 'does not return a content tag' do
      expect(@get_items_query.query).to eq(empty_result)
    end
  end
end
