# frozen_string_literal: true

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

describe Accessibility::UserCourseScanService do
  let(:account) { Account.default }
  let(:teacher) { user_model }
  let!(:course) do
    course = course_model(account:)
    course.enroll_teacher(teacher, enrollment_state: :active)
    course
  end

  before do
    account.enable_feature!(:educator_dashboard)
    Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
    account.enable_feature!(:a11y_checker)
    account.enable_feature!(:a11y_checker_ga1)
  end

  describe ".queue_user_courses_scan" do
    context "when educator_dashboard flag is disabled" do
      before { account.disable_feature!(:educator_dashboard) }

      it "returns nil" do
        expect(described_class.queue_user_courses_scan(teacher, account)).to be_nil
      end

      it "does not create a Progress record" do
        expect { described_class.queue_user_courses_scan(teacher, account) }
          .not_to change { Progress.count }
      end
    end

    context "when a11y_checker_account_statistics is disabled" do
      before { Account.site_admin.disable_feature!(:a11y_checker_account_statistics) }

      it "returns nil" do
        expect(described_class.queue_user_courses_scan(teacher, account)).to be_nil
      end

      it "does not create a Progress record" do
        expect { described_class.queue_user_courses_scan(teacher, account) }
          .not_to change { Progress.count }
      end
    end

    context "when a11y_checker_account_statistics is enabled but a11y_checker is disabled" do
      before { account.disable_feature!(:a11y_checker) }

      it "returns nil" do
        expect(described_class.queue_user_courses_scan(teacher, account)).to be_nil
      end
    end

    context "when required flags are enabled" do
      it "creates a Progress record with the correct tag and context" do
        expect { described_class.queue_user_courses_scan(teacher, account) }
          .to change { Progress.where(tag: described_class::SCAN_TAG, context: teacher).count }.by(1)
      end

      it "sets the user on the Progress record" do
        progress = described_class.queue_user_courses_scan(teacher, account)
        expect(progress.user).to eq(teacher)
      end

      it "returns the new Progress record" do
        result = described_class.queue_user_courses_scan(teacher, account)
        expect(result).to be_a(Progress)
        expect(result.tag).to eq(described_class::SCAN_TAG)
      end

      it "enqueues the job with the correct n_strand and singleton" do
        mock_progress = instance_double(Progress)
        allow(Progress).to receive(:create!).and_return(mock_progress)

        expect(mock_progress).to receive(:process_job).with(
          described_class,
          :perform_scan,
          hash_including(
            n_strand: [described_class::SCAN_TAG, account.global_id],
            singleton: "#{described_class::SCAN_TAG}_#{teacher.global_id}",
            on_conflict: :overwrite
          ),
          teacher.id,
          account.id
        )

        described_class.queue_user_courses_scan(teacher, account)
      end

      context "when a scan is already queued" do
        let!(:existing_progress) do
          Progress.create!(
            tag: described_class::SCAN_TAG,
            context: teacher,
            user: teacher,
            workflow_state: "queued"
          )
        end

        it "does not create a new Progress" do
          expect { described_class.queue_user_courses_scan(teacher, account) }
            .not_to change { Progress.where(tag: described_class::SCAN_TAG, context: teacher).count }
        end

        it "returns the existing pending progress" do
          result = described_class.queue_user_courses_scan(teacher, account)
          expect(result).to eq(existing_progress)
        end
      end

      context "when a scan is already running" do
        let!(:existing_progress) do
          Progress.create!(
            tag: described_class::SCAN_TAG,
            context: teacher,
            user: teacher,
            workflow_state: "running"
          )
        end

        it "does not create a new Progress" do
          expect { described_class.queue_user_courses_scan(teacher, account) }
            .not_to change { Progress.where(tag: described_class::SCAN_TAG, context: teacher).count }
        end

        it "returns the existing running progress" do
          result = described_class.queue_user_courses_scan(teacher, account)
          expect(result).to eq(existing_progress)
        end
      end

      context "when a previous scan has completed" do
        before do
          Progress.create!(
            tag: described_class::SCAN_TAG,
            context: teacher,
            user: teacher,
            workflow_state: "completed"
          )
        end

        it "creates a new Progress record" do
          expect { described_class.queue_user_courses_scan(teacher, account) }
            .to change { Progress.where(tag: described_class::SCAN_TAG, context: teacher).count }.by(1)
        end
      end

      context "when a previous scan has failed" do
        before do
          Progress.create!(
            tag: described_class::SCAN_TAG,
            context: teacher,
            user: teacher,
            workflow_state: "failed"
          )
        end

        it "creates a new Progress record" do
          expect { described_class.queue_user_courses_scan(teacher, account) }
            .to change { Progress.where(tag: described_class::SCAN_TAG, context: teacher).count }.by(1)
        end
      end
    end
  end

  describe ".perform_scan" do
    let(:progress) do
      Progress.create!(
        tag: described_class::SCAN_TAG,
        context: teacher,
        user: teacher
      ).tap(&:start!)
    end

    before do
      service_double = instance_double(described_class, scan_user_courses: nil)
      allow(described_class).to receive(:new).and_return(service_double)
    end

    it "calls scan_user_courses on the service instance" do
      service_instance = instance_double(described_class, scan_user_courses: nil)
      allow(described_class).to receive(:new).with(user: teacher, root_account: account).and_return(service_instance)

      described_class.perform_scan(progress, teacher.id, account.id)

      expect(service_instance).to have_received(:scan_user_courses)
    end

    it "completes the progress on success" do
      described_class.perform_scan(progress, teacher.id, account.id)
      expect(progress.reload).to be_completed
    end

    context "when an error occurs" do
      before do
        service_double = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:scan_user_courses).and_raise(StandardError, "unexpected failure")
      end

      it "marks the progress as failed" do
        expect { described_class.perform_scan(progress, teacher.id, account.id) }
          .to raise_error(StandardError, "unexpected failure")
        expect(progress.reload).to be_failed
      end

      it "logs to ErrorReport" do
        expect(ErrorReport).to receive(:log_exception).with(
          described_class::ERROR_TAG,
          instance_of(StandardError),
          hash_including(progress_id: progress.id, user_id: teacher.id)
        )
        expect { described_class.perform_scan(progress, teacher.id, account.id) }
          .to raise_error(StandardError)
      end

      it "captures to Sentry" do
        expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
        expect(Sentry).to receive(:capture_exception).with(instance_of(StandardError), level: :error)
        expect { described_class.perform_scan(progress, teacher.id, account.id) }
          .to raise_error(StandardError)
      end
    end
  end

  describe "#scan_user_courses" do
    subject(:service) { described_class.new(user: teacher, root_account: account) }

    context "with a11y_checker_ga1 enabled" do
      before { account.enable_feature!(:a11y_checker_ga1) }

      it "queues a scan for each active teacher course" do
        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        service.scan_user_courses
      end

      it "skips completed courses" do
        completed_course = course_model(account:, workflow_state: "completed")
        completed_course.enroll_teacher(teacher, enrollment_state: :active)

        expect(Accessibility::CourseScanService).not_to receive(:queue_course_scan).with(completed_course)
        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        service.scan_user_courses
      end

      it "skips deleted courses" do
        deleted_course = course_model(account:)
        deleted_course.enroll_teacher(teacher, enrollment_state: :active)
        deleted_course.update!(workflow_state: "deleted")

        expect(Accessibility::CourseScanService).not_to receive(:queue_course_scan).with(deleted_course)
        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        service.scan_user_courses
      end

      it "skips courses where the user is only a student" do
        student_course = course_model(account:)
        student_course.enroll_student(teacher, enrollment_state: :active)

        expect(Accessibility::CourseScanService).not_to receive(:queue_course_scan).with(student_course)
        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        service.scan_user_courses
      end

      it "queues a scan for designer courses" do
        designer_course = course_model(account:)
        designer_course.enroll_designer(teacher, enrollment_state: :active)

        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(designer_course)
        service.scan_user_courses
      end
    end

    context "with a11y_checker_ga1 disabled" do
      before do
        account.disable_feature!(:a11y_checker_ga1)
        account.enable_feature!(:a11y_checker)
        Account.site_admin.enable_feature!(:a11y_checker_eap)
        course.enable_feature!(:a11y_checker_eap)
      end

      it "queues a scan only for a11y-enabled courses" do
        other_course = course_model(account:)
        other_course.enroll_teacher(teacher, enrollment_state: :active)
        # other_course does not have a11y_checker_eap enabled

        expect(Accessibility::CourseScanService).to receive(:queue_course_scan).with(course)
        expect(Accessibility::CourseScanService).not_to receive(:queue_course_scan).with(other_course)
        service.scan_user_courses
      end
    end

    context "when a course scan raises ScanLimitExceededError" do
      before do
        allow(Accessibility::CourseScanService)
          .to receive(:queue_course_scan)
          .and_raise(Accessibility::CourseScanService::ScanLimitExceededError)
      end

      it "does not raise" do
        expect { service.scan_user_courses }.not_to raise_error
      end

      it "logs to ErrorReport" do
        expect(ErrorReport).to receive(:log_exception).with(
          described_class::ERROR_TAG,
          an_instance_of(Accessibility::CourseScanService::ScanLimitExceededError),
          hash_including(course_id: course.id)
        )
        service.scan_user_courses
      end

      it "does not capture to Sentry" do
        expect(Sentry).not_to receive(:capture_exception)
        service.scan_user_courses
      end
    end

    context "when a course scan raises an unexpected error" do
      let!(:second_course) do
        c = course_model(account:)
        c.enroll_teacher(teacher, enrollment_state: :active)
        c
      end

      before do
        call_count = 0
        allow(Accessibility::CourseScanService).to receive(:queue_course_scan) do
          call_count += 1
          raise StandardError, "scan failed" if call_count == 1
        end
      end

      it "continues scanning remaining courses" do
        service.scan_user_courses
        expect(Accessibility::CourseScanService).to have_received(:queue_course_scan).twice
      end

      it "logs to ErrorReport for the failed course" do
        expect(ErrorReport).to receive(:log_exception).with(
          described_class::ERROR_TAG,
          an_instance_of(StandardError),
          hash_including(:course_id)
        )
        service.scan_user_courses
      end

      it "captures to Sentry at warning level" do
        expect(Sentry).to receive(:capture_exception).with(
          an_instance_of(StandardError),
          level: :warning
        )
        service.scan_user_courses
      end
    end
  end
end
