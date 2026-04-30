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

describe AccessibilityCourseStatisticsController do
  describe "GET #index" do
    before(:once) do
      @account = Account.default
      @account.enable_feature!(:educator_dashboard)
      @account.enable_feature!(:a11y_checker)
      @account.enable_feature!(:a11y_checker_ga1)
      Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
      @teacher = user_factory(active_all: true)
      @course1 = course_factory(account: @account, active_all: true)
      @course2 = course_factory(account: @account, active_all: true)
      @course1.enroll_teacher(@teacher, enrollment_state: "active")
      @course2.enroll_teacher(@teacher, enrollment_state: "active")
    end

    context "authorization" do
      it "requires authentication" do
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_unauthorized
      end

      it "returns 403 when educator_dashboard feature flag is disabled" do
        @account.disable_feature!(:educator_dashboard)
        user_session(@teacher)
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      end

      it "returns 403 when a11y_checker_account_statistics is not enabled" do
        Account.site_admin.disable_feature!(:a11y_checker_account_statistics)
        user_session(@teacher)
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      end

      it "returns 403 when user_id resolves to a different user" do
        other_user = user_factory(active_all: true)
        user_session(other_user)
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_forbidden
      end

      it "returns 403 when the user has no teacher or designer enrollments" do
        student = user_factory(active_all: true)
        @course1.enroll_student(student, enrollment_state: "active")
        user_session(student)
        get :index, params: { user_id: student.id }, format: :json
        expect(response).to be_forbidden
      end

      it "allows a user to access their own data" do
        user_session(@teacher)
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
      end

      it "allows a user to access their own data via 'self'" do
        user_session(@teacher)
        get :index, params: { user_id: "self" }, format: :json
        expect(response).to be_successful
      end
    end

    context "data retrieval" do
      before do
        user_session(@teacher)
      end

      it "returns an empty array when no active statistics exist" do
        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        expect(response.parsed_body).to eq([])
      end

      it "includes course_name and course_code when include[]=course_details" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )

        get :index, params: { user_id: @teacher.id, include: ["course_details"] }, format: :json
        expect(response).to be_successful
        row = response.parsed_body.first
        expect(row["course_name"]).to eq(@course1.name)
        expect(row["course_code"]).to eq(@course1.course_code)
      end

      it "omits course_name and course_code by default" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        row = response.parsed_body.first
        expect(row).not_to have_key("course_name")
        expect(row).not_to have_key("course_code")
        expect(row).not_to have_key("published")
      end

      it "returns active statistics for the teacher's courses" do
        stat1 = AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5,
          resolved_issue_count: 3,
          closed_issue_count: 2
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "active",
          active_issue_count: 10,
          resolved_issue_count: 7,
          closed_issue_count: 4
        )

        get :index, params: { user_id: @teacher.id, include: ["closed_issue_count"] }, format: :json
        expect(response).to be_successful
        data = response.parsed_body
        expect(data.length).to eq(2)

        course_ids = data.pluck("course_id")
        expect(course_ids).to contain_exactly(@course1.id, @course2.id)

        row1 = data.find { |r| r["course_id"] == stat1.course_id }
        expect(row1["active_issue_count"]).to eq(5)
        expect(row1["resolved_issue_count"]).to eq(3)
        expect(row1["closed_issue_count"]).to eq(2)
      end

      it "includes closed_issue_count when include[]=closed_issue_count" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 1,
          resolved_issue_count: 1,
          closed_issue_count: 9
        )

        get :index, params: { user_id: @teacher.id, include: ["closed_issue_count"] }, format: :json
        expect(response).to be_successful
        row = response.parsed_body.first
        expect(row).to have_key("closed_issue_count")
        expect(row["closed_issue_count"]).to eq(9)
      end

      it "omits closed_issue_count by default" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 1,
          resolved_issue_count: 1,
          closed_issue_count: 9
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        row = response.parsed_body.first
        expect(row).not_to have_key("closed_issue_count")
      end

      it "ignores unknown include[] values" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )

        get :index, params: { user_id: @teacher.id, include: ["bogus"] }, format: :json
        expect(response).to be_successful
        row = response.parsed_body.first
        expect(row).not_to have_key("closed_issue_count")
        expect(row).not_to have_key("course_name")
      end

      it "excludes statistics with non-active workflow states" do
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "in_progress",
          active_issue_count: 10
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        data = response.parsed_body
        expect(data.length).to eq(1)
        expect(data.first["course_id"]).to eq(@course1.id)
      end

      it "excludes courses where the user is not a teacher or designer" do
        other_course = course_factory(account: @account, active_course: true)
        AccessibilityCourseStatistic.create!(
          course: other_course,
          workflow_state: "active",
          active_issue_count: 99
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).not_to include(other_course.id)
      end

      it "excludes courses where a11y_checker is not enabled" do
        @account.disable_feature!(:a11y_checker_ga1)
        @course1.enable_feature!(:a11y_checker_eap)
        # course2 intentionally has no a11y_checker_eap

        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "active",
          active_issue_count: 10
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).to contain_exactly(@course1.id)
        expect(course_ids).not_to include(@course2.id)
      end

      it "includes all teacher courses when a11y_checker_ga1 is enabled" do
        # ga1 is on (set in before(:once)), so all courses are eligible
        # without needing the per-course a11y_checker_eap flag
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "active",
          active_issue_count: 10
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).to contain_exactly(@course1.id, @course2.id)
      end

      it "includes courses where the user has a DesignerEnrollment" do
        designer_course = course_factory(account: @account, active_course: true)
        designer_course.enroll_designer(@teacher, enrollment_state: "active")
        stat = AccessibilityCourseStatistic.create!(
          course: designer_course,
          workflow_state: "active",
          active_issue_count: 3
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).to include(stat.course_id)
      end

      it "excludes completed (concluded) courses" do
        @course1.update!(workflow_state: "completed")
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "active",
          active_issue_count: 10
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).not_to include(@course1.id)
        expect(course_ids).to include(@course2.id)
      end

      it "excludes deleted courses" do
        @course1.update!(workflow_state: "deleted")
        AccessibilityCourseStatistic.create!(
          course: @course1,
          workflow_state: "active",
          active_issue_count: 5
        )
        AccessibilityCourseStatistic.create!(
          course: @course2,
          workflow_state: "active",
          active_issue_count: 10
        )

        get :index, params: { user_id: @teacher.id }, format: :json
        expect(response).to be_successful
        course_ids = response.parsed_body.pluck("course_id")
        expect(course_ids).not_to include(@course1.id)
        expect(course_ids).to include(@course2.id)
      end
    end
  end
end
