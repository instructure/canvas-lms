# frozen_string_literal: true

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

describe BasicLTI::Sourcedid do
  subject(:sourcedid) { described_class.new(tool, course, assignment, user) }

  let(:tool) { external_tool_model(context: course) }
  let(:course) { course_model }
  let(:assignment) do
    course.assignments.create!(
      {
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now,
        points_possible: "1.5",
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: tool.url }
      }
    )
  end
  let(:user) { course_with_student(course:).user }

  before do
    fake_lti_secrets = {
      "lti-signing-secret" => Base64.encode64("signing-secret-vp04BNqApwdwUYPUI"),
      "lti-encryption-secret" => Base64.encode64("encryption-secret-5T14NjaTbcYjc4")
    }

    allow(Rails.application.credentials).to receive(:dig)
      .with(:lti, :signing_secret)
      .and_return(fake_lti_secrets["lti-signing-secret"])

    allow(Rails.application.credentials).to receive(:dig)
      .with(:lti, :encryption_secret)
      .and_return(fake_lti_secrets["lti-encryption-secret"])
  end

  it "creates a signed and encrypted sourcedid" do
    timestamp = Time.zone.now
    allow(Time.zone).to receive(:now).and_return(timestamp)

    token = BasicLTI::Sourcedid.token_from_sourcedid!(sourcedid.to_s)

    expect(token[:iss]).to eq "Canvas"
    expect(token[:aud]).to eq ["Instructure"]
    expect(token[:iat]).to eq timestamp.to_i
    expect(token[:tool_id]).to eq tool.id
    expect(token[:course_id]).to eq course.id
    expect(token[:assignment_id]).to eq assignment.id
    expect(token[:user_id]).to eq user.id
  end

  describe ".load!" do
    it "raises an exception for an invalid sourcedid" do
      expect { described_class.load!("invalid-sourcedid") }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "Invalid sourcedid"
      )
    end

    it "raises an exception for a nil sourcedid" do
      expect { described_class.load!(nil) }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "Invalid sourcedid"
      )
    end

    context "legacy sourcedid" do
      it "raises an exception when improperly signed" do
        sourcedid = "#{tool.id}-#{course.id}-#{assignment.id}-#{user.id}-badsignature"
        expect { described_class.load!(sourcedid) }.to raise_error(
          BasicLTI::Errors::InvalidSourceId, "Invalid signature"
        )
      end

      it "raises an exception when the tool id is invalid" do
        sourcedid = "9876543210-#{course.id}-#{assignment.id}-#{user.id}-badsignature"
        expect { described_class.load!(sourcedid) }.to raise_error(
          BasicLTI::Errors::InvalidSourceId, "Tool is invalid"
        )
      end

      it "builds a sourcedid" do
        payload = [tool.id, course.id, assignment.id, user.id].join("-")
        legacy_sourcedid = "#{payload}-#{Canvas::Security.hmac_sha1(payload)}"

        sourcedid = described_class.load!(legacy_sourcedid)

        expect(sourcedid.tool).to eq tool
        expect(sourcedid.course).to eq course
        expect(sourcedid.assignment).to eq assignment
        expect(sourcedid.user).to eq user
      end
    end

    it "raises an exception when the course is invalid" do
      course.destroy!

      expect { described_class.load!(sourcedid.to_s) }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "Course is invalid"
      )
    end

    it "raises an exception when the user is not in the course" do
      user.enrollments.find_by(course_id: course.id).destroy!

      expect { described_class.load!(sourcedid.to_s) }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "User is no longer in course"
      )
    end

    it "raises an exception when the assignment is not valid" do
      assignment.destroy!

      expect { described_class.load!(sourcedid.to_s) }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "Assignment is invalid"
      )
    end

    it "raises an exception when the assignment is not associated with the tool" do
      assignment.external_tool_tag.update(url: "http://invalidurl.com")

      expect { described_class.load!(sourcedid.to_s) }.to raise_error(
        BasicLTI::Errors::InvalidSourceId, "Assignment is no longer associated with this tool"
      )
    end
  end
end
