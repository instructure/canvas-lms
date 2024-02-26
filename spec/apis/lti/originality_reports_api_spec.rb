# frozen_string_literal: true

#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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

require_relative "lti2_api_spec_helper"

module Lti
  describe "Originality Reports API", type: :request do
    include_context "lti2_api_spec_helper"
    let(:service_name) { OriginalityReportsApiController::ORIGINALITY_REPORT_SERVICE }
    let(:aud) { host }

    before(:once) { attachment_model }

    before do
      course_factory(active_all: true)
      message_handler.update(message_type: "basic-lti-launch-request")
      student_in_course active_all: true
      teacher_in_course active_all: true

      @tool = @course.context_external_tools.create(name: "a",
                                                    domain: "google.com",
                                                    consumer_key: "12345",
                                                    shared_secret: "secret")
      @tool.settings[:assignment_configuration] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      @tool.save!
      @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12,
                                                tool_settings_tool: @tool)

      @assignment.tool_settings_tool = message_handler
      @assignment.save!
      @attachment.context = @student
      @attachment.save!

      @submission = @assignment.submit_homework(@student, attachments: [@attachment])

      @endpoints = {
        create: "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report"
      }
    end

    describe "service definition" do
      it "uses the correct endpoint" do
        service = Lti::OriginalityReportsApiController::SERVICE_DEFINITIONS.first
        expect(service[:endpoint]).to eq "api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report"
      end
    end

    describe "GET assignments/:assignment_id/originality_report/submissions/:submission_id/:id (#show)" do
      before do
        report_initial_values = {
          attachment: @attachment,
          originality_score: 0.5,
          submission: @submission
        }
        @report = OriginalityReport.create!(report_initial_values)
        @endpoints[:show] = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id}"
        @endpoints[:alt_show] = "/api/lti/assignments/#{@assignment.id}/files/#{@attachment.id}/originality_report"
        @assignment.course.update(account: tool_proxy.context)
      end

      it "requires an lti access token" do
        get @endpoints[:show]
        expect(response).to have_http_status :unauthorized
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool = nil
        @assignment.save!
        get @endpoints[:show], headers: request_headers
        expect(response).to have_http_status :unauthorized
      end

      it "allows tool proxies with matching access" do
        @assignment.tool_settings_tool = message_handler
        @assignment.save!

        new_tool_proxy = tool_proxy.deep_clone
        new_tool_proxy.update(guid: SecureRandom.uuid)

        token = Lti::OAuth2::AccessToken.create_jwt(aud:, sub: new_tool_proxy.guid)
        other_helpers = { Authorization: "Bearer #{token}" }
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).and_return(true)
        get @endpoints[:show], headers: other_helpers
        expect(response).to have_http_status :ok
      end

      it "returns an originality report in the response" do
        expected_keys = %w[
          id
          file_id
          originality_score
          originality_report_file_id
          originality_report_url
          originality_report_lti_url
          created_at
          updated_at
          submission_id
          workflow_state
          link_id
          error_message
          submission_time
          root_account_id
        ].freeze

        get @endpoints[:show], headers: request_headers
        expect(response).to be_successful
        expect(JSON.parse(response.body).keys).to match_array(expected_keys)
      end

      it "returns the specified originality report in the response" do
        get @endpoints[:show], headers: request_headers
        expect(response).to be_successful
        expect(JSON.parse(response.body)["id"]).to eq @report.id
      end

      it "checks that the specified originality report exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}originality_report/#{@report.id + 1}"
        get invalid_report_url

        expect(response).to have_http_status :not_found
      end

      it "checks that the specified submission exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}originality_report/#{@report.id}"
        get invalid_report_url

        expect(response).to have_http_status :not_found
      end

      it "requires the plagiarism feature flag" do
        post @endpoints[:show]
        expect(response).not_to be_successful
      end

      it "verifies the specified attachment is in the course" do
        attachment = @attachment.dup
        attachment.context = @course
        attachment.save!

        post @endpoints[:show], params: { originality_report: { file_id: attachment.id, originality_score: 0.4 } }, headers: request_headers
        expect(response).to have_http_status :not_found
      end

      it "verifies that the specified submission includes the attachment" do
        sub = @submission.dup
        sub.attachments
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
        get endpoint, params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }
        expect(response).to have_http_status :unauthorized
      end

      context "show by attachment id" do
        it "requires an lti access token" do
          get @endpoints[:alt_show]
          expect(response).to have_http_status :unauthorized
        end

        it "requires the tool proxy to be associated to the assignment" do
          @assignment.tool_settings_tool = nil
          @assignment.save!
          get @endpoints[:alt_show], headers: request_headers
          expect(response).to have_http_status :unauthorized
        end

        it "allows tool proxies with matching access" do
          @assignment.tool_settings_tool = message_handler
          @assignment.save!
          new_tool_proxy = tool_proxy.deep_clone
          new_tool_proxy.update(guid: SecureRandom.uuid)
          token = Lti::OAuth2::AccessToken.create_jwt(aud:, sub: new_tool_proxy.guid)
          other_helpers = { Authorization: "Bearer #{token}" }
          allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).and_return(true)
          get @endpoints[:alt_show], headers: other_helpers
          expect(response).to have_http_status :ok
        end

        it "returns an originality report in the response" do
          expected_keys = %w[
            id
            file_id
            originality_score
            originality_report_file_id
            originality_report_url
            originality_report_lti_url
            created_at
            updated_at
            submission_id
            workflow_state
            link_id
            error_message
            submission_time
            root_account_id
          ].freeze
          get @endpoints[:alt_show], headers: request_headers
          expect(response).to be_successful
          expect(JSON.parse(response.body).keys).to match_array(expected_keys)
        end

        it "returns the specified originality report in the response" do
          get @endpoints[:alt_show], headers: request_headers
          expect(response).to be_successful
          expect(JSON.parse(response.body)["id"]).to eq @report.id
        end

        it "checks that the specified originality report exists" do
          invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}originality_report/#{@report.id + 1}"
          get invalid_report_url
          expect(response).to have_http_status :not_found
        end

        it "checks that the specified submission exists" do
          invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}originality_report/#{@report.id}"
          get invalid_report_url
          expect(response).to have_http_status :not_found
        end

        it "requires the plagiarism feature flag" do
          post @endpoints[:alt_show]
          expect(response).not_to be_successful
        end

        it "verifies the specified attachment is in the course" do
          attachment = @attachment.dup
          attachment.context = @course
          attachment.save!
          post @endpoints[:alt_show], params: { originality_report: { file_id: attachment.id, originality_score: 0.4 } }, headers: request_headers
          expect(response).to have_http_status :not_found
        end

        it "verifies that the specified submission includes the attachment" do
          sub = @submission.dup
          sub.attachments
          sub.user = @teacher
          sub.save!
          endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
          get endpoint, params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }
          expect(response).to have_http_status :unauthorized
        end
      end
    end

    describe "PUT assignments/:assignment_id/originality_report (#update)" do
      before do
        report_initial_values = {
          attachment: @attachment,
          originality_score: 0.5,
          submission: @submission
        }
        @report = OriginalityReport.create!(report_initial_values)
        @endpoints[:update] = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id}"
        @endpoints[:update_alt] = "/api/lti/assignments/#{@assignment.id}/files/#{@attachment.id}/originality_report"
        @assignment.course.update(account:)
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool = nil
        @assignment.save!
        put @endpoints[:update], params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }, headers: request_headers
        expect(response).to have_http_status :unauthorized
      end

      it "checks that the OriginalityReport exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id + 1}"
        put invalid_report_url, params: { originality_report: { originality_score: 0.3 } }, headers: request_headers
        expect(response).to have_http_status :not_found
      end

      it "checks that the Submission exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}/originality_report/#{@report.id}"
        put invalid_report_url, params: { originality_report: { originality_score: 0.3 } }, headers: request_headers
        expect(response).to have_http_status :not_found
      end

      it "updates originality score" do
        put @endpoints[:update], params: { originality_report: { originality_score: 0.3 } }, headers: request_headers

        expect(response).to be_successful
        expect(OriginalityReport.find(@report.id).originality_score).to eq 0.3
      end

      it "does not update originality score if out of range" do
        put @endpoints[:update], params: { originality_report: { originality_score: 150 } }, headers: request_headers
        expect(response).to have_http_status :bad_request
        expect(JSON.parse(response.body)["errors"]).to have_key "originality_score"
      end

      it "allows setting the originality_report to nil" do
        put @endpoints[:update], params: { originality_report: { originality_score: nil } }, headers: request_headers
        expect(response).to be_ok
      end

      it "updates originality report attachment id" do
        report_file = @attachment.dup
        report_file.save!

        put @endpoints[:update], params: { originality_report: { originality_report_file_id: report_file.id } }, headers: request_headers
        expect(response).to be_successful
        expect(OriginalityReport.find(@report.id).originality_report_file_id).to eq report_file.id
      end

      it "updates originality report url" do
        put @endpoints[:update], params: { originality_report: { originality_report_url: "http://www.test.com" } }, headers: request_headers
        expect(response).to be_successful
        expect(OriginalityReport.find(@report.id).originality_report_url).to eq "http://www.test.com"
      end

      it "updates error_message" do
        put @endpoints[:update], params: { originality_report: { error_message: "An error occured." } }, headers: request_headers
        expect(response).to be_successful
        expect(OriginalityReport.find(@report.id).error_message).to eq "An error occured."
      end

      it "updates the associated resource_url" do
        put @endpoints[:update],
            params: {
              originality_report: {
                tool_setting: {
                  resource_url: "http://www.lti-test.com",
                  resource_type_code: "code"
                }
              }
            },
            headers: request_headers
        expect(response).to be_successful
        tool_setting = OriginalityReport.find(@report.id).lti_link
        expect(tool_setting.resource_url).to eq "http://www.lti-test.com"
      end

      it "does not remove the lti link when tool_setting is not supplied" do
        put @endpoints[:update],
            params: {
              originality_report: {
                originality_score: 5,
                tool_setting: {
                  resource_url: "http://www.lti-test.com",
                  resource_type_code: "code"
                }
              }
            },
            headers: request_headers
        expect(response).to be_successful
        lti_link_id = OriginalityReport.find(@report.id).lti_link.id
        put @endpoints[:update],
            params: {
              originality_report: {
                originality_score: nil
              }
            },
            headers: request_headers
        expect(response).to be_successful
        expect(Lti::Link.find_by(id: lti_link_id)).to eq OriginalityReport.find(@report.id).lti_link
      end

      it "removes the lti link when tool_setting is null" do
        put @endpoints[:update],
            params: {
              originality_report: {
                originality_score: 5,
                tool_setting: {
                  resource_url: "http://www.lti-test.com",
                  resource_type_code: "code"
                }
              }
            },
            headers: request_headers

        lti_link_id = OriginalityReport.find(@report.id).lti_link.id
        expect(Lti::Link.find_by(id: lti_link_id)).not_to be_nil

        put @endpoints[:update],
            params: {
              originality_report: {
                originality_score: nil,
                tool_setting: {
                  resource_type_code: nil
                }
              }
            },
            headers: request_headers

        expect(Lti::Link.find_by(id: lti_link_id)).to be_nil
      end

      it "verifies the report is in the same context as the assignment" do
        @submission.attachments = []
        @submission.save!
        put @endpoints[:update], params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }, headers: request_headers
        expect(response).to have_http_status :unauthorized
      end

      it "verifies that the specified submission includes the attachment" do
        sub = @submission.dup
        sub.attachments
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
        put endpoint, params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }
        expect(response).to have_http_status :unauthorized
      end

      it "sets the resource type code for the associated tool setting" do
        score = 0.25
        put @endpoints[:update],
            params: {
              originality_report: {
                file_id: @attachment.id,
                originality_score: score,
                tool_setting: {
                  resource_type_code: resource_handler.resource_type_code
                }
              }
            },
            headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["tool_setting"]["resource_type_code"]).to eq resource_handler.resource_type_code
      end

      it "sets the workflow state" do
        put @endpoints[:update],
            params: {
              originality_report: {
                file_id: @attachment.id,
                originality_score: nil,
                workflow_state: "pending"
              }
            },
            headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["workflow_state"]).to eq "pending"
      end

      it "sets the resource_url of the associated tool setting" do
        score = 0.25
        launch_url = "http://www.my-launch.com"
        put @endpoints[:update],
            params: {
              originality_report: {
                file_id: @attachment.id,
                originality_score: score,
                tool_setting: {
                  resource_type_code: resource_handler.resource_type_code,
                  resource_url: launch_url
                }
              }
            },
            headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["tool_setting"]["resource_url"]).to eq launch_url
      end

      context "update by attachment id" do
        before { AttachmentAssociation.create!(attachment: @attachment, context: @submission) }

        it "requires the tool proxy to be associated to the assignment" do
          @assignment.tool_settings_tool = nil
          @assignment.save!
          put @endpoints[:update_alt], params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }, headers: request_headers
          expect(response).to have_http_status :unauthorized
        end

        it "checks that the OriginalityReport exists" do
          invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id + 1}"
          put invalid_report_url, params: { originality_report: { originality_score: 0.3 } }, headers: request_headers
          expect(response).to have_http_status :not_found
        end

        it "checks that the Submission exists" do
          invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}/originality_report/#{@report.id}"
          put invalid_report_url, params: { originality_report: { originality_score: 0.3 } }, headers: request_headers
          expect(response).to have_http_status :not_found
        end

        it "updates originality score" do
          put @endpoints[:update_alt], params: { originality_report: { originality_score: 0.3 } }, headers: request_headers

          expect(response).to be_successful
          expect(OriginalityReport.find(@report.id).originality_score).to eq 0.3
        end

        it "does not update originality score if out of range" do
          put @endpoints[:update_alt], params: { originality_report: { originality_score: 150 } }, headers: request_headers
          expect(response).to have_http_status :bad_request
          expect(JSON.parse(response.body)["errors"]).to have_key "originality_score"
        end

        it "allows setting the originality_report to nil" do
          put @endpoints[:update_alt], params: { originality_report: { originality_score: nil } }, headers: request_headers
          expect(response).to be_ok
        end

        it "updates originality report attachment id" do
          report_file = @attachment.dup
          report_file.save!
          put @endpoints[:update_alt], params: { originality_report: { originality_report_file_id: report_file.id } }, headers: request_headers
          expect(response).to be_successful
          expect(OriginalityReport.find(@report.id).originality_report_file_id).to eq report_file.id
        end

        it "updates originality report url" do
          put @endpoints[:update_alt], params: { originality_report: { originality_report_url: "http://www.test.com" } }, headers: request_headers
          expect(response).to be_successful
          expect(OriginalityReport.find(@report.id).originality_report_url).to eq "http://www.test.com"
        end

        it "updates the associated resource_url" do
          put @endpoints[:update_alt],
              params: {
                originality_report: {
                  tool_setting: {
                    resource_url: "http://www.lti-test.com",
                    resource_type_code: "code"
                  }
                }
              },
              headers: request_headers
          expect(response).to be_successful
          lti_link = OriginalityReport.find(@report.id).lti_link
          expect(lti_link.resource_url).to eq "http://www.lti-test.com"
        end

        it "verifies the report is in the same context as the assignment" do
          @submission.attachments = []
          @submission.save!
          put @endpoints[:update_alt], params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }, headers: request_headers
          expect(response).to have_http_status :not_found
        end

        it "verifies that the specified submission includes the attachment" do
          sub = @submission.dup
          sub.attachments
          sub.user = @teacher
          sub.save!
          endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
          put endpoint, params: { originality_report: { originality_report_lti_url: "http://www.lti-test.com" } }
          expect(response).to have_http_status :unauthorized
        end

        it "sets the resource type code for the associated tool setting" do
          score = 0.25
          put @endpoints[:update_alt],
              params: {
                originality_report: {
                  file_id: @attachment.id,
                  originality_score: score,
                  tool_setting: {
                    resource_type_code: resource_handler.resource_type_code
                  }
                }
              },
              headers: request_headers
          response_body = JSON.parse(response.body)
          expect(response_body["tool_setting"]["resource_type_code"]).to eq resource_handler.resource_type_code
        end

        it "sets the workflow state" do
          put @endpoints[:update_alt],
              params: {
                originality_report: {
                  file_id: @attachment.id,
                  originality_score: nil,
                  workflow_state: "pending"
                }
              },
              headers: request_headers
          response_body = JSON.parse(response.body)
          expect(response_body["workflow_state"]).to eq "pending"
        end

        it "sets the resource_url of the associated tool setting" do
          score = 0.25
          launch_url = "http://www.my-launch.com"
          put @endpoints[:update_alt],
              params: {
                originality_report: {
                  file_id: @attachment.id,
                  originality_score: score,
                  tool_setting: {
                    resource_type_code: resource_handler.resource_type_code,
                    resource_url: launch_url
                  }
                }
              },
              headers: request_headers
          response_body = JSON.parse(response.body)
          expect(response_body["tool_setting"]["resource_url"]).to eq launch_url
        end
      end
    end

    describe "POST assignments/:assignment_id/submissions/:submission_id/originality_report (#create)" do
      before do
        @assignment.course.update(account:)
      end

      it "creates an originality report when provided required params" do
        score = 0.25
        post @endpoints[:create], params: { originality_report: { file_id: @attachment.id, originality_score: score } }, headers: request_headers

        expect(assigns[:report].attachment).to eq @attachment
        expect(assigns[:report].originality_score).to eq score
      end

      it "includes expected keys in JSON response" do
        expected_keys = %w[
          id
          file_id
          originality_score
          originality_report_file_id
          originality_report_url
          originality_report_lti_url
          created_at
          updated_at
          submission_id
          workflow_state
          link_id
          error_message
          submission_time
          root_account_id
        ].freeze

        post @endpoints[:create], params: { originality_report: { file_id: @attachment.id, originality_score: 0.4 } }, headers: request_headers
        expect(response).to be_successful
        expect(JSON.parse(response.body).keys).to match_array(expected_keys)
      end

      it "checks for required params" do
        post @endpoints[:create], headers: request_headers
        expect(response).to have_http_status :bad_request

        post @endpoints[:create], params: { originality_report: {} }, headers: request_headers
        expect(response).to have_http_status :bad_request

        post @endpoints[:create], params: { originality_report: { originality_score: 0.5 } }, headers: request_headers
        expect(response).to have_http_status :not_found
      end

      it "checks that the specified assignment exists" do
        invalid_attach_url = "/api/lti/assignments/#{@assignment.id + 1}/submissions/#{@submission.id}/originality_report"
        post invalid_attach_url, params: { originality_report: { file_id: @attachment.id, originality_score: 0.4 } }
        expect(response).not_to be_successful
      end

      it "checks that the specified file exists" do
        post @endpoints[:create], params: { originality_report: { file_id: @attachment.id + 1, originality_score: 0.4 } }, headers: request_headers
        expect(response).not_to be_successful
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool = nil
        @assignment.save!
        post @endpoints[:create], params: { originality_report: { file_id: @attachment.id, originality_score: 0.4 } }, headers: request_headers
        expect(response).to have_http_status :unauthorized
      end

      it "verifies the specified attachment is in the course" do
        attachment = @attachment.dup
        attachment.context = @course
        attachment.save!

        post @endpoints[:create], params: { originality_report: { file_id: attachment.id, originality_score: 0.4 } }, headers: request_headers
        expect(response).to have_http_status :unauthorized
      end

      it "verifies that the specified submission includes the attachment" do
        sub = @submission.dup
        sub.attachments = []
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report"
        post endpoint, params: { originality_report: { file_id: @attachment.id, originality_score: 0.4 } }
        expect(response).to have_http_status :unauthorized
      end

      it "does not require an attachment if submission type includes online text entry" do
        @submission.assignment.update!(submission_types: "online_text_entry")
        @submission.update!(body: "some text")
        score = 0.25
        post @endpoints[:create], params: { originality_report: { originality_score: score } }, headers: request_headers

        expect(assigns[:report].attachment).to be_nil
        expect(assigns[:report].originality_score).to eq score
      end

      it "does not requre an attachment if submission type does not include online text entry" do
        @submission.update!(body: "some text")
        score = 0.25
        post @endpoints[:create], params: { originality_report: { originality_score: score } }, headers: request_headers
        expect(response).to be_not_found
      end

      it "sets the resource type code of the associated tool setting" do
        score = 0.25
        post @endpoints[:create],
             params: {
               originality_report: {
                 file_id: @attachment.id,
                 originality_score: score,
                 tool_setting: {
                   resource_type_code: resource_handler.resource_type_code
                 }
               }
             },
             headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["tool_setting"]["resource_type_code"]).to eq resource_handler.resource_type_code
      end

      it "sets the workflow state" do
        post @endpoints[:create],
             params: {
               originality_report: {
                 file_id: @attachment.id,
                 workflow_state: "pending"
               }
             },
             headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["workflow_state"]).to eq "pending"
      end

      it "sets the error_message" do
        post @endpoints[:create],
             params: {
               originality_report: {
                 file_id: @attachment.id,
                 workflow_state: "error",
                 error_message: "error message"
               }
             },
             headers: request_headers
        expect(json_parse["error_message"]).to eq "error message"
      end

      it "sets the link_id resource_url" do
        score = 0.25
        launch_url = "http://www.my-launch.com"
        post @endpoints[:create],
             params: {
               originality_report: {
                 file_id: @attachment.id,
                 originality_score: score,
                 tool_setting: {
                   resource_url: launch_url,
                   resource_type_code: resource_handler.resource_type_code,
                 }
               }
             },
             headers: request_headers
        response_body = JSON.parse(response.body)
        expect(response_body["tool_setting"]["resource_url"]).to eq launch_url
      end

      context "with sharded attachments" do
        specs_require_sharding

        it "allows creating reports for any attachment in submission history" do
          shard_two = @shard1
          a = @course.assignments.create!(
            title: "some assignment",
            assignment_group: @group,
            points_possible: 12,
            tool_settings_tool: @tool
          )
          a.tool_settings_tool = message_handler
          a.save!

          first_attachment = shard_two.activate { attachment_model(context: @student) }
          Timecop.freeze(10.seconds.ago) do
            a.submit_homework(@student, attachments: [first_attachment])
          end

          Timecop.freeze(5.seconds.ago) do
            a.submit_homework(@student, attachments: [attachment_model(context: @student)])
          end

          post "/api/lti/assignments/#{a.id}/submissions/#{a.reload.submissions.first.id}/originality_report",
               params: {
                 originality_report: {
                   file_id: first_attachment.id,
                   workflow_state: "pending"
                 }
               },
               headers: request_headers

          expect(response).to have_http_status :created
        end
      end

      context "when the originality report already exists" do
        let(:submission) { @submission }
        let(:originality_score) { 50 }
        let(:existing_report) do
          OriginalityReport.create!(
            attachment: @attachment,
            workflow_state: "pending",
            submission:
          )
        end

        before { existing_report }

        it "updates the originality report" do
          post @endpoints[:create],
               params: {
                 originality_report: {
                   file_id: @attachment.id,
                   originality_score:
                 }
               },
               headers: request_headers

          response_body = JSON.parse(response.body)
          expect(response_body["originality_score"]).to eq 50
        end

        it "allows error_message to be cleared and workflow_state to not be errored" do
          existing_report.update(workflow_state: "error", error_message: "the batteries are in backwards")
          post @endpoints[:create],
               params: {
                 originality_report: {
                   file_id: @attachment.id,
                   workflow_state: "pending"
                 }
               },
               headers: request_headers

          response_body = JSON.parse(response.body)
          expect(response_body["workflow_state"]).to eq "pending"
          expect(response_body["error_message"]).to be_nil
        end

        context "when the attachment matches, but the submission does not" do
          let(:new_assignment) do
            a = @submission.assignment.dup
            a.lti_context_id = SecureRandom.uuid
            a.tool_settings_tool = message_handler
            a.save!
            a
          end
          let(:new_submission) { new_assignment.submit_homework(@student, attachments: [@attachment]) }

          it "does not update the originality report" do
            post "/api/lti/assignments/#{new_assignment.id}/submissions/#{new_submission.id}/originality_report",
                 params: {
                   originality_report: {
                     file_id: @attachment.id,
                     workflow_state: "pending"
                   }
                 },
                 headers: request_headers

            response_body = JSON.parse(response.body)
            expect(response_body["workflow_state"]).to eq "pending"
          end
        end
      end

      context "when the assignment does not require an attachment (i.e. allows online_text_entry)" do
        let!(:n_reports_at_beginning) { OriginalityReport.count }

        def expect_n_new_reports(n)
          expect(OriginalityReport.count).to eq(n_reports_at_beginning + n)
        end

        context "when attempt is given" do
          before do
            @submission.assignment.update!(submission_types: "online_text_entry")
          end

          def create_version
            sub = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "1st noattach")
            new_version = sub.versions.max_by { |v| v.model.attempt }
            expect(sub.attempt).to eq(new_version.model.attempt)

            new_version
          end

          def post_score_for_version(version, score)
            post_score_for_attempt(version.model.attempt, score)
          end

          def post_score_for_attempt(attempt, score)
            post @endpoints[:create],
                 params: {
                   originality_report: {
                     originality_score: score,
                     attempt:
                   },
                 },
                 headers: request_headers
            JSON.parse(response.body)["id"]
          end

          it "updates the originality report if one exists for the attempt" do
            ver1 = create_version
            report1_id = post_score_for_version(ver1, 10)
            expect(response).to have_http_status(:created) # created
            create_version
            report2_id = post_score_for_version(ver1, 20)
            expect(response).to have_http_status(:ok) # ok (updated)

            expect_n_new_reports(1)
            expect(report2_id).to eq(report1_id)
            report = OriginalityReport.find(report2_id)
            expect(report.originality_score).to eq(20)
            expect(report.submission_time).to eq(ver1.model.submitted_at)
          end

          it "creates a new originality report if one does not exist for the attempt" do
            ver1 = create_version
            report1_id = post_score_for_version(ver1, 10)
            expect(response).to have_http_status(:created) # created
            ver2 = create_version
            report2_id = post_score_for_version(ver2, 20)
            expect(response).to have_http_status(:created) # created

            expect_n_new_reports(2)
            report1 = OriginalityReport.find(report1_id)
            report2 = OriginalityReport.find(report2_id)
            expect(report1.originality_score).to eq(10)
            expect(report1.submission_time).to eq(ver1.model.submitted_at)
            expect(report2.originality_score).to eq(20)
            expect(report2.submission_time).to eq(ver2.model.submitted_at)
          end

          # This ensures that, if they are creating a report for an attempt other than the latest,
          # we will connect the report to the correct attempt (we match them up by submission time
          # when viewing reports, or updating them in #create)
          it "creates reports which match up (with correct the submitted_at) with the correct attempt" do
            ver1 = create_version
            ver2 = create_version
            report1_id = post_score_for_version(ver1, 10)
            expect(response).to have_http_status(:created) # created
            report2_id = post_score_for_version(ver2, 20)
            expect(response).to have_http_status(:created) # created

            expect_n_new_reports(2)
            report1 = OriginalityReport.find(report1_id)
            report2 = OriginalityReport.find(report2_id)
            expect(report1.originality_score).to eq(10)
            expect(report1.submission_time).to eq(ver1.model.submitted_at)
            expect(report2.originality_score).to eq(20)
            expect(report2.submission_time).to eq(ver2.model.submitted_at)
          end

          it "returns a 404 if the attempt does not exist" do
            ver1 = create_version
            post_score_for_attempt(ver1.model.attempt + 1, 10)
            expect(response).to have_http_status(:not_found)
            expect_n_new_reports(0)
          end
        end

        context "when attempt is not given" do
          it "updates the first originality report created without an attachment" do
            @submission.assignment.update!(submission_types: "online_text_entry")
            originality_score = 50
            post @endpoints[:create],
                 params: {
                   originality_report: {
                     workflow_state: "pending"
                   }
                 },
                 headers: request_headers

            post @endpoints[:create],
                 params: {
                   originality_report: {
                     originality_score:
                   }
                 },
                 headers: request_headers
            response_body = JSON.parse(response.body)
            expect_n_new_reports(1)
            expect(response_body["originality_score"]).to eq 50
          end
        end
      end

      context "optional params" do
        before do
          report_file = @attachment.dup
          report_file.save!

          @report = {
            file_id: @attachment.id,
            originality_score: 0.5,
            originality_report_file_id: report_file.id,
            originality_report_url: "http://www.report-url.com",
            originality_report_lti_url: "http://www.report-lti-url.com"
          }

          post @endpoints[:create], params: { originality_report: @report }, headers: request_headers
          @response_hash = JSON.parse response.body
        end

        it "sets the attachment" do
          expect(response).to be_successful
          created_report = OriginalityReport.find(@response_hash["id"])
          expect(created_report.attachment).to eq @attachment
        end
      end

      context "when group assignment" do
        let!(:original_assignment) { @assignment }
        let(:user_one) { submission_one.user }
        let(:user_two) { submission_two.user }
        let(:course) { submission_one.assignment.course }
        let(:submission_one) { submission_model({ course: original_assignment.course, assignment: original_assignment }) }
        let(:submission_two) { submission_model({ course: original_assignment.course, assignment: original_assignment }) }
        let(:submission_three) { submission_model({ course: original_assignment.course, assignment: original_assignment }) }
        let!(:group) do
          group = course.groups.create!(name: "group one")
          group.add_user(user_one)
          group.add_user(user_two)
          submission_one.update!(group:)
          submission_two.update!(group:)
          group
        end
        let(:create_endpoint) do
          "/api/lti/assignments/#{submission_one.assignment.id}/submissions/#{submission_one.id}/originality_report"
        end
        let(:originality_score) { 33 }

        before do
          submission_one.assignment.update!(submission_types: "online_text_entry")
          submission_two.update!(
            assignment_id: submission_one.assignment_id,
            group_id: submission_one.group_id
          )
        end

        def post_to_endpoint
          post create_endpoint,
               params: {
                 originality_report: {
                   originality_score:,
                 },
                 submission_id: submission_one.id
               },
               headers: request_headers
        end

        it "copies the report to all other submissions in the group" do
          post_to_endpoint
          run_jobs

          expect(submission_two.originality_reports.first.originality_score).to eq originality_score
        end

        it "calls OriginalityReport.copy_to_group_submissions_later! when creating" do
          expect_any_instance_of(OriginalityReport)
            .to receive(:copy_to_group_submissions_later!) do |instance|
            expect(instance.submission_id).to eq(submission_one.id)
            expect(instance.originality_score).to eq(originality_score)
          end

          post_to_endpoint
        end

        it "calls OriginalityReport.copy_to_group_submissions_later! when updating" do
          post_to_endpoint
          created_report_id = JSON.parse(response.body)["id"]

          expect_any_instance_of(OriginalityReport)
            .to receive(:copy_to_group_submissions_later!).at_least(:once) do |instance|
            expect(instance.id).to eq(created_report_id)
          end
          post_to_endpoint
        end

        it "does not copy the report to submissions outside the group" do
          post_to_endpoint
          run_jobs

          expect(submission_three.originality_reports).to be_blank
        end
      end

      def api_create_originality_report(file_id, score)
        api_call(
          :post,
          "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report",
          {
            controller: "originality_reports_api",
            action: "create",
            format: "json",
            assignment_id: @assignment.id,
            submission_id: @submission.id
          },
          {
            originality_report: {
              originality_score: score,
              file_id:
            }
          },
          request_headers
        )
      end
    end
  end
end
