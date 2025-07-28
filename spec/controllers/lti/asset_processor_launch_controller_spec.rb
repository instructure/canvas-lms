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
#

module Lti
  describe AssetProcessorLaunchController do
    include Lti::RedisMessageClient

    before :once do
      course_with_teacher(active_all: true)
    end

    let(:asset_processor) do
      lti_asset_processor_model({
                                  assignment_opts: { course: @course },
                                  external_tool_context: @course
                                })
    end

    let(:decoded_jwt) do
      lti_message_hint = response.body.match(/<input[^>]*name="lti_message_hint"[^>]*value="([^"]*)"/)[1]
      JSON::JWT.decode(lti_message_hint, :skip_verification)
    end

    let(:id_token_decoded) do
      launch = fetch_and_delete_launch(@course, decoded_jwt["verifier"])
      JSON.parse(launch)["post_payload"]
    end

    describe "#launch_settings" do
      subject { get :launch_settings, params: { asset_processor_id: asset_processor.id } }

      context "with feature disabled" do
        before do
          asset_processor.assignment.context.root_account.disable_feature!(:lti_asset_processor)
        end

        it "requires feature enabled" do
          subject
          expect(response).to have_http_status :not_found
        end
      end

      context "with feature enabled" do
        render_views
        before do
          asset_processor.assignment.context.root_account.enable_feature!(:lti_asset_processor)
        end

        context "with proper rights (user belongs to course)" do
          before do
            user_session(@teacher)
          end

          it "returns 200" do
            subject
            expect(response).to have_http_status :ok
            expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq("LtiAssetProcessorSettingsRequest")
            expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/activity"]["id"]).to eq(asset_processor.assignment.lti_context_id)
          end

          context "logging" do
            before do
              allow(Lti::LogService).to receive(:new) do
                double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
              end
            end

            it "logs launch" do
              expect(Lti::LogService).to receive(:new).with(
                tool: asset_processor.context_external_tool,
                context: @course,
                user: @teacher,
                session_id: nil,
                launch_type: :content_item,
                launch_url: asset_processor.url,
                message_type: "LtiAssetProcessorSettingsRequest"
              )
              subject
            end
          end
        end

        context "when user has no manage_grade rights (aka student in course)" do
          before do
            @student = student_in_course(course: @course, active_all: true).user
            user_session(@student)
          end

          it "returns unauthorized" do
            subject
            expect(response).to have_http_status :unauthorized
          end
        end

        context "without proper rights" do
          it "returns redirect" do
            subject
            expect(response).to redirect_to "/login"
          end
        end
      end

      context "with invalid asset_processor_id" do
        subject { get :launch_settings, params: { asset_processor_id: 0 } }

        it "returns 404" do
          subject
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#launch_report" do
      let(:asset_report) { lti_asset_report_model(lti_asset_processor_id: asset_processor.id) }

      subject { get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report } }

      context "with feature disabled" do
        before do
          asset_processor.assignment.context.root_account.disable_feature!(:lti_asset_processor)
        end

        it "requires feature enabled" do
          subject
          expect(response).to have_http_status :not_found
        end
      end

      context "with feature enabled" do
        render_views
        before do
          asset_processor.assignment.context.root_account.enable_feature!(:lti_asset_processor)
          user_session(@teacher)
        end

        it "redirects 200" do
          subject
          expect(response).to have_http_status :ok
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq("LtiReportReviewRequest")
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/activity"]["id"]).to eq(asset_processor.assignment.lti_context_id)
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/for_user"]["user_id"]).to eq(@teacher.lti_id)
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/assetreport_type"]).to eq(asset_report.report_type)
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/submission"]["id"]).to eq(asset_report.asset.submission.lti_attempt_id)
        end

        context "with specific submission_attempt" do
          let(:submission_attempt) { 5 }

          subject { get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report, submission_attempt: } }

          it "contains valid submission lti_attempt_id" do
            subject
            expect(response).to have_http_status :ok
            expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/submission"]["id"]).to eq(asset_report.asset.submission.lti_attempt_id(submission_attempt))
          end
        end

        context "with invalid asset_processor_id" do
          subject { get :launch_report, params: { asset_processor_id: 0, report_id: asset_report } }

          it "returns 404" do
            subject
            expect(response).to have_http_status :not_found
          end
        end

        context "with invalid asset_report_id" do
          subject { get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: 0 } }

          it "returns 404" do
            subject
            expect(response).to have_http_status :not_found
          end
        end

        context "with asset_report that does not belongs to asset_processor" do
          let(:asset_report) { lti_asset_report_model }

          subject { get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report.id } }

          it "returns 400" do
            subject
            expect(response).to have_http_status :bad_request
          end
        end

        context "when launched by the owner student" do
          let(:student) { student_in_course(course: @course, active_all: true).user }
          let(:submission) { submission_model(user: student, assignment: asset_processor.assignment) }
          let(:asset) { lti_asset_model(submission:) }
          let(:asset_report) do
            lti_asset_report_model(
              lti_asset_processor_id: asset_processor.id,
              asset:,
              visible_to_owner:
            )
          end

          context "when report is visible to owner" do
            let(:visible_to_owner) { true }

            it "allows student to view their own report" do
              user_session(student)
              get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report.id }
              expect(response).to have_http_status :ok
            end
          end

          context "when report is not visible to owner" do
            let(:visible_to_owner) { false }

            it "prevents student from viewing the report" do
              user_session(student)
              get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report.id }
              expect(response).to have_http_status :unauthorized
            end
          end
        end

        context "when launched by teacher with visible_to_owner false" do
          let(:student) { student_in_course(course: @course, active_all: true).user }
          let(:submission) { submission_model(user: student, assignment: asset_processor.assignment) }
          let(:asset) { lti_asset_model(submission:) }
          let(:asset_report) do
            lti_asset_report_model(
              lti_asset_processor_id: asset_processor.id,
              asset:,
              visible_to_owner: false
            )
          end

          it "allows teacher to view the report regardless of visible_to_owner setting" do
            user_session(@teacher)
            get :launch_report, params: { asset_processor_id: asset_processor.id, report_id: asset_report.id }
            expect(response).to have_http_status :ok
          end
        end

        context "logging" do
          before do
            allow(Lti::LogService).to receive(:new) do
              double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
            end
          end

          it "logs launch" do
            expect(Lti::LogService).to receive(:new).with(
              tool: asset_processor.context_external_tool,
              context: @course,
              user: @teacher,
              session_id: nil,
              launch_type: :content_item,
              launch_url: asset_processor.report["url"],
              message_type: "LtiReportReviewRequest"
            )
            subject
          end
        end
      end
    end
  end
end
