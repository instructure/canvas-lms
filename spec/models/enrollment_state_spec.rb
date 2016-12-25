require_relative "../spec_helper"

describe EnrollmentState do

  describe "#enrollments_needing_calculation" do
    it "should find enrollments that need calculation" do
      course_factory
      normal_enroll = student_in_course(:course => @course)

      invalidated_enroll1 = student_in_course(:course => @course)
      EnrollmentState.where(:enrollment_id => invalidated_enroll1).update_all(:state_is_current => false)
      invalidated_enroll2 = student_in_course(:course => @course)
      EnrollmentState.where(:enrollment_id => invalidated_enroll2).update_all(:access_is_current => false)

      expect(EnrollmentState.enrollments_needing_calculation.to_a).to match_array([invalidated_enroll1, invalidated_enroll2])
    end

    it "should be able to use a scope" do
      course_factory
      enroll = student_in_course(:course => @course)
      EnrollmentState.where(:enrollment_id => enroll).update_all(:state_is_current => false)

      expect(EnrollmentState.enrollments_needing_calculation(Enrollment.where.not(:id => nil)).to_a).to eq [enroll]
      expect(EnrollmentState.enrollments_needing_calculation(Enrollment.where(:id => nil)).to_a).to be_empty
    end
  end

  describe "#process_states_for" do
    before :once do
      course_factory(active_all: true)
      @enrollment = student_in_course(:course => @course)
    end

    it "should reprocess invalidated states" do
      EnrollmentState.where(:enrollment_id => @enrollment).update_all(:state_is_current => false, :state => "somethingelse")

      @enrollment.reload
      EnrollmentState.process_states_for(@enrollment)

      @enrollment.reload
      expect(@enrollment.enrollment_state.state_is_current?).to be_truthy
      expect(@enrollment.enrollment_state.state).to eq 'invited'
    end

    it "should reprocess invalidated accesses" do
      EnrollmentState.where(:enrollment_id => @enrollment).update_all(:access_is_current => false, :restricted_access => true)

      @enrollment.reload
      EnrollmentState.process_states_for(@enrollment)

      @enrollment.reload
      expect(@enrollment.enrollment_state.access_is_current?).to be_truthy
      expect(@enrollment.enrollment_state.restricted_access?).to be_falsey
    end
  end

  describe "state invalidation" do
    it "should invalidate enrollments after enrollment term date change" do
      course_factory(active_all: true)
      other_enroll = student_in_course(:course => @course)

      term = Account.default.enrollment_terms.create!
      course_factory(active_all: true)
      @course.enrollment_term = term
      @course.save!
      term_enroll = student_in_course(:course => @course)

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e != other_enroll}

      term.reload
      end_at = 2.days.ago
      term.end_at = end_at
      term.save!

      term_enroll.reload
      expect(term_enroll.enrollment_state.state_is_current?).to be_falsey

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      state = term_enroll.enrollment_state
      state.ensure_current_state
      expect(state.state).to eq "completed"
      expect(state.state_started_at).to eq end_at
    end

    it "should invalidate enrollments after enrollment term role-specific date change" do
      term = Account.default.enrollment_terms.create!
      course_factory(active_all: true)
      @course.enrollment_term = term
      @course.save!
      other_enroll = teacher_in_course(:course => @course)
      term_enroll = student_in_course(:course => @course)

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e == term_enroll}

      override = term.enrollment_dates_overrides.new(:enrollment_type => "StudentEnrollment", :enrollment_term => term)
      start_at = 2.days.from_now
      override.start_at = start_at
      override.save!

      term_enroll.reload
      expect(term_enroll.enrollment_state.state_is_current?).to be_falsey

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      state = term_enroll.enrollment_state
      state.ensure_current_state
      expect(state.state).to eq "pending_invited"
      expect(state.state_valid_until).to eq start_at
    end

    it "should invalidate enrollments after course date changes" do
      course_factory(active_all: true)
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(:course => @course)
      enroll_state = enroll.enrollment_state

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e.course == @course}

      @course.start_at = 4.days.ago
      ended_at = 3.days.ago
      @course.conclude_at = ended_at
      @course.save!

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq 'completed'
      expect(enroll_state.state_started_at).to eq ended_at
    end

    it "should invalidate enrollments even if they have null lock versions (i.e. already exist before db migration)" do
      course_factory(active_all: true)
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(:course => @course)
      enroll_state = enroll.enrollment_state
      EnrollmentState.where(:enrollment_id => enroll_state).update_all(:lock_version => nil)

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e.course == @course}

      @course.reload
      @course.start_at = 4.days.ago
      ended_at = 3.days.ago
      @course.conclude_at = ended_at
      @course.save!

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq 'completed'
      expect(enroll_state.state_started_at).to eq ended_at
    end

    it "should invalidate enrollments after changing course setting overriding term dates" do
      course_factory(active_all: true)
      enroll = student_in_course(:course => @course)
      enroll_state = enroll.enrollment_state

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e.course == @course}

      @course.start_at = 4.days.ago
      ended_at = 3.days.ago
      @course.conclude_at = ended_at
      @course.save!

      # should not have changed yet - not overriding term dates
      expect(enroll_state.state_is_current?).to be_truthy

      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq 'completed'
      expect(enroll_state.state_started_at).to eq ended_at
    end

    it "should invalidate enrollments after changing course section dates" do
      course_factory(active_all: true)
      other_enroll = student_in_course(:course => @course)

      section = @course.course_sections.create!
      enroll = student_in_course(:course => @course, :section => section)
      enroll_state = enroll.enrollment_state

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e.course_section == section}

      section.restrict_enrollments_to_section_dates = true
      section.save!
      start_at = 1.day.from_now
      section.start_at = start_at
      section.save!

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq 'pending_invited'
      expect(enroll_state.state_valid_until).to eq start_at
    end
  end

  describe "access invalidation" do
    def restrict_view(account, type)
      account.settings[type] = {:value => true, :locked => false}
      account.save!
    end

    it "should invalidate access for future students when account future access settings are changed" do
      course_factory(active_all: true)
      other_enroll = student_in_course(:course => @course)
      other_state = other_enroll.enrollment_state

      future_enroll = student_in_course(:course => @course)
      start_at = 2.days.from_now
      future_enroll.start_at = start_at
      future_enroll.end_at = 3.days.from_now
      future_enroll.save!

      future_state = future_enroll.enrollment_state
      expect(future_state.state).to eq 'pending_invited'
      expect(future_state.state_valid_until).to eq start_at
      expect(future_state.restricted_access?).to be_falsey

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e != other_enroll}

      restrict_view(Account.default, :restrict_student_future_view)

      future_state.reload
      expect(future_state.access_is_current).to be_falsey
      other_state.reload
      expect(other_state.access_is_current).to be_truthy

      future_state.ensure_current_state
      expect(future_state.restricted_access).to be_truthy
      future_enroll.reload
      expect(future_enroll).to be_inactive
    end

    it "should invalidate access for past students when past access settings are changed" do
      course_factory(active_all: true)
      other_enroll = student_in_course(:course => @course)
      other_state = other_enroll.enrollment_state

      sub_account = Account.default.sub_accounts.create!

      course_factory(active_all: true, :account => sub_account)
      @course.start_at = 3.days.ago
      @course.conclude_at = 2.days.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      past_enroll = student_in_course(:course => @course)

      past_state = past_enroll.enrollment_state
      expect(past_state.state).to eq 'completed'

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e != other_enroll}

      restrict_view(Account.default, :restrict_student_past_view)

      past_state.reload
      expect(past_state.access_is_current).to be_falsey
      other_state.reload
      expect(other_state.access_is_current).to be_truthy

      past_state.ensure_current_state
      expect(past_state.restricted_access).to be_truthy
      past_enroll.reload
      expect(past_enroll).to be_inactive
    end

    it "should invalidate access when course access settings change" do
      course_factory(active_all: true)
      @course.start_at = 3.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(:course => @course)
      enroll_state = enroll.enrollment_state

      expect(enroll_state.state).to eq 'pending_invited'

      EnrollmentState.expects(:update_enrollment).at_least_once.with {|e| e.course == @course}
      @course.restrict_student_future_view = true
      @course.save!

      enroll_state.reload
      expect(enroll_state.access_is_current).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.restricted_access).to be_truthy
      enroll.reload
      expect(enroll).to be_inactive
    end
  end

  describe "#recalculate_expired_states" do
    it "should recalculate expired states" do
      course_factory(active_all: true)
      @course.start_at = 3.days.from_now
      end_at = 5.days.from_now
      @course.conclude_at = end_at
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      enroll = student_in_course(:course => @course)
      enroll_state = enroll.enrollment_state
      expect(enroll_state.state).to eq 'pending_invited'

      Timecop.freeze(4.days.from_now) do
        EnrollmentState.recalculate_expired_states
        enroll_state.reload
        expect(enroll_state.state).to eq 'invited'
      end

      Timecop.freeze(6.days.from_now) do
        EnrollmentState.recalculate_expired_states
        enroll_state.reload
        expect(enroll_state.state).to eq 'completed'
      end
    end
  end
end
