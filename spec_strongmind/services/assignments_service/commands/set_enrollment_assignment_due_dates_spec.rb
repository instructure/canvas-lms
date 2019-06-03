require_relative '../../../rails_helper'

RSpec.describe AssignmentsService::Commands::SetEnrollmentAssignmentDueDates do
  include_context "stubbed_network"

  before do
    @course_start_date     = Time.parse('2019-01-07 23:59:59.999999999 -0700')
    enrollment_start_time = @course_start_date + 1.day

    student_in_course(:active_all => 1)
    @course.update start_at: @course_start_date, conclude_at: @course_start_date + 4.days

    section1 = create_records(CourseSection, [{course_id: @course.id, root_account_id: Account.default.id, name: "Default Section", default_section: true}])

    section2 = create_records(CourseSection, [{course_id: @course.id, root_account_id: Account.default.id, name: "Section 2"}])

    @enrollment  = @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active', course: @course, user: @student)
    @enrollment.update_column :created_at, enrollment_start_time

    @assignment  = @course.assignments.create!(title: "some assignment 1", due_at: Time.now)
    @assignment2 = @course.assignments.create!(title: "some assignment 2", due_at: Time.now)

    @submission  = @assignment.submit_homework(@student)
    @submission2 = @assignment2.submit_homework(@student)

    @assignment_override  = create_adhoc_override_for_assignment(@assignment, @student, {title: 'ALL', due_at: 1.day.ago, due_at_overridden: true})

    @assignment_override2 = create_adhoc_override_for_assignment(@assignment2, @student, {title: 'ALL', due_at: 1.day.ago, due_at_overridden: true})

    allow(PipelineService).to receive(:publish)
    allow(SettingsService).to receive(:get_settings).and_return('enable_unit_grade_calculations' => false)

    instance = double(:query_instance, query: [@assignment, @assignment2])
    allow(AssignmentsService::Queries::AssignmentsWithDueDates).to receive(:new).and_return(instance)

    @command = described_class.new(enrollment: @enrollment)
  end

  describe "#call" do
    context 'feature flags' do
      context 'auto due dates' do
        before do
          allow(SettingsService).to receive(:get_settings).and_return('auto_due_dates' => 'on')
        end

        it 'does not create an assignment override' do
          expect(AssignmentOverrideStudent).to_not receive(:create)
          @command.call
        end
      end

      context 'auto enrollment due dates' do
        before do
          allow(SettingsService).to receive(:get_settings).and_return('auto_enrollment_due_dates' => 'on')
        end

        it 'does not create an assignment override' do
          expect(AssignmentOverrideStudent).to_not receive(:create)
          @command.call
        end
      end

    end

    context 'auto_enrollment_due_dates and auto_due_dates feature is switched on' do
      before do
        AssignmentOverride.destroy_all

        allow(SettingsService).to receive(:get_settings).and_return(
          'auto_due_dates' => 'on',
          'auto_enrollment_due_dates' => 'on'
        )
      end

      it 'creates assignment overrides' do
        AssignmentOverride.destroy_all
        expect {
          @command.call
        }.to change{ AssignmentOverride.count }.by(2)

        expect(AssignmentOverride.last.assignment_override_students.count).to eq 1
        expect(AssignmentOverride.last.due_at_overridden).to eq true
      end

      it 'creates a student override' do
        AssignmentOverride.destroy_all
        @command.call
        expect(AssignmentOverrideStudent.count).to eq 2
      end

      context 'course has no start date' do
        before do
          @course.update start_at: nil
        end

        it 'wont run' do
          expect(AssignmentOverrideStudent).to_not receive(:create)
          @command.call
        end
      end

      context 'enrollment starts before course' do
        let(:enrollment_start_time) { @course_start_date - 1.day }
        before do
          @enrollment.update_column :created_at, enrollment_start_time
        end

        it 'wont run' do
          expect(AssignmentOverrideStudent).to_not receive(:create)
          @command.call
        end
      end


    end
  end

  # easier to pull this out into top level example group
  describe '#call - assignment has no due date' do
    it 'wont run' do
      expect(AssignmentOverrideStudent).to_not receive(:create)
      @command.call
    end
  end
end
