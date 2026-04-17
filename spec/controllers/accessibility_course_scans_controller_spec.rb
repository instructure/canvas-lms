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

describe AccessibilityCourseScansController do
  describe "POST #create" do
    before(:once) do
      @account = Account.default
      @account.enable_feature!(:educator_dashboard)
      @account.enable_feature!(:a11y_checker)
      @account.enable_feature!(:a11y_checker_ga1)
      Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
      @teacher = user_factory(active_all: true)
      @course = course_factory(account: @account, active_all: true)
      @course.enroll_teacher(@teacher, enrollment_state: "active")
    end

    before do
      allow(Accessibility::UserCourseScanService)
        .to receive(:queue_user_courses_scan)
        .and_return(
          Progress.create!(
            tag: Accessibility::UserCourseScanService::SCAN_TAG,
            context: @teacher,
            user: @teacher
          )
        )
    end

    context "authentication" do
      it "requires authentication" do
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_unauthorized
      end
    end

    context "feature flag gating" do
      before { user_session(@teacher) }

      it "returns 403 when educator_dashboard is disabled" do
        @account.disable_feature!(:educator_dashboard)
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      ensure
        @account.enable_feature!(:educator_dashboard)
      end

      it "returns 403 when a11y_checker_account_statistics is disabled" do
        Account.site_admin.disable_feature!(:a11y_checker_account_statistics)
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      ensure
        Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
      end
    end

    context "authorization" do
      before { user_session(@teacher) }

      it "returns 403 when requesting a scan for another user" do
        other_user = user_factory(active_all: true)
        post :create, params: { user_id: other_user.id }, format: :json
        expect(response).to be_forbidden
      end

      it "returns 403 when the user has no active educator enrollments" do
        student = user_factory(active_all: true)
        @course.enroll_student(student, enrollment_state: "active")
        user_session(student)
        post :create, params: { user_id: student.id }, format: :json
        expect(response).to be_forbidden
      end

      it "returns 403 when all educator enrollments are in completed courses" do
        completed_course = course_factory(account: @account, active_all: true)
        completed_course.enroll_teacher(@teacher, enrollment_state: "active")
        completed_course.update!(workflow_state: "completed")

        teacher_no_active = user_factory(active_all: true)
        completed_course.enroll_teacher(teacher_no_active, enrollment_state: "active")

        user_session(teacher_no_active)
        post :create, params: { user_id: teacher_no_active.id }, format: :json
        expect(response).to be_forbidden
      end

      it "allows access via 'self'" do
        user_session(@teacher)
        post :create, params: { user_id: "self" }, format: :json
        expect(response).to be_successful
      end
    end

    context "when the service returns nil" do
      before do
        allow(Accessibility::UserCourseScanService)
          .to receive(:queue_user_courses_scan)
          .and_return(nil)
        user_session(@teacher)
      end

      it "returns 403" do
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "successful scan trigger" do
      before { user_session(@teacher) }

      it "returns 200" do
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
      end

      it "calls UserCourseScanService with the user and root account" do
        post :create, params: { user_id: @teacher.id }, format: :json
        expect(Accessibility::UserCourseScanService)
          .to have_received(:queue_user_courses_scan)
          .with(@teacher, @account)
      end

      it "returns a Progress JSON with the expected fields" do
        post :create, params: { user_id: @teacher.id }, format: :json
        body = response.parsed_body
        expect(body).to include(
          "tag" => Accessibility::UserCourseScanService::SCAN_TAG,
          "workflow_state" => "queued"
        )
        expect(body["id"]).to be_present
        expect(body["url"]).to be_present
      end

      it "returns the existing Progress when a scan is already in progress" do
        existing_progress = Progress.create!(
          tag: Accessibility::UserCourseScanService::SCAN_TAG,
          context: @teacher,
          user: @teacher,
          workflow_state: "running"
        )
        allow(Accessibility::UserCourseScanService)
          .to receive(:queue_user_courses_scan)
          .and_return(existing_progress)

        post :create, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        expect(response.parsed_body["id"]).to eq(existing_progress.id)
        expect(response.parsed_body["workflow_state"]).to eq("running")
      end

      it "includes designer enrollment users" do
        designer = user_factory(active_all: true)
        @course.enroll_designer(designer, enrollment_state: "active")
        designer_progress = Progress.create!(
          tag: Accessibility::UserCourseScanService::SCAN_TAG,
          context: designer,
          user: designer
        )
        allow(Accessibility::UserCourseScanService)
          .to receive(:queue_user_courses_scan)
          .with(designer, @account)
          .and_return(designer_progress)

        user_session(designer)
        post :create, params: { user_id: designer.id }, format: :json
        expect(response).to be_successful
        expect(Accessibility::UserCourseScanService)
          .to have_received(:queue_user_courses_scan)
          .with(designer, @account)
      end
    end
  end
end
