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

require File.expand_path(File.dirname(__FILE__) + '/lti2_api_spec_helper')
require_dependency "lti/ims/access_token_helper"
module Lti
  describe 'Originality Reports API', type: :request do
    include_context 'lti2_api_spec_helper'
    let(:service_name) { OriginalityReportsApiController::ORIGINALITY_REPORT_SERVICE }
    before :each do
      attachment_model

      course_factory(active_all: true)
      student_in_course active_all: true
      teacher_in_course active_all: true

      @tool = @course.context_external_tools.create(name: "a",
                                                    domain: "google.com",
                                                    consumer_key: '12345',
                                                    shared_secret: 'secret')
      @tool.settings[:assignment_configuration] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
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

      Account.any_instance.stubs(:feature_enabled?).with(:plagiarism_detection_platform).returns(true)
    end

    describe "GET assignments/:assignment_id/originality_report/submissions/:submission_id/:id (#show)" do
      before :each do
        report_initial_values = {
          attachment: @attachment,
          originality_score: 0.5,
          submission: @submission
        }
        @report = OriginalityReport.create!(report_initial_values)
        @endpoints[:show] = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id}"
      end

      it "requires an lti access token" do
        get @endpoints[:show]
        expect(response.code).to eq '401'
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool_proxies.clear
        @assignment.save!
        get @endpoints[:show], {}, request_headers
        expect(response.code).to eq '401'
      end

      it "returns an originality report in the response" do

        expected_keys = [
          'id',
          'file_id',
          'originality_score',
          'originality_report_file_id',
          'originality_report_url',
          'originality_report_lti_url',
          'created_at',
          'updated_at',
          'submission_id',
          'workflow_state'
        ].freeze

        get @endpoints[:show], {}, request_headers

        expect(response).to be_success
        expect(JSON.parse(response.body).keys).to match_array(expected_keys)
      end

      it "returns the specified originality report in the response" do
        get @endpoints[:show], {}, request_headers
        expect(response).to be_success
        expect(JSON.parse(response.body)['id']).to eq @report.id
      end

      it "checks that the specified originality report exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}originality_report/#{@report.id + 1}"
        get invalid_report_url

        expect(response.status).to eq 404
      end

      it "checks that the specified submission exists" do
        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}originality_report/#{@report.id}"
        get invalid_report_url

        expect(response.status).to eq 404
      end

      it "requires the plagiarism feature flag" do
        Account.any_instance.stubs(:feature_enabled?).with(:plagiarism_detection_platform).returns(false)
        post @endpoints[:show]
        expect(response).not_to be_success
      end

      it "verifies the specified attachment is in the course" do

        attachment = @attachment.dup
        attachment.context = @course
        attachment.save!

        post @endpoints[:show], {originality_report: {file_id: attachment.id, originality_score: 0.4}}, request_headers
        expect(response.status).to eq 404
      end

      it "verifies that the specified submission includes the attachment" do

        sub = @submission.dup
        sub.attachments
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
        get endpoint, originality_report: {originality_report_lti_url: "http://www.lti-test.com"}
        expect(response.status).to eq 401
      end
    end

    describe "PUT assignments/:assignment_id/originality_report (#update)" do
      before :each do
        report_initial_values = {
          attachment: @attachment,
          originality_score: 0.5,
          submission: @submission
        }
        @report = OriginalityReport.create!(report_initial_values)
        @endpoints[:update] = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id}"
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool_proxies.clear
        @assignment.save!
        put @endpoints[:update], {originality_report: {originality_report_lti_url: "http://www.lti-test.com"}}, request_headers
        expect(response.code).to eq '401'
      end

      it "checks that the OriginalityReport exists" do

        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report/#{@report.id + 1}"
        put invalid_report_url, {originality_report: {originality_score: 0.3}}, request_headers
        expect(response.status).to eq 404
      end

      it "checks that the Submission exists" do

        invalid_report_url = "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id + 1}/originality_report/#{@report.id}"
        put invalid_report_url, {originality_report: {originality_score: 0.3}}, request_headers
        expect(response.status).to eq 404
      end

      it "updates originality score" do

        put @endpoints[:update], {originality_report: {originality_score: 0.3}}, request_headers

        expect(response).to be_success
        expect(OriginalityReport.find(@report.id).originality_score).to eq 0.3
      end

      it "does not update originality score if out of range" do

        put @endpoints[:update], {originality_report: {originality_score: 150}}, request_headers

        expect(response.status).to eq 400
        expect(JSON.parse(response.body)['errors'].key? 'originality_score').to be_truthy
      end

      it "updates originality report attachment id" do
        report_file = @attachment.dup
        report_file.save!

        put @endpoints[:update], {originality_report: {originality_report_file_id: report_file.id}}, request_headers

        expect(response).to be_success
        expect(OriginalityReport.find(@report.id).originality_report_file_id).to eq report_file.id
      end

      it "updates originality report url" do

        put @endpoints[:update], {originality_report: {originality_report_url: "http://www.test.com"}}, request_headers

        expect(response).to be_success
        expect(OriginalityReport.find(@report.id).originality_report_url).to eq "http://www.test.com"
      end

      it "updates originality report LTI url" do

        put @endpoints[:update], {originality_report: {originality_report_lti_url: "http://www.lti-test.com"}}, request_headers

        expect(response).to be_success
        expect(OriginalityReport.find(@report.id).originality_report_lti_url).to eq "http://www.lti-test.com"
      end

      it "requires the plagiarism feature flag" do
        Account.any_instance.stubs(:feature_enabled?).with(:plagiarism_detection_platform).returns(false)

        put @endpoints[:udpate], {originality_report: {originality_report_lti_url: "http://www.lti-test.com"}}, request_headers
        expect(response).not_to be_success
      end

      it "verifies the report is in the same context as the assignment" do

        @submission.attachments = []
        @submission.save!
        put @endpoints[:update], {originality_report: {originality_report_lti_url: "http://www.lti-test.com"}}, request_headers

        expect(response.status).to eq 401
      end

      it "verifies that the specified submission includes the attachment" do

        sub = @submission.dup
        sub.attachments
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report/#{@report.id}"
        put endpoint, originality_report: {originality_report_lti_url: "http://www.lti-test.com"}
        expect(response.status).to eq 401
      end
    end

    describe "POST assignments/:assignment_id/submissions/:submission_id/originality_report (#create)" do
      it "creates an originality report when provided required params" do

        score = 0.25
        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: score}}, request_headers

        expect(assigns[:report].attachment).to eq @attachment
        expect(assigns[:report].originality_score).to eq score
      end

      it "includes expected keys in JSON response" do

        expected_keys = [
          'id',
          'file_id',
          'originality_score',
          'originality_report_file_id',
          'originality_report_url',
          'originality_report_lti_url',
          'created_at',
          'updated_at',
          'submission_id',
          'workflow_state'
        ].freeze

        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: 0.4}}, request_headers
        expect(response).to be_success
        expect(JSON.parse(response.body).keys).to match_array(expected_keys)
      end

      it "checks for required params" do


        post @endpoints[:create], {}, request_headers
        expect(response.status).to eq 400

        post @endpoints[:create], {originality_report: {}}, request_headers
        expect(response.status).to eq 400

        post @endpoints[:create], {originality_report: {originality_score: 0.5}}, request_headers
        expect(response.status).to eq 404
      end

      it "checks that the specified assignment exists" do

        invalid_attach_url = "/api/lti/assignments/#{@assignment.id + 1}/submissions/#{@submission.id}/originality_report"
        post invalid_attach_url, originality_report: {file_id: @attachment.id, originality_score: 0.4}
        expect(response).not_to be_success
      end

      it "checks that the specified file exists" do

        post @endpoints[:create], {originality_report: {file_id: @attachment.id + 1, originality_score: 0.4}}, request_headers
        expect(response).not_to be_success
      end

      it "requires the tool proxy to be associated to the assignment" do
        @assignment.tool_settings_tool_proxies.clear
        @assignment.save!
        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: 0.4}}, request_headers
        expect(response.code).to eq '401'
      end

      it "gives useful error message on non unique tool/file combinations" do

        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: 0.4}}, request_headers
        expect(response.status).to eq 201

        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: 0.4}}, request_headers
        expect(response.status).to eq 400
        expect(JSON.parse(response.body)['errors'].key?('base')).to be_truthy
      end

      it "requires the plagiarism feature flag" do
        Account.any_instance.stubs(:feature_enabled?).with(:plagiarism_detection_platform).returns(false)

        post @endpoints[:create], {originality_report: {file_id: @attachment.id, originality_score: 0.4}}, request_headers
        expect(response).not_to be_success
      end

      it "verifies the specified attachment is in the course" do

        attachment = @attachment.dup
        attachment.context = @course
        attachment.save!

        post @endpoints[:create], {originality_report: {file_id: attachment.id, originality_score: 0.4}}, request_headers
        expect(response.status).to eq 401
      end

      it "verifies that the specified submission includes the attachment" do

        sub = @submission.dup
        sub.attachments = []
        sub.user = @teacher
        sub.save!
        endpoint = "/api/lti/assignments/#{@assignment.id}/submissions/#{sub.id}/originality_report"
        post endpoint, originality_report: {file_id: @attachment.id, originality_score: 0.4}
        expect(response.status).to eq 401
      end

      context "optional params" do
        before :each do

          report_file = @attachment.dup
          report_file.save!

          @report = {
            file_id: @attachment.id,
            originality_score: 0.5,
            originality_report_file_id: report_file.id,
            originality_report_url: 'http://www.report-url.com',
            originality_report_lti_url: 'http://www.report-lti-url.com'
          }

          post @endpoints[:create], {originality_report: @report}, request_headers
          @response_hash = JSON.parse response.body
        end

        it "sets the attachment" do
          expect(response).to be_success
          created_report = OriginalityReport.find(@response_hash['id'])
          expect(created_report.attachment).to eq @attachment
        end
      end

      def api_create_originality_report(file_id, score)
        api_call(
          :post,
          "/api/lti/assignments/#{@assignment.id}/submissions/#{@submission.id}/originality_report",
          {
            controller: 'originality_reports_api',
            action: 'create',
            format: 'json',
            assignment_id: @assignment.id,
            submission_id: @submission.id
          },
          {
            originality_report: {
              originality_score: score,
              file_id: file_id
            }
          },
          request_headers
        )
      end
    end
  end
end
