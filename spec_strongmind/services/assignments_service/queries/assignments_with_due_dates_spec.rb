require_relative '../../../rails_helper'

RSpec.describe AssignmentsService::Queries::AssignmentsWithDueDates do
  include_context "stubbed_network"

  let!(:course) { teacher_in_course; @course }
  let!(:assignment) { assignment_model(context: @course) }
  let!(:context_module) { course.context_modules.create(name: 'Unit 1', context: course) }
  let!(:content_tag) { context_module.add_item({:id => assignment.id, :type => 'assignment'}) }

  subject { described_class.new(course: course) }

  describe '#query' do
    it 'returns assignments' do
      expect(subject.query).to eq [assignment]
    end
  end
end
