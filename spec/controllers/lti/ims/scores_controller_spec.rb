#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/concerns/advantage_services_shared_context')
require File.expand_path(File.dirname(__FILE__) + '/concerns/advantage_services_shared_examples')
require_dependency "lti/ims/scores_controller"

module Lti::Ims
  RSpec.describe ScoresController do
    include_context 'advantage services context'

    let(:context) { course }
    let(:assignment) do
      opts = {course: course}
      if tool.present? && tool.use_1_3?
        opts[:submission_types] = 'external_tool'
        opts[:external_tool_tag_attributes] = {
          url: tool.url,
          content_type: 'context_external_tool',
          content_id: tool.id
        }
      end
      assignment_model(opts)
    end
    let(:unknown_context_id) { (Course.maximum(:id) || 0) + 1 }
    let(:line_item) do
      assignment.external_tool? && tool.use_1_3? ?
        assignment.line_items.first :
        line_item_model(course: course)
    end
    let(:user) { student_in_course(course: course, active_all: true).user }
    let(:line_item_id) { line_item.id }
    let(:result) { lti_result_model line_item: line_item, user: user, scoreGiven: nil, scoreMaximum: nil }
    let(:submission) { nil }
    let(:json) { JSON.parse(response.body) }
    let(:access_token_scopes) { 'https://purl.imsglobal.org/spec/lti-ags/scope/score' }
    let(:params_overrides) do
      {
        course_id: context_id,
        line_item_id: line_item_id,
        userId: user.id,
        activityProgress: 'Completed',
        gradingProgress: 'FullyGraded',
        timestamp: Time.zone.now.iso8601(3)
      }
    end
    let(:action) { :create }
    let(:scope_to_remove) { 'https://purl.imsglobal.org/spec/lti-ags/scope/score' }

    describe '#create' do
      it_behaves_like 'advantage services'

      context 'with valid params' do
        it 'returns a valid resultUrl in the body' do
          send_request
          expect(json['resultUrl']).to include 'results'
        end

        context 'with no existing result' do
          it 'creates a new result' do
            expect do
              send_request
            end.to change(Lti::Result, :count).by(1)
          end

          it 'sets the updated_at and created_at to match the params timestamp' do
            send_request
            rslt = Lti::Result.find(json['resultUrl'].split('/').last)
            expect(rslt.created_at).to eq(params_overrides[:timestamp])
            expect(rslt.updated_at).to eq(params_overrides[:timestamp])
          end
        end

        context 'with existing result' do
          context do
            let(:params_overrides) { super().merge(scoreGiven: 5.0, scoreMaximum: line_item.score_maximum) }

            it 'updates result' do
              result
              expect do
                send_request
              end.to change(Lti::Result, :count).by(0)
              expect(result.reload.result_score).to eq 5.0
            end
          end

          it 'sets the updated_at to match the params timestamp' do
            send_request
            rslt = Lti::Result.find(json['resultUrl'].split('/').last)
            expect(rslt.updated_at).to eq(params_overrides[:timestamp])
          end

          context do
            let(:params_overrides) { super().merge(timestamp: 1.day.from_now) }

            it 'does not update the created_at timestamp' do
              result
              send_request
              rslt = Lti::Result.find(json['resultUrl'].split('/').last)
              expect(rslt.created_at).not_to eq(params_overrides[:timestamp])
            end
          end
        end

        context 'when line_item is not an assignment' do
          let(:line_item_no_submission) do
            line_item_model assignment: line_item.assignment, resource_link: line_item.resource_link, tool: tool
          end
          let(:line_item_id) { line_item_no_submission.id }

          context 'with gradingProgress set to FullyGraded or PendingManual' do
            let(:params_overrides) { super().merge(scoreGiven: 10, scoreMaximum: line_item.score_maximum) }

            it 'does not create submission' do
              send_request
              rslt = Lti::Result.find(json['resultUrl'].split('/').last)
              expect(rslt.submission).to be_nil
            end

            context do
              let(:params_overrides) { super().merge(gradingProgress: 'PendingManual') }

              it 'does not create submission with PendingManual' do
                send_request
                rslt = Lti::Result.find(json['resultUrl'].split('/').last)
                expect(rslt.submission).to be_nil
              end
            end
          end
        end

        context 'when line_item is an assignment' do
          let(:result) { lti_result_model line_item: line_item, user: user }

          before { result }

          context do
            let(:params_overrides) { super().merge(scoreGiven: 10, scoreMaximum: line_item.score_maximum) }

            it 'does not create submission' do
              expect do
                send_request
              end.to change(Submission, :count).by(0)
            end
          end

          context 'with no scoreGiven' do
            it 'does not update submission' do
              send_request
              expect(result.submission.reload.score).to be_nil
            end
          end

          context 'with gradingProgress not set to FullyGraded or PendingManual' do
            let(:params_overrides) { super().merge(scoreGiven: 100, gradingProgress: 'Pending') }

            it 'does not update submission' do
              send_request
              expect(result.submission.score).to be_nil
            end
          end

          context 'with gradingProgress set to FullyGraded or PendingManual' do
            let(:params_overrides) { super().merge(scoreGiven: 10, scoreMaximum: line_item.score_maximum) }

            it 'updates submission with FullyGraded' do
              send_request
              expect(result.submission.reload.score).to eq 10.0
            end

            context do
              let(:params_overrides) { super().merge(gradingProgress: 'PendingManual') }

              it 'updates submission with PendingManual' do
                send_request
                expect(result.submission.reload.score).to eq 10.0
              end
            end

            context 'with comment in payload' do
              let(:params_overrides) { super().merge(comment: 'Test coment') }

              it 'creates a new submission_comment' do
                send_request
                expect(result.submission.reload.submission_comments).not_to be_empty
              end
            end

            context 'with submission already graded' do
              let(:result) { lti_result_model line_item: line_item, user: user, result_score: 100, result_maximum: 10 }

              it 'updates submission score' do
                expect(result.submission.score).to eq(100)
                send_request
                expect(result.submission.reload.score).to eq 10.0
              end
            end
          end
        end

        context 'with different scoreMaximum' do
          let(:params_overrides) { super().merge(scoreGiven: 10, scoreMaximum: 100) }

          it 'does not scale the score for the result' do
            result
            send_request
            expect(result.reload.result_score).to eq(params_overrides[:scoreGiven])
          end

          it 'scales the score for the submission to be the correct ratio between points_possible and scoreMaximum' do
            result
            send_request
            expect(result.submission.reload.score).to eq(result.reload.result_score * (line_item.score_maximum / 100))
          end
        end
      end

      context 'with invalid params' do
        context 'when timestamp is before updated_at' do
          let(:params_overrides) { super().merge(timestamp: 1.day.ago.iso8601(3)) }

          it 'does not process request' do
            result
            send_request
            expect(response).to be_bad_request
          end
        end

        context 'when scoreGiven is supplied without scoreMaximum' do
          let(:params_overrides) { super().merge(scoreGiven: 10, scoreMaximum: line_item.score_maximum).except(:scoreMaximum) }

          it 'does not process request' do
            result
            send_request
            expect(response).to have_http_status :unprocessable_entity
          end
        end

        context 'when user_id not found in course' do
          let(:user) { student_in_course(course: course_model, active_all: true).user }

          it 'returns an error unprocessable_entity' do
            send_request
            expect(response).to have_http_status :unprocessable_entity
          end
        end

        context 'when user_id is not a student in course' do
          let(:user) { ta_in_course(course: course, active_all: true).user }

          it 'returns an error unprocessable_entity' do
            send_request
            expect(response).to have_http_status :unprocessable_entity
          end
        end
      end
    end
  end
end
