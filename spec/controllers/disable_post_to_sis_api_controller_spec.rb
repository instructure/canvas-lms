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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DisablePostToSisApiController do
  describe "PUT disable_post_to_sis" do
    let(:account) {account_model}
    let(:course) {course_model(account: account, workflow_state: 'available')}
    let(:admin) {account_admin_user(account: account)}

    before do
      bypass_rescue
      user_session(admin)
    end

    it 'works even when post_to_sis/new_sis_integrations disabled' do
      assignment = assignment_model(course: course,
                                    post_to_sis: true,
                                    workflow_state: 'published')

      put 'disable_post_to_sis', params: {course_id: course.id}

      expect(response).to be_success
      expect(assignment.reload.post_to_sis).to eq false
    end

    context 'with bulk_sis_grade_export and new_sis_integrations enabled' do
      before do
        account.enable_feature!(:bulk_sis_grade_export)
        account.enable_feature!(:new_sis_integrations)
      end

      it 'responds with 200' do
        put 'disable_post_to_sis', params: {course_id: course.id}

        expect(response.code).to eq "204"
        expect(response.success?).to be_truthy
      end

      it 'disables assignments with post_to_sis enabled' do
        assignment = assignment_model(course: course,
                                      post_to_sis: true,
                                      workflow_state: 'published')

        put 'disable_post_to_sis', params: {course_id: course.id}
        assignment = Assignment.find(assignment.id)

        expect(response.code).to eq "204"
        expect(response.success?).to be_truthy
        expect(assignment.post_to_sis).to be_falsey
      end

      context 'with assignments in a grading_period' do
        let(:grading_period_group) do
          group = account.grading_period_groups.create!(title: "A Group")
          term = course.enrollment_term
          group.enrollment_terms << term
          group
        end

        let(:grading_period) do
            grading_period_group.grading_periods.create!(
              title:      'Too Much Tuna',
              start_date: 2.months.from_now(Time.zone.now),
              end_date:   3.months.from_now(Time.zone.now)
            )
        end

        it 'responds with 400 when grading period does not exist' do
          put 'disable_post_to_sis', params: {course_id: course.id,
                                     grading_period_id: 789465789}

          parsed_json = json_parse(response.body)
          expect(response.code).to eq "400"
          expect(parsed_json['code']).to eq 'not_found'
        end

        it 'disables assignments with post_to_sis enabled based on grading period' do
          assignment = assignment_model(course: course,
                                        post_to_sis: true,
                                        workflow_state: 'published',
                                        due_at: grading_period.start_date + 1.minute)

          put 'disable_post_to_sis', params: {course_id: course.id,
                                     grading_period_id: grading_period.id}
          assignment = Assignment.find(assignment.id)

          expect(response.code).to eq "204"
          expect(response.success?).to be_truthy
          expect(assignment.post_to_sis).to be_falsey
        end
      end
    end
  end
end
