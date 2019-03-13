require_relative '../rails_helper'

RSpec.describe 'Assignment', type: :model do
  describe 'Callbacks' do
    describe 'after_save' do
      let!(:assign) { assignment_model }

      it 'publishes to the Pipeline' do
        expect(PipelineService).to receive(:publish).with(an_instance_of(Assignment))
        assign.save
      end
    end
  end
end