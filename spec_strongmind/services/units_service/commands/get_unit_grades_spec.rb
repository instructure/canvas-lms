require_relative '../../../rails_helper'

RSpec.describe UnitsService::Commands::GetUnitGrades do
  include_context "stubbed_network"

  let!(:account_admin) do
    user_with_pseudonym(account: Account.default)
    account_admin_user(user: @user)
  end

  before do
    @enrollment = student_in_course(:active_all => true)
    @student    = @enrollment.student
    @pseudonym  = pseudonym(@student)

    teacher_in_course(course: @course)

    @context_module = @course.context_modules.create!(name: "Module 1") # unit
    @assignment     = @course.assignments.create!(title: "Assignment 1", workflow_state: 'published')
    @content_tag    = @context_module.add_item({id: @assignment.id, type: 'assignment'}) # item
    @submission     = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "o hai")

    calculator_instance = double('calculator_instance', call: { @context_module => 54 })

    allow(SettingsService).to receive(:get_settings).and_return('auto_due_dates' => nil, 'auto_enrollment_due_dates' => nil)
    allow(UnitsService::GradesCalculator).to receive(:new).and_return(calculator_instance)
    allow_any_instance_of(Enrollment).to receive(:computed_current_score).and_return(90)
  end

  describe '#call' do
    it 'returns the calculator results' do
      @pseudonym.update! sis_user_id: 1001
      @submission.update!(graded_at: Time.zone.now, grader_id: @teacher.id, score: 54)
      @command = UnitsService::Commands::GetUnitGrades.new(course: @course, student: @student, submission: @submission)

      expect(@command.call).to eq(
        course_id: @course.id,
        course_score: 90,
        school_domain: ENV['CANVAS_DOMAIN'],
        student_id: @student.id,
        sis_user_id: '1001',
        submitted_at: @submission[:submitted_at],
        units: [{
          score: 54,
          id: @context_module.id,
          position: @context_module.position,
          excused: false
        }]
      )
    end
  end

  describe "#submissions_graded?" do
    context 'when student has a graded submission' do
      it "does the thing" do
        @submission.update!(graded_at: Time.zone.now, grader_id: @teacher.id, score: 54)
        @command = UnitsService::Commands::GetUnitGrades.new(course: @course, student: @student, submission: @submission)

        expect(@command.send(:submissions_graded?, @context_module, 54)).to eq 54
      end
    end

    context "when student has no graded submissions" do
      it 'does not do the thing' do
        @command = UnitsService::Commands::GetUnitGrades.new(course: @course, student: @student, submission: @submission)

        expect(@command.send(:submissions_graded?, @context_module, 0)).to eq nil
      end
    end

    context "when student has graded submissions from zerograder" do
      it 'does not do the thing' do
        @submission.update!(graded_at: Time.zone.now, grader_id: account_admin.id, score: 0)
        @command = UnitsService::Commands::GetUnitGrades.new(course: @course, student: @student, submission: @submission)

        expect(@command.send(:submissions_graded?, @context_module, 0)).to eq nil
      end
    end
  end
end
