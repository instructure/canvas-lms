# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe DataFixup::RecalculateAdminEnrollmentStatesForCourseDatesRegression do
  specs_require_sharding

  subject(:fixup) { operation_shard.activate { described_class.new } }

  let(:operation_shard) { @shard1 }
  let(:buggy_updated_at) { described_class::BUGGY_WINDOW_START + 1.day }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  def create_enrollment(enrollment_type:, term_end_at: 1.month.ago, course_conclude_at: 1.month.from_now, restrict_to_course_dates: true, course_workflow_state: "available")
    account = account_model
    term = account.enrollment_terms.create!(
      name: "Term",
      start_at: 6.months.ago,
      end_at: term_end_at
    )
    course = Course.create!(account:, name: "Course", enrollment_term_id: term.id)
    course.offer! if course_workflow_state == "available"
    course.update!(
      start_at: 1.month.ago,
      conclude_at: course_conclude_at,
      restrict_enrollments_to_course_dates: restrict_to_course_dates
    )
    course.enroll_user(user_factory, enrollment_type, enrollment_state: "active")
  end

  def simulate_buggy_state(enrollment, state: "completed", state_is_current: true, updated_at: buggy_updated_at)
    enrollment.enrollment_state.update_columns(
      state:,
      state_is_current:,
      state_valid_until: nil,
      updated_at:
    )
    # Clear any jobs enqueued by the setup so run_jobs in the test only runs the fixup.
    Delayed::Job.delete_all
  end

  def execute_fixup
    fixup.run
    run_jobs
  end

  describe "#run" do
    it "recalculates state for affected teacher enrollments" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment")
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("active")
    end

    it "recalculates state for affected TA enrollments" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TaEnrollment")
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("active")
    end

    it "recalculates state for affected designer enrollments" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "DesignerEnrollment")
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("active")
    end

    it "leaves student enrollments untouched" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "StudentEnrollment")
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("completed")
    end

    it "skips enrollments updated outside the buggy window" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment")
        simulate_buggy_state(e, updated_at: described_class::BUGGY_WINDOW_END + 1.day)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("completed")
    end

    it "skips courses without restrict_enrollments_to_course_dates" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment", restrict_to_course_dates: false)
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("completed")
    end

    it "skips courses whose term has not ended" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment", term_end_at: 1.month.from_now)
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("completed")
    end

    it "skips courses that have concluded" do
      enrollment = operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment", course_conclude_at: 1.day.ago)
        simulate_buggy_state(e)
        e
      end

      execute_fixup

      expect(enrollment.enrollment_state.reload.state).to eq("completed")
    end

    it "skips enrollment_states already marked not current" do
      operation_shard.activate do
        e = create_enrollment(enrollment_type: "TeacherEnrollment")
        simulate_buggy_state(e, state_is_current: false)
      end

      expect(EnrollmentState).not_to receive(:process_states_for_ids)
      execute_fixup
    end
  end
end
