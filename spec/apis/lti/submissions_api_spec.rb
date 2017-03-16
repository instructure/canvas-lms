require File.expand_path(File.dirname(__FILE__) + '/lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

require_dependency "lti/ims/access_token_helper"
require_dependency "lti/submissions_api_controller"
module Lti
  describe SubmissionsApiController, type: :request do
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
        get endpoint, {}, request_headers
        expect(response.code).to eq '401'
      end

      it "returns a 401 if the tool is not associated with the assignment" do
        assignment.tool_settings_tool = []
        assignment.save!
        get endpoint, {}, request_headers
        expect(response.code).to eq '401'
      end

      it "returns a 401 if the tool is not in the context" do
        a = Account.create!
        tool_proxy.context_id = a.id
        tool_proxy.save!
        tool_proxy_binding.context_id = a.id
        tool_proxy_binding.save!
        get endpoint, {}, request_headers
        expect(response.code).to eq '401'
      end

    end

    describe "#show" do
      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}" }
      include_examples "authorization"

      it "returns a submission json object" do
        now = Time.now.utc
        Timecop.freeze(now) do
          get endpoint, {}, request_headers
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
                       "url" => controller.attachment_url(attachment.id),
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


    end

    describe "#history" do

      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/history" }
      include_examples "authorization"
      it "returns the submission history as an array of JSON objects" do
        now = Time.now.utc
        Timecop.freeze(now) do
          get endpoint, {}, request_headers
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
                       "url" => controller.attachment_url(attachment.id),
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

        get endpoint, {}, request_headers
        json = JSON.parse(response.body)
        expect(json[0]["attachments"].first["id"]).to_not equal json[1]["attachments"].first["id"]
      end
    end

    describe "#attachment" do

      let(:endpoint) { "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/attachment/#{attachment.id}" }
      include_examples 'authorization'

      it "allows a user to download a file" do
        get "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}", {}, request_headers
        json = JSON.parse(response.body)
        url = json["attachments"].first["url"]
        get url, {}, request_headers
        expect(response.content_type.to_s).to eq attachment.content_type
      end

      it "returns a 401 if the attachment isn't associated to the assignment" do
        get "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}", {}, request_headers
        attachment1 = Attachment.create!(context: Account.create!, filename: "test.txt", content_type: "text/plain")
        endpoint = "/api/lti/assignments/#{assignment.id}/submissions/#{submission.id}/attachment/#{attachment1.id}"
        get controller.attachment_url(attachment1.id), {}, request_headers
        expect(response.code).to eq "401"
      end

    end

  end
end
