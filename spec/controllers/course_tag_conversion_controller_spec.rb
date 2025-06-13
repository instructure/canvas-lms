# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe CourseTagConversionController do
  include DifferentiationTag
  before :once do
    @course = course_factory(active_all: true)
    @teacher = teacher_in_course(active_all: true, course: @course).user
    @student = student_in_course(active_all: true, course: @course).user
  end

  describe "PUT 'convert_tag_overrides_to_adhoc_overrides'" do
    context "errors" do
      it "requires proper permissions" do
        user_session(@student)
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("Unauthorized")
      end

      it "returns a conflict if a job is already running" do
        user_session(@teacher)
        Progress.create!(context: @course, tag: DifferentiationTag::DELAYED_JOB_TAG, workflow_state: "running")

        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id }

        expect(response).to have_http_status(:conflict)
        expect(response.body).to include("A tag override conversion job is already in progress for this course.")
      end

      it "returns a bad request if the account allows assignment to differentiation tags" do
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!

        user_session(@teacher)
        put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Cannot perform conversion for courses belonging to accounts that allow assignment via differentiation tags")
      end
    end

    it "starts a conversion job" do
      user_session(@teacher)
      put :convert_tag_overrides_to_adhoc_overrides, params: { course_id: @course.id }

      expect(response).to have_http_status(:no_content)

      job = Progress.last
      expect(job.context).to eq(@course)
      expect(job.tag).to eq(DifferentiationTag::DELAYED_JOB_TAG)
    end
  end

  describe "GET 'conversion_job_status'" do
    context "errors" do
      it "requres proper permissions" do
        user_session(@student)
        get :conversion_job_status, params: { course_id: @course.id }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("Unauthorized")
      end

      it "returns not found if no job exists" do
        user_session(@teacher)
        get :conversion_job_status, params: { course_id: @course.id }

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("No active override conversion job found for this course.")
      end
    end

    it "returns the status of an active job" do
      user_session(@teacher)
      Progress.create!(context: @course, tag: DifferentiationTag::DELAYED_JOB_TAG, workflow_state: "running", completion: 50)

      get :conversion_job_status, params: { course_id: @course.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("workflow_state")
      expect(response.body).to include("running")
      expect(response.body).to include("progress")
      expect(response.body).to include("50")
    end
  end
end
