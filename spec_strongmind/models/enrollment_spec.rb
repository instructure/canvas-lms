require_relative '../rails_helper'


RSpec.describe 'Enrollment', type: :model do
  include_context 'stubbed_network'
  describe "#after_commit" do
    let(:enrollment) do 
      Enrollment.create(
          course: Course.create, 
          user: User.create, 
          type: "StudentEnrollment", 
          workflow_state: "active"
        )
    end

    it "reactivates deleted scores when active" do
      Score.create(enrollment: enrollment, workflow_state: "deleted")
      enrollment.save
      expect(Score.first.workflow_state).to eq("active")
    end

    it "does not run on active scores" do
      Score.create(enrollment: enrollment, workflow_state: "active")
      enrollment.save
      expect(Score.first).not_to receive(:update)
    end
  end
  
  describe '#after_create' do
      let(:command) { double("Command", perform: nil)}

    describe 'AssignmentsService.distribute_due_dates' do
          it 'calls SetEnrollmentAssignmentDueDates command and enqueues it to run in background' do
              expect(AssignmentsService::Commands::SetEnrollmentAssignmentDueDates).to receive(:new).and_return(command)
              expect(Delayed::Job).to receive(:enqueue).with(command)
              course_with_student
          end
      end
  end
end
