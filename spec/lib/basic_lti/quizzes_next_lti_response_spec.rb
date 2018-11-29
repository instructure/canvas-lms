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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe BasicLTI::QuizzesNextLtiResponse do
  before(:each) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, :name => "some user", :workflow_state => "registered")
    @course.enroll_student(@user)
  end

  let(:tool) do
    @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: '12345', shared_secret: 'secret', tool_id: "Quizzes 2")
  end

  let(:assignment) do
    @course.assignments.create!(
      {
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now,
        points_possible: "1.5",
        submission_types: 'external_tool',
        external_tool_tag_attributes: {url: tool.url}
      }
    )
  end

  let(:source_id) { gen_source_id }

  let(:launch_url) { 'https://abcdef.com/uuurrrlll00' }

  let(:xml) do
    request_xml(source_id, launch_url, "0.12")
  end

  def gen_source_id(t: tool, c: @course, a: assignment, u: @user)
    tool.shard.activate do
      payload = [t.id, c.id, a.id, u.id].join('-')
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  end

  def request_xml(source_id, launch_url, grade)
    Nokogiri::XML.parse %{
      <?xml version="1.0" encoding="UTF-8"?>
      <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXRequestHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>8d4280b4-0e6f-484f-918d-efa4d0a5910e</imsx_messageIdentifier>
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
                  <textString>#{grade}</textString>
                </resultScore>
                <resultData>
                  <ltiLaunchUrl>#{launch_url}</ltiLaunchUrl>
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
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'success'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.handle_request(tool)).to be_truthy
      submission = assignment.submissions.where(user_id: @user.id).first
      expect(submission.grade).to eq((assignment.points_possible * 0.12).to_s)
    end

    it "rejects a grade for an assignment with no points possible" do
      xml.css('resultData').remove
      assignment.points_possible = nil
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment has no points possible.'
    end

    it "doesn't explode when an assignment with no points possible receives a grade for an existing submission " do
      xml.css('resultData').remove
      assignment.points_possible = nil
      assignment.save!
      BasicLTI::BasicOutcomes.process_request(tool, xml)
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)

      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment has no points possible.'
    end

    it 'handles tools that have a url mismatch with the assignment' do
      assignment.external_tool_tag_attributes = {url: 'http://example.com/foo'}
      assignment.save!
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
      expect(request.description).to eq 'Assignment is no longer associated with this tool'
    end

    it "fails if neither result data or a grade is sent" do
      xml.css('resultData').remove
      xml.css('resultScore').remove
      request = BasicLTI::BasicOutcomes.process_request(tool, xml)
      expect(request.code_major).to eq 'failure'
      expect(request.body).to eq '<replaceResultResponse />'
    end

    it "sets 'submitted_at' to the current time" do
      Timecop.freeze do
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at).to eq Time.zone.now
      end
    end

    context 'with submitted_at details' do
      let(:timestamp) { 1.day.ago.iso8601(3) }

      it "sets submitted_at to submitted_at details if resultData is present" do
        xml.at_css('imsx_POXBody > replaceResultRequest').add_child(
          "<submissionDetails><submittedAt>#{timestamp}</submittedAt></submissionDetails>"
        )
        BasicLTI::BasicOutcomes.process_request(tool, xml)
        submission = assignment.submissions.where(user_id: @user.id).first
        expect(submission.submitted_at.iso8601(3)).to eq timestamp
      end
    end

    context "submissions" do
      it "creates a new submission if there isn't one" do
        expect{BasicLTI::BasicOutcomes.process_request(tool, xml)}.
          to change{assignment.submissions.not_placeholder.where(user_id: @user.id).count}.from(0).to(1)
        expect(assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count).to be(1)
      end

      context "with previous versions" do
        let(:launch_urls) do
          [
            'https://abcdef.com/uuurrrlll01',
            'https://abcdef.com/uuurrrlll02',
            'https://abcdef.com/uuurrrlll03'
          ]
        end

        let(:grades) { [0.11, 0.22, 0.33] }

        before do
          BasicLTI::BasicOutcomes.process_request(tool, xml)
          submission = assignment.submissions.first
          (0..2).each do |i|
            grade = "#{TextHelper.round_if_whole(grades[i] * 100)}%"
            grade, score = assignment.compute_grade_and_score(grade, nil)
            submission.grade = grade
            submission.score = score
            submission.submission_type = 'basic_lti_launch'
            submission.workflow_state = 'submitted'
            submission.submitted_at = Time.zone.now
            submission.url = launch_urls[i]
            submission.grader_id = -1
            submission.with_versioning(:explicit => true) { submission.save! }
          end
        end

        it "doesn't add a version if last score and url of a submission are same" do
          expect {
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[2], grades[2])
            )
          }.
            not_to change{
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }
        end

        it "doesn't add a version if last score of a submission is different, but urls are same" do
          expect {
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[2], grades[1])
            )
          }.
            not_to change{
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }
        end

        it "adds a version if last url of a submission is different" do
          expect {
            BasicLTI::BasicOutcomes.process_request(
              tool,
              request_xml(source_id, launch_urls[1], grades[2])
            )
          }.
            to change{
              assignment.submissions.not_placeholder.where(user_id: @user.id).first.versions.count
            }.from(4).to(5)
        end
      end
    end
  end
end
