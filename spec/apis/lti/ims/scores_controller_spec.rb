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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/scores_controller"

module Lti::Ims
  RSpec.describe ScoresController, type: :request do
    let_once(:line_item) { line_item_model with_resource_link: true }
    let_once(:user) { student_in_course(course: course, active_all: true).user }
    let(:course) { line_item.assignment.course }
    let(:line_item_id) { line_item.id }
    let(:url) do
      Rails.application.routes.url_helpers.lti_result_create_path(course_id: course.id, line_item_id: line_item_id)
    end
    let(:result) { lti_result_model line_item: line_item, user: user, scoreGiven: nil, scoreMaximum: nil }
    let(:submission) { nil }
    let(:json) { JSON.parse(response.body) }
    let(:create_params) do
      {
        userId: user.id,
        activityProgress: 'Completed',
        gradingProgress: 'FullyGraded',
        timestamp: Time.zone.now.iso8601(3)
      }
    end
    let(:create_params_with_score) do
      create_params.merge(scoreGiven: 10, scoreMaximum: line_item.score_maximum)
    end

    describe '#create' do
      context 'with valid params' do
        it 'returns a valid resultUrl in the body' do
          post url, params: create_params
          get json['resultUrl']
          expect(json).not_to be_empty
        end


        context 'with no existing result' do
          it 'creates a new result' do
            expect do
              post url, params: create_params
            end.to change(Lti::Result, :count).by(1)
          end

          it 'sets the updated_at and created_at to match the params timestamp' do
            post url, params: create_params
            rslt = Lti::Result.find(json['resultUrl'].split('/').last)
            expect(rslt.created_at).to eq(create_params[:timestamp])
            expect(rslt.updated_at).to eq(create_params[:timestamp])
          end
        end

        context 'with existing result' do
          it 'updates result' do
            result
            expect do
              post url, params: create_params_with_score.merge(scoreGiven: 5.0)
            end.to change(Lti::Result, :count).by(0)
            expect(result.reload.result_score).to eq 5.0
          end

          it 'sets the updated_at to match the params timestamp' do
            post url, params: create_params
            rslt = Lti::Result.find(json['resultUrl'].split('/').last)
            expect(rslt.updated_at).to eq(create_params[:timestamp])
          end

          it 'does not update the created_at timestamp' do
            result
            post url, params: create_params.merge(timestamp: 1.day.from_now)
            rslt = Lti::Result.find(json['resultUrl'].split('/').last)
            expect(rslt.created_at).not_to eq(create_params[:timestamp])
          end
        end

        context 'when line_item is not an assignment' do
          let(:line_item_no_submission) do
            line_item_model assignment: line_item.assignment, resource_link: line_item.resource_link
          end
          let(:line_item_id) { line_item_no_submission.id }

          context 'with gradingProgress set to FullyGraded or PendingManual' do
            it 'does not create submission' do
              post url, params: create_params_with_score
              rslt = Lti::Result.find(json['resultUrl'].split('/').last)
              expect(rslt.submission).to be_nil
            end

            it 'does not create submission with PendingManual' do
              post url, params: create_params_with_score.merge(gradingProgress: 'PendingManual')
              rslt = Lti::Result.find(json['resultUrl'].split('/').last)
              expect(rslt.submission).to be_nil
            end
          end
        end

        context 'when line_item is an assignment' do
          let(:result) { lti_result_model line_item: line_item, user: user }

          before { result }

          it 'does not create submission' do
            expect do
              post url, params: create_params_with_score
            end.to change(Submission, :count).by(0)
          end

          context 'with no scoreGiven' do
            it 'does not update submission' do
              post url, params: create_params
              expect(result.submission.reload.score).to be_nil
            end
          end

          context 'with gradingProgress not set to FullyGraded or PendingManual' do
            it 'does not update submission' do
              post url, params: create_params_with_score.merge(scoreGiven: 100, gradingProgress: 'Pending')
              expect(result.submission.score).to be_nil
            end
          end

          context 'with gradingProgress set to FullyGraded or PendingManual' do
            it 'updates submission with FullyGraded' do
              post url, params: create_params_with_score
              expect(result.submission.reload.score).to eq 10.0
            end

            it 'updates submission with PendingManual' do
              post url, params: create_params_with_score.merge(gradingProgress: 'PendingManual')
              expect(result.submission.reload.score).to eq 10.0
            end

            context 'with comment in payload' do
              it 'creates a new submission_comment' do
                post url, params: create_params_with_score.merge(comment: 'Test coment')
                expect(result.submission.reload.submission_comments).not_to be_empty
              end
            end

            context 'with submission already graded' do
              let(:result) { lti_result_model line_item: line_item, user: user, result_score: 100, result_maximum: 10 }

              it 'updates submission score' do
                expect(result.submission.score).to eq(100)
                post url, params: create_params_with_score
                expect(result.submission.reload.score).to eq 10.0
              end
            end
          end
        end

        context 'with different scoreMaximum' do
          it 'does not scale the score for the result' do
            result
            post url, params: create_params_with_score.merge(scoreMaximum: 100)
            expect(result.reload.result_score).to eq(create_params_with_score[:scoreGiven])
          end

          it 'scales the score for the submission to be the correct ratio between points_possible and scoreMaximum' do
            result
            post url, params: create_params_with_score.merge(scoreMaximum: 100)
            expect(result.submission.reload.score).to eq(result.reload.result_score * (line_item.score_maximum / 100))
          end
        end
      end

      context 'with invalid params' do
        context 'when timestamp is before updated_at' do
          it 'does not process request' do
            result
            post url, params: create_params.merge(timestamp: 1.day.ago.iso8601(3))
            expect(response).to be_bad_request
          end
        end

        context 'when scoreGiven is supplied without scoreMaximum' do
          it 'does not process request' do
            result
            post url, params: create_params_with_score.except!(:scoreMaximum)
            expect(response).to have_http_status :unprocessable_entity
          end
        end

        context 'when user_id not found in course' do
          let(:user) { student_in_course(course: course_model, active_all: true).user }

          it 'returns an error unprocessable_entity' do
            post url, params: create_params
            expect(response).to have_http_status :unprocessable_entity
          end
        end

        context 'when user_id is not a student in course' do
          let(:user) { ta_in_course(course: course, active_all: true).user }

          it 'returns an error unprocessable_entity' do
            post url, params: create_params
            expect(response).to have_http_status :unprocessable_entity
          end
        end
      end
    end
  end
end
