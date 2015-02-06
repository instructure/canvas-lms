#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe BasicLTI::BasicOutcomes do
  before(:each) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
    @course.enroll_student(@user)
  end

  let(:tool) do
    @course.context_external_tools.create(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
  end

  let(:assignment) do
    @course.assignments.create!(
      {
          title: "value for title",
          description: "value for description",
          due_at: Time.now,
          points_possible: "1.5",
          submission_types: 'external_tool',
          external_tool_tag_attributes: {url: tool.url}
      }
    )
  end

  let(:source_id) {
    tool.shard.activate do
      payload = [tool.id, @course.id, assignment.id, @user.id].join('-')
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  }

  let(:xml) do
    Nokogiri::XML.parse %Q{
      <?xml version = "1.0" encoding = "UTF-8"?>
      <imsx_POXEnvelopeRequest xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXRequestHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
          </imsx_POXRequestHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
          <replaceResultRequest>
            <resultRecord>
              <sourcedGUID>
                <sourcedId>#{source_id}</sourcedId>
              </sourcedGUID>
              <result>
                <resultScore>
                  <language>en</language>
                  <textString>0.92</textString>
                </resultScore>
                <resultData>
                  <text>text data for canvas submission</text>
                </resultData>
              </result>
            </resultRecord>
          </replaceResultRequest>
        </imsx_POXBody>
      </imsx_POXEnvelopeRequest>
    }
  end

  describe "#handle_replaceResult" do
    it "accepts a grade" do
      xml.css('resultData').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'success'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.grade).to eq (assignment.points_possible * 0.92).to_s
    end

    it "accepts a result data without grade" do
      xml.css('resultScore').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'success'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.body).to eq 'text data for canvas submission'
      expect(submission.grade).to be_nil
      expect(submission.workflow_state).to eq 'submitted'
    end

    it "fails if neither result data or a grade is sent" do
      xml.css('resultData').remove
      xml.css('resultScore').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'failure'
    end
  end
end
