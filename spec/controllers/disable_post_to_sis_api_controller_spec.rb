# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe DisablePostToSisApiController do
  describe "PUT disable_post_to_sis" do
    let(:account) { account_model }
    let(:course) { course_model(account:, workflow_state: "available") }
    let(:admin) { account_admin_user(account:) }

    before do
      bypass_rescue
      user_session(admin)
    end

    it "works even when post_to_sis/new_sis_integrations disabled" do
      assignment = assignment_model(course:,
                                    post_to_sis: true,
                                    workflow_state: "published")

      put "disable_post_to_sis", params: { course_id: course.id }

      expect(response).to be_successful
      expect(assignment.reload.post_to_sis).to be false
    end

    context "with new_sis_integrations enabled" do
      before do
        account.enable_feature!(:new_sis_integrations)
      end

      it "responds with 200" do
        put "disable_post_to_sis", params: { course_id: course.id }

        expect(response).to have_http_status :no_content
        expect(response).to be_successful
      end

      it "disables assignments with post_to_sis enabled" do
        assignment = assignment_model(course:,
                                      post_to_sis: true,
                                      workflow_state: "published")

        put "disable_post_to_sis", params: { course_id: course.id }
        assignment = Assignment.find(assignment.id)

        expect(response).to have_http_status :no_content
        expect(response).to be_successful
        expect(assignment.post_to_sis).to be_falsey
      end

      context "with assignments in a grading_period" do
        let(:grading_period_group) do
          group = account.grading_period_groups.create!(title: "A Group")
          term = course.enrollment_term
          group.enrollment_terms << term
          group
        end

        let(:grading_period) do
          grading_period_group.grading_periods.create!(
            title: "Too Much Tuna",
            start_date: 2.months.from_now(Time.zone.now),
            end_date: 3.months.from_now(Time.zone.now)
          )
        end

        it "responds with 400 when grading period does not exist" do
          put "disable_post_to_sis", params: { course_id: course.id,
                                               grading_period_id: 789_465_789 }

          parsed_json = json_parse(response.body)
          expect(response).to have_http_status :bad_request
          expect(parsed_json["code"]).to eq "not_found"
        end

        it "disables assignments with post_to_sis enabled based on grading period" do
          assignment = assignment_model(course:,
                                        post_to_sis: true,
                                        workflow_state: "published",
                                        due_at: grading_period.start_date + 1.minute)

          put "disable_post_to_sis", params: { course_id: course.id,
                                               grading_period_id: grading_period.id }
          assignment = Assignment.find(assignment.id)

          expect(response).to have_http_status :no_content
          expect(response).to be_successful
          expect(assignment.post_to_sis).to be_falsey
        end
      end
    end
  end
end
