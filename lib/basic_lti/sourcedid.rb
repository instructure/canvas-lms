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

module BasicLTI
  class Sourcedid
    SOURCE_ID_REGEX = %r{^(\d+)-(\d+)-(\d+)-(\d+)-(\w+)$}

    attr_reader :tool, :course, :assignment, :user

    def initialize(tool, course, assignment, user)
      @tool, @course, @assignment, @user = tool, course, assignment, user
    end

    def to_s
      crypted_token = Canvas::Security.create_encrypted_jwt(
        jwt_payload,
        self.class.signing_secret,
        self.class.encryption_secret
      )
      Canvas::Security.base64_encode(crypted_token)
    end

    def jwt_payload
      {
        iss: "Canvas",
        aud: ["Instructure"],
        iat: Time.zone.now.to_i,
        tool_id: tool.id,
        course_id: course.id,
        assignment_id: assignment.id,
        user_id: user.id,
      }
    end
    private :jwt_payload

    def validate!
      raise Errors::InvalidSourceId, 'Course is invalid' unless course
      raise Errors::InvalidSourceId, 'User is no longer in course' unless user
      raise Errors::InvalidSourceId, 'Assignment is invalid' unless assignment

      tag = assignment.external_tool_tag
      raise Errors::InvalidSourceId, 'Assignment is no longer associated with this tool' unless tag && tool.
          matches_url?(tag.url, false) && tool.workflow_state != 'deleted'
    end

    def self.load!(sourcedid_string)
      raise Errors::InvalidSourceId, 'Invalid sourcedid' if sourcedid_string.blank?
      token = load_from_legacy_sourcedid!(sourcedid_string) ||
        token_from_sourcedid!(sourcedid_string)

      tool = ContextExternalTool.find_by(id: token[:tool_id])
      course = Course.active.find_by(id: token[:course_id])
      if course
        user = course.student_enrollments.active.find_by(user_id: token[:user_id])&.user
        assignment = course.assignments.active.find_by(id: token[:assignment_id])
      end

      sourcedid = self.new(tool, course, assignment, user)
      sourcedid.validate!
      sourcedid
    end

    def self.load_from_legacy_sourcedid!(sourcedid)
      token = nil
      md = sourcedid.match(SOURCE_ID_REGEX)
      if md
        tool = ContextExternalTool.find_by(id: md[1])
        raise Errors::InvalidSourceId, 'Tool is invalid' unless tool
        new_encoding = [md[1], md[2], md[3], md[4]].join('-')
        raise Errors::InvalidSourceId, 'Invalid signature' unless Canvas::Security.
            verify_hmac_sha1(md[5], new_encoding, key: tool.shard.settings[:encryption_key])
        token = { tool_id: md[1].to_i, course_id: md[2], assignment_id: md[3], user_id: md[4] }
      end
      token
    end

    def self.token_from_sourcedid!(sourcedid)
      Canvas::Security.decrypt_services_jwt(
        Canvas::Security.base64_decode(sourcedid),
        signing_secret,
        encryption_secret
      )
    rescue JSON::JWT::InvalidFormat
      raise Errors::InvalidSourceId, 'Invalid sourcedid'
    end

    def self.signing_secret
      Canvas::DynamicSettings.find()["lti-signing-secret"]
    end

    def self.encryption_secret
      Canvas::DynamicSettings.find()["lti-encryption-secret"]
    end
  end
end
