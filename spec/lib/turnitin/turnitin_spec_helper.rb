#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

RSpec.shared_context "shared_tii_lti", :shared_context => :metadata do
  before do
    allow(BasicLTI::Sourcedid).to receive(:encryption_secret) {'encryption-secret-5T14NjaTbcYjc4'}
    allow(BasicLTI::Sourcedid).to receive(:signing_secret) {'signing-secret-vp04BNqApwdwUYPUI'}
  end

  let(:lti_student) { user_model }
  let(:lti_course) { course_with_student({user: lti_student}).course }
  let(:tool) do
    tool = lti_course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
    )
    tool.url = "http://www.example.com/basic_lti"
    tool.resource_selection = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :selection_width => 400,
      :selection_height => 400}
    tool.save!
    tool
  end

  let(:lti_assignment) do
    assignment = assignment_model(course: lti_course)
    tag = assignment.build_external_tool_tag(url: tool.url)
    tag.content_type = 'ContextExternalTool'
    tag.content_id = tool.id
    tag.save!
    assignment
  end

  let(:attachment) do
    Attachment.create! uploaded_data: StringIO.new('blah'),
                       context: lti_course,
                       filename: 'blah.txt'
  end

  let(:tii_client) do
    tii_mock = double('tii_client')
    allow(tii_mock).to receive(:original_submission).and_yield(response_mock)
    tii_mock
  end
  let(:filename) { 'my/new/filename.txt' }
  let(:response_mock) do
    r_mock = double('response')
    allow(r_mock).to receive(:headers).
      and_return({
                'content-disposition' => "attachment; filename=#{filename}",
                'content-type' => 'plain/text'
              })
    allow(r_mock).to receive(:body).and_return('abcdef')
    r_mock
  end

  let(:outcome_response_json) do
    {
      "paperid" => 200505101,
      "outcomes_tool_placement_url" => "https://turnitin.example.com/api/lti/1p0/outcome_tool_data/201?lang=en_us",
      "lis_result_sourcedid" => Lti::LtiOutboundAdapter.new(
        tool,
        lti_student,
        lti_course
      ).encode_source_id(lti_assignment)
    }
  end

  let(:tii_response) do
    {"outcome_grademark" => {
      "text" => "--",
      "label" => "Open GradeMark",
      "roles" => ["Instructor"],
      "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/dv/grademark/200587213?lang=en_us",
      "numeric" => {"score" => nil, "max" => 10}
    },
     "outcome_pdffile" => {
       "text" => nil,
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/download/pdf/200587213?lang=en_us",
       "roles" => ["Learner", "Instructor"],
       "label" => "Download File in PDF Format"
     },
     "meta" => {
       "date_uploaded" => "2016-10-24T19:48:40Z"
     },
     "outcome_originalityreport" => {
       "label" => "Open Originality Report",
       "numeric" => {
         "max" => 100,
         "score" => nil
       },
       "roles" => ["Instructor"],
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/dv/report/200587213?lang=en_us",
       "breakdown" => {
         "submitted_works_score" => nil,
         "internet_score" => nil,
         "publications_score" => nil
       },
       "text" => "Pending"
     },
     "outcome_originalfile" => {
       "text" => nil,
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/download/orig/200587213?lang=en_us",
       "roles" => ["Learner", "Instructor"],
       "label" => "Download File in Original Format"
     },
     "outcome_resubmit" => {
       "label" => "Resubmit File",
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/upload/resubmit/200587213?lang=en_us",
       "roles" => ["Learner"],
       "text" => nil
     }
    }
  end

end
