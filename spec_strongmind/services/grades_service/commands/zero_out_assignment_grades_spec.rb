require_relative '../../../rails_helper'

RSpec.describe GradesService::Commands::ZeroOutAssignmentGrades do
  subject {described_class.new(submission)}

  let(:external_tool_tag) do
    double(
      "external_tool_tag",
      url: 'http://bob.bob'
    )
  end

  let(:assignment) do
    double(
      "assignment",
      grade_student: nil,
      published?: true,
      due_at: nil,
      context: course,
      mute!: nil,
      unmute!: nil,
      overridden: true,
      external_tool_tag: external_tool_tag
    )
  end

  let(:user) { double("user") }
  let(:grader) { double("grader") }
  let(:enrollment) {double("enrollment")}
  let(:course) {
    double(
      'course',
      includes_user?: true,
      admin_visible_student_enrollments: [enrollment]
    )
  }

  let(:submission) do
    double(
      "submission",
      id: 1,
      assignment: assignment,
      user: user,
      workflow_state: 'unsubmitted',
      score: nil,
      grade: nil,
      grader: nil,
      cached_due_date: 1.hour.ago
    )
  end

  before do
    allow(GradesService::Account).to receive(:account_admin).and_return(grader)
    allow(SettingsService).to receive(:update_settings)
    allow(SettingsService).to receive('get_settings').and_return({'zero_out_past_due' => 'on'})
  end

  context '#call' do
    it 'uses the correct grader' do
      expect(assignment).to receive(:grade_student).with(any_args, hash_including(grader: grader))
      subject.call!(log_file: 'logfile')
    end

    it 'updates the score to 0' do
      expect(assignment).to receive(:grade_student).with(any_args, hash_including(score: 0))
      subject.call!(log_file: 'logfile')
    end


    context 'logging the operation' do
      it 'logs the operation' do
        fh = File.open('test.log', 'a+')
        expect(File).to receive(:open).and_return(fh)
        expect(fh).to receive(:close)
        expect(fh).to receive(:write).with("1,\n")

        subject.call!(log_file: 'logfile')
      end

      it 'dies if the file can not be opened' do
        allow(CSV).to receive(:open).and_raise
        expect(assignment).to_not receive(:grade_student)
        expect {subject.call!(log_file: 'logfile')}.to raise_error(RuntimeError)
      end
    end

    context 'extended operation logging' do
      before do
        allow(SettingsService).to receive('get_settings').and_return({'zero_out_extended_log' => 'on', 'zero_out_past_due' => 'on'})
      end

      it 'logs the operation with additional details' do
        fh = File.open('test.log', 'a+')
        expect(File).to receive(:open).and_return(fh)
        expect(fh).to receive(:close)
        expect(fh).to receive(:write).with("1,,#{submission.cached_due_date},#{assignment.due_at},true,http://bob.bob\n")

        subject.call!(log_file: 'logfile')
      end

      it 'dies if the file can not be opened' do
        allow(CSV).to receive(:open).and_raise
        expect(assignment).to_not receive(:grade_student)
        expect {subject.call!(log_file: 'logfile')}.to raise_error(RuntimeError)
      end
    end


    context 'will not grade' do
      it 'when there is no due date on the submission' do
        allow(submission).to receive(:cached_due_date).and_return(nil)
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when no logfile is supplied' do
        expect(assignment).to_not receive(:grade_student)
        subject.call!
      end

      it 'when submission is submitted' do
        allow(submission).to receive(:workflow_state).and_return('submitted')
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when submission is graded' do
        allow(submission).to receive(:workflow_state).and_return('graded')
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when submission has a score' do
        allow(submission).to receive(:score).and_return(1)
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when submission is not late' do
        allow(submission).to receive(:grade).and_return(1)
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when submission is on an unpublished assignment' do
        allow(assignment).to receive(:published?).and_return(false)
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when student is not enrolled in the course' do
        allow(course).to receive(:includes_user?).with(
          user,
          course.admin_visible_student_enrollments
        ).and_return(false)
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end

      it 'when the setting is not turned on' do
        allow(SettingsService).to receive(:get_settings).and_return({})
        expect(assignment).to_not receive(:grade_student)
        subject.call!(log_file: 'logfile')
      end
    end

    context 'when in dry run mode' do
      let(:dry_run_file) { double(:dry_run_file, write: nil, close: nil) }

      before do
        allow(assignment).to receive(:due_at?).and_return(2.hour.ago)
        allow(File).to receive(:open).and_return(dry_run_file)
      end

      after do
        subject.call!(log_file: 'logfile', dry_run: true)
      end

      it 'will append the file' do
        expect(File).to receive(:open).with('dry_run.log', 'a+')
      end

      it 'will not run the command' do
        expect(assignment).to_not receive(:grade_student).with(any_args, hash_including(score: 0))
      end

      it 'will log execution plan' do
        expect(dry_run_file).to receive(:write).with("Changing submission 1 from nil to 0\n")
      end
    end
  end
end
