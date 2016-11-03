require_relative '../../spec_helper'

describe SupportHelpers::Tii do
  describe "Fixer" do
    describe "#job_id" do
      it 'generates a unique id' do
        fixer1 = SupportHelpers::Tii::ShardFixer.new('email')
        fixer2 = SupportHelpers::Tii::ShardFixer.new('email')
        expect(fixer1.job_id).not_to eq(fixer2.job_id)
      end
    end

    describe '#fixer_name' do
      it 'returns the fixer class name and job id' do
        fixer = SupportHelpers::Tii::ShardFixer.new('email')
        expect(fixer.fixer_name).to eq "TurnItIn ShardFixer ##{fixer.job_id}"
      end
    end

    describe '#monitor_and_fix' do
      it 'emails the caller upon success' do
        fixer = SupportHelpers::Tii::ShardFixer.new('email')
        Message.expects(:new).with do |actual|
          actual.slice(:to, :from, :subject, :delay_for) == {
            to: 'email',
            from: 'tii_script@instructure.com',
            subject: 'TurnItIn Fixer Success',
            delay_for: 0
          } && actual[:body] =~ /fixed 0 assignments in \d+ seconds/
        end
        Mailer.expects(:create_message)
        fixer.monitor_and_fix
      end

      it 'emails the caller upon error' do
        fixer = SupportHelpers::Tii::Fixer.new('email')
        Message.expects(:new)
        Mailer.expects(:create_message)
        begin
          fixer.monitor_and_fix
        rescue => error
          expect(error.message).to eq 'SupportHelpers::Tii::Fixer must implement #fix'
        end
      end
    end
  end

  describe "Error2305Fixer" do
    before :once do
      @a1 = generate_assignment({error_code: 2305, error_message: 'sad panda'})
      @a2 = generate_assignment
      @a3 = generate_assignment({error_code: 2305, error_message: 'rad panda'})
      @a4 = generate_assignment({error_code: 1027, error_message: 'bad panda'})
      Timecop.travel(5.months.ago) do
        @a5 = generate_assignment({error_code: 2305, error_message: 'mad panda'})
      end
    end

    describe '#new' do
      it 'finds all broken assignments' do
        fixer = SupportHelpers::Tii::Error2305Fixer.new('email')
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id]
      end

      it 'finds more broken submissions with an older after_time' do
        fixer = SupportHelpers::Tii::Error2305Fixer.new('email', 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id, @a5.id]
      end
    end

    describe '#fix' do
      it 'creates an AssignmentFixer for each broken assignment' do
        after_time = 2.months.ago
        e2305_fixer = SupportHelpers::Tii::Error2305Fixer.new('email', after_time)
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new('email', after_time, @a1.id)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', after_time, @a1.id).returns(assignment_fixer)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', after_time, @a3.id).returns(assignment_fixer)
        assignment_fixer.expects(:fix).with(:assignment_fix).twice
        Timecop.scale(300) { e2305_fixer.fix }
      end
    end
  end

  describe "MD5Fixer" do
    before :once do
      @a1 = generate_assignment({error_message: 'MD5 not authenticated'})
      @a2 = generate_assignment({error_code: 2305, error_message: 'bad panda'})
      @a3 = generate_assignment({error_message: 'MD5 not authenticated'})
      @a4 = generate_assignment
      Timecop.travel(5.months.ago) do
        @a5 = generate_assignment({error_code: 2305, error_message: 'MD5 not authenticated'})
      end
    end

    describe '#new' do
      it 'finds all broken assignments' do
        fixer = SupportHelpers::Tii::MD5Fixer.new('email')
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id]
      end

      it 'finds more broken submissions with an older after_time' do
        fixer = SupportHelpers::Tii::MD5Fixer.new('email', 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id, @a5.id]
      end
    end

    describe '#fix' do
      it 'creates an AssignmentFixer for each broken assignment' do
        after_time = 2.months.ago
        md5_fixer = SupportHelpers::Tii::MD5Fixer.new('email', after_time)
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new('email', after_time, @a1.id)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', after_time, @a1.id).returns(assignment_fixer)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', after_time, @a3.id).returns(assignment_fixer)
        assignment_fixer.expects(:fix).with(:md5_fix).twice
        Timecop.scale(300) { md5_fixer.fix }
      end
    end
  end

  describe "ShardFixer" do
    before :once do
      @a1 = generate_assignment
      @s1 = Timecop.travel(2.hours.ago) do
        generate_submission({status: 'rawr error rawr'}, @a1)
      end
      @s2 = Timecop.travel(2.hours.ago) do
        generate_submission({status: 'there was an error'}, @a1)
      end
      @s3 = Timecop.travel(2.hours.ago) do
        generate_submission({status: 'all good in the hood'}, @a1)
      end
      @s4 = Timecop.travel(2.hours.ago) do
        generate_submission({status: 'boop error'})
      end
      @s5 = Timecop.travel(5.months.ago) do
        generate_submission({status: 'old error is very old'})
      end
      @s6 = Timecop.travel(2.hours.ago) do
        generate_submission
      end
      @s7 = generate_submission({status: 'rawr error rawr'})
    end

    describe '#new' do
      it 'finds all broken assignments' do
        fixer = SupportHelpers::Tii::ShardFixer.new('email')
        expect(fixer.broken_objects).to match_array [@a1.id, @s4.assignment_id]
      end

      it 'finds more broken submissions with an older after_time' do
        fixer = SupportHelpers::Tii::ShardFixer.new('email', 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @s4.assignment_id, @s5.assignment_id]
      end
    end

    describe '#fix' do
      it 'creates an AssignmentFixer for each broken assignment' do
        shard_fixer = SupportHelpers::Tii::ShardFixer.new('email')
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', is_a(Time), @a1.id).returns(assignment_fixer)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with('email', is_a(Time), @s4.assignment_id).returns(assignment_fixer)
        assignment_fixer.expects(:fix).twice
        Timecop.scale(300) { shard_fixer.fix }
      end
    end
  end

  describe "AssignmentFixer" do
    context ':course_fix' do
      before :once do
        generate_submissions({status: "error", student_error: {error_code: 204}})
      end

      describe '#new' do
        it 'finds all broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it 'finds more broken submissions with an older after_time' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe '#fix' do
        it 'creates course and assignment and resubmits the broken submissions' do
          fix_helper(create_course: true, create_or_update_assignment: true)
        end
      end
    end

    context ':resubmit_fix' do
      before :once do
        generate_submissions({status: "error", student_error: {error_code: 216}})
      end

      describe '#new' do
        it 'finds all broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it 'finds more broken submissions with an older after_time' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe '#fix' do
        it 'resubmits the broken submissions' do
          fix_helper(create_course: false, create_or_update_assignment: false)
        end
      end
    end

    context ':assignment_fix' do
      before do
        generate_submissions({status: "error", assignment_error: {error_code: 206}})
      end

      describe '#new' do
        it 'finds all broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it 'finds more broken submissions with an older after_time' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe '#fix' do
        it 'creates the assignment and resubmits the broken submissions' do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ':assignment_exists_fix' do
      before :once do
        generate_submissions({status: "error", assignment_error: {error_code: 419}})
      end

      describe '#new' do
        it 'finds all broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it 'finds more broken submissions with an older after_time' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe '#fix' do
        it 'updates the assignment and resubmits the broken submissions' do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ':assignment_fix without assignment_error key' do
      before :once do
        generate_submissions({status: "error", panda: {error_code: 206}})
      end

      describe '#new' do
        it 'finds all broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it 'finds more broken submissions with an older after_time' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe '#fix' do
        it 'creates the assignment and resubmits the broken submissions' do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ':md5_fix' do
      before :once do
        generate_submissions({status: "error", student_error: {error_code: 204}})
      end

      describe '#fix' do
        it 'saves the assignment and resubmits the broken submissions' do
          turnitin_client = mock
          Turnitin::Client.expects(:new).returns(turnitin_client)

          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          turnitin_client.expects(:createCourse).never
          turnitin_client.expects(:createOrUpdateAssignment).returns({assignment_id: 1})
          Submission.any_instance.expects(:resubmit_to_turnitin).times(2)
          Timecop.scale(300) { fixer.fix(:md5_fix) }
        end
      end
    end

    context ':no_fix' do
      before :once do
        @a1 = generate_assignment
        @s1 = Timecop.travel(2.hours.ago) do
          generate_submission({error_code: 216}, @a1)
        end
        @s2 = Timecop.travel(2.hours.ago) do
          generate_submission({car: "all error in the hood"}, @a1)
        end
        @s3 = Timecop.travel(2.hours.ago) do
          generate_submission({status: "success", student_error: {error_code: 200}}, @a1)
        end
        @s4 = Timecop.travel(5.months.ago) do
          generate_submission({status: "error", student_error: {error_code: 206}}, @a1)
        end
        @s5 = Timecop.travel(2.hours.ago) do
          generate_submission({status: "error", student_error: {error_code: 216}})
        end
        @s6 = generate_submission({status: "error", student_error: {error_code: 206}}, @a1)
      end

      describe '#new' do
        it 'finds no broken submissions' do
          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          expect(fixer.broken_objects).to match_array []
        end
      end

      describe '#fix' do
        it 'does nothing' do
          Turnitin::Client.expects(:new).never
          Submission.any_instance.expects(:resubmit_to_turnitin).never

          fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
          Timecop.scale(300) { fixer.fix }
        end
      end
    end

    def fix_helper(create_course: false, create_or_update_assignment: false)
      if create_course || create_or_update_assignment
        turnitin_client = mock
        Turnitin::Client.expects(:new).returns(turnitin_client)
      else
        Turnitin::Client.expects(:new).never
      end

      fixer = SupportHelpers::Tii::AssignmentFixer.new('email', nil, @a1.id)
      turnitin_client.expects(:createCourse) if create_course
      turnitin_client.expects(:createOrUpdateAssignment).returns({assignment_id: 1}) if create_or_update_assignment
      Submission.any_instance.expects(:resubmit_to_turnitin).times(2)
      Timecop.scale(300) { fixer.fix }
    end
  end

  # TODO: uncomment these once we figure out what the sql queries should
  # like on StuckInPendingFixer and ExpiredAccountFixer
  # describe "StuckInPendingFixer" do
  #   before do
  #     Timecop.travel(2.hours.ago) do
  #       @s1 = generate_submission({last_processed_attempt: 3})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s2 = generate_submission({last_processed_attempt: 3, attachment123456789: nil, status: :pending}, @s1.assignment)
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s3 = generate_submission({last_processed_attempt: 8, attachment408528125: nil, status: :pending, object_id: "312980567"})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s4 = generate_submission
  #     end
  #     Timecop.travel(5.months.ago) do
  #       @s5 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #     end
  #     @s6 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #   end

  #   describe '#new' do
  #     it 'finds all broken assignments' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email')
  #       expect(fixer.broken_objects).to match_array [@s1.id, @s2.id]
  #     end

  #     it 'finds more broken submissions with an older after_time' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email', 6.months.ago)
  #       expect(fixer.broken_objects).to match_array [@s1.id, @s2.id, @s5.id]
  #     end
  #   end

  #   describe '#fix' do
  #     it 'resubmits all broken submissions and checks turnitin status for all stuck submissions' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email')
  #       Submission.any_instance.expects(:resubmit_to_turnitin).times(2)
  #       Submission.any_instance.expects(:check_turnitin_status)
  #       Timecop.scale(300) { fixer.fix }
  #     end
  #   end
  # end

  # describe "ExpiredAccountFixer" do
  #   before do
  #     Timecop.travel(2.hours.ago) do
  #       @s1 = generate_submission({last_processed_attempt: 3})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s2 = generate_submission({status: :pending, status: :error, assignment_error: {error_code: 217}}, @s1.assignment)
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s3 = generate_submission({last_processed_attempt: 8, attachment408528125: nil, status: :pending, object_id: "312980567"})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s4 = generate_submission
  #     end
  #     Timecop.travel(5.months.ago) do
  #       @s5 = generate_submission({status: :pending, status: :error, assignment_error: {error_code: 217}})
  #     end
  #     @s6 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #   end

  #   describe '#new' do
  #     it 'finds all broken assignments' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email')
  #       expect(fixer.broken_objects).to match_array [@s2.id]
  #     end

  #     it 'finds more broken submissions with an older after_time' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email', 6.months.ago)
  #       expect(fixer.broken_objects).to match_array [@s2.id, @s5.id]
  #     end
  #   end

  #   describe '#fix' do
  #     it 'resubmits all expired submissions and does not check turnitin status for any stuck submissions' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email')
  #       Submission.any_instance.expects(:resubmit_to_turnitin)
  #       Submission.any_instance.expects(:check_turnitin_status).never
  #       Timecop.scale(300) { fixer.fix }
  #     end
  #   end
  # end

  let_once(:course) do
    course = course_model
    course.account.turnitin_account_id = 99
    course.account.turnitin_shared_secret = "sekret"
    course.account.turnitin_host = "turn.it.in"
    course.account.save
    course
  end

  def generate_submissions(turnitin_data)
    @a1 = generate_assignment
    @s1 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s2 = Timecop.travel(2.hours.ago) do
      generate_submission({car: "all error in the hood"}, @a1)
    end
    @s3 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s4 = Timecop.travel(5.months.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s5 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data)
    end
    @s6 = generate_submission(turnitin_data, @a1)
  end

  def generate_assignment(settings = {})
    assignment = assignment_model(course: course)
    assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
    settings.each { |k, v| assignment.turnitin_settings[k] = v }
    assignment.save
    assignment
  end

  def generate_submission(settings = {}, assignment = generate_assignment)
    submission = submission_model(assignment: assignment)
    settings.each { |k, v| submission.turnitin_data[k] = v }
    submission.save
    submission
  end
end
