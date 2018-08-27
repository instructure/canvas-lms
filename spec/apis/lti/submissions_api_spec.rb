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
#

require File.expand_path(File.dirname(__FILE__) + '/lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

require_dependency "lti/ims/access_token_helper"
require_dependency "lti/submissions_api_controller"
module Lti
  describe SubmissionsApiController, type: :request do
    specs_require_sharding
    include_context 'lti2_api_spec_helper'

    let(:service_name) { SubmissionsApiController::SUBMISSION_SERVICE }

    let(:submission) do
      assignment.submit_homework(student, submission_type: 'online_upload',
                                 attachments: [attachment])
    end

    let(:mock_file) do
      stub_file_data('myfile.txt', nil, "plain/txt")
    end

    let(:attachment) do
      student.attachments.create! uploaded_data: dummy_io, filename: 'doc.doc', display_name: 'doc.doc', context: student
    end

    let(:assignment) do
      a = course.assignments.new(:title => "some assignment")
      a.workflow_state = "published"
      a.tool_settings_tool = message_handler
      a.save!
      a
    end

    let(:student) { course_with_student(active_all: true, course: course); @user }

    let(:aud) { host }

    let(:other_tool_proxy) do
      tp = tool_proxy.dup
      tp.update_attributes(guid: other_tp_guid)
      tp
    end

    let(:other_tp_guid) { SecureRandom.uuid }

    before do
      mock_sub_helper = instance_double("Lti::AssignmentSubscriptionsHelper",
                                        create_subscription: "123",
                                        destroy_subscription: nil)
      allow(Lti::AssignmentSubscriptionsHelper).to receive(:new).and_return(mock_sub_helper)
      tool_proxy.raw_data['enabled_capability'] << ResourcePlacement::SIMILARITY_DETECTION_LTI2
      tool_proxy.save!
    end

    RSpec.shared_examples "authorization" do
      it "returns a 401 if no auth token" do
        get endpoint
        expect(response.code).to eq '401'
      end

      it "returns a 401 if the tool doesn't have a similarity detection placement" do
        tool_proxy.raw_data['enabled_capability'] = []
        tool_proxy.save!
        get endpoint, headers: request_headers
        expect(response.code).to eq '401'
      end

      it "returns a 401 if the tool is not associated with the assignment" do
        assignment.tool_settings_tool = []
        assignment.save!
        get endpoint, headers: request_headers
        expect(response.code).to eq '401'
      end

      it "returns a 401 if the tool is not in the context" do
        a = Account.create!
        tool_proxy.context_id = a.id
        tool_proxy.save!
        tool_proxy_binding.context_id = a.id
        tool_proxy_binding.save!
        get endpoint, headers: request_headers
        expect(response.code).to eq '401'
      end

      it "allows tool proxies with matching access" do
        tool_proxy.raw_data['tool_profile'] = tool_profile
        tool_proxy.raw_data['security_contract'] = security_contract
        tool_proxy.save!
        token = Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: other_tool_proxy.guid)
        other_helpers = {Authorization: "Bearer #{token}"}
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).and_return(true)
        get endpoint, headers: other_helpers
        expect(response).not_to be '401'
      end

    end

    describe "#show" do
      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}" }
      include_examples "authorization"

      it "returns a submission json object" do
        now = Time.now.utc
        Timecop.freeze(now) do
          get endpoint, headers: request_headers
          expect(JSON.parse(response.body)).to(
            eq({
                 "id" => submission.id,
                 "body" => nil,
                 "url" => nil,
                 "submitted_at" => now.iso8601,
                 "assignment_id" => assignment.id,
                 "user_id" => Lti::Asset.opaque_identifier_for(student),
                 "submission_type" => "online_upload",
                 "workflow_state" => "submitted",
                 "attempt" => 1,
                 "attachments" =>
                   [
                     {
                       "id" => attachment.id,
                       "size" => attachment.size,
                       "url" => controller.attachment_url(attachment),
                       "filename" => attachment.filename,
                       "display_name" => attachment.display_name,
                       "created_at" => now.iso8601,
                       "updated_at" => now.iso8601
                     }
                   ]
               })
          )
        end
      end

      it 'uses global ids in the attachment download URL' do
        get endpoint, headers: request_headers
        expect(JSON.parse(response.body)['attachments'].first['url']).to include(
          attachment.global_id.to_s,
          assignment.global_id.to_s,
          submission.global_id.to_s
        )
      end

      it 'includes the eula agreement timestamp if present' do
        submission.turnitin_data[:eula_agreement_timestamp] = Time.now.to_i
        submission.save!
        get endpoint, headers: request_headers
        expect(JSON.parse(response.body)['eula_agreement_timestamp']).to eq submission.turnitin_data[:eula_agreement_timestamp]
      end
    end

    describe "#history" do

      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/history" }
      include_examples "authorization"
      it "returns the submission history as an array of JSON objects" do
        now = Time.now.utc
        Timecop.freeze(now) do
          get endpoint, headers: request_headers
          expect(JSON.parse(response.body)).to(
            match_array(
              [{
                 "id" => submission.id,
                 "body" => nil,
                 "url" => nil,
                 "submitted_at" => now.iso8601,
                 "assignment_id" => assignment.id,
                 "user_id" => Lti::Asset.opaque_identifier_for(student),
                 "submission_type" => "online_upload",
                 "workflow_state" => "submitted",
                 "attempt" => 1,
                 "attachments" =>
                   [
                     {
                       "id" => attachment.id,
                       "size" => attachment.size,
                       "url" => controller.attachment_url(attachment),
                       "filename" => attachment.filename,
                       "display_name" => attachment.display_name,
                       "created_at" => now.iso8601,
                       "updated_at" => now.iso8601
                     }
                   ]
               }]
            )
          )
        end
      end

      it "sends back versioned attachments" do
        attachments = [attachment_model(filename: "submission-a.doc", :context => student)]
        Timecop.freeze(10.second.ago) do
          assignment.submit_homework(student, submission_type: 'online_upload',
                                     attachments: [attachments[0]])
        end

        attachments << attachment_model(filename: "submission-b.doc", :context => student)
        Timecop.freeze(5.second.ago) do
          assignment.submit_homework student, attachments: [attachments[1]]
        end

        attachments << attachment_model(filename: "submission-c.doc", :context => student)
        Timecop.freeze(1.second.ago) do
          assignment.submit_homework student, attachments: [attachments[2]]
        end

        get endpoint, headers: request_headers
        json = JSON.parse(response.body)
        expect(json[0]["attachments"].first["id"]).to_not equal json[1]["attachments"].first["id"]
      end
    end

    describe "#attachment" do

      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/attachment/#{attachment.id}" }
      include_examples 'authorization'

      it "allows a user to download a file" do
        get "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}", headers: request_headers
        json = JSON.parse(response.body)
        url = json["attachments"].first["url"]
        get url, headers: request_headers
        expect(response.content_type.to_s).to eq attachment.content_type
      end

      it "returns a 401 if the attachment isn't associated to the assignment" do
        get "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}", headers: request_headers
        attachment1 = Attachment.create!(context: Account.create!, filename: "test.txt", content_type: "text/plain")
        endpoint = "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/attachment/#{attachment1.id}"
        get controller.attachment_url(attachment1), headers: request_headers
        expect(response.code).to eq "401"
      end

      context 'sharding' do
        it 'retrieves attachments when tool proxy is installed on another shard' do
          get "/api/lti/assignments/#{assignment.global_id}/submissions/#{submission.global_id}", headers: request_headers
          json = JSON.parse(response.body)
          url = json["attachments"].first["url"]

          @shard2.activate do
            get url, headers: request_headers
            expect(response).to be_successful
            expect(response.content_type.to_s).to eq attachment.content_type
          end
        end
      end

    end

    describe 'service' do
      it 'has the correct endpoint for submission service' do
        service_url = SubmissionsApiController::SERVICE_DEFINITIONS.first[:endpoint]
        expect(service_url).to eq 'api/lti/assignments/{assignment_id}/submissions/{submission_id}'
      end

      it 'has the correct endpoint for submission history service' do
        service_url = SubmissionsApiController::SERVICE_DEFINITIONS.last[:endpoint]
        expect(service_url).to eq 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/history'
      end
    end

  end
end
