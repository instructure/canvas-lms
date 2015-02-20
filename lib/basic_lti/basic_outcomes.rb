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
module BasicLTI
  module BasicOutcomes
    class Unauthorized < Exception;
    end

    class InvalidSourceId < Exception;
    end

    SOURCE_ID_REGEX = %r{^(\d+)-(\d+)-(\d+)-(\d+)-(\w+)$}

    def self.decode_source_id(tool, sourceid)
      tool.shard.activate do
        md = sourceid.match(SOURCE_ID_REGEX)
        raise InvalidSourceId, 'Invalid sourcedid' unless md
        new_encoding = [md[1], md[2], md[3], md[4]].join('-')
        return false unless Canvas::Security.verify_hmac_sha1(md[5], new_encoding, key: tool.shard.settings[:encryption_key])
        return false unless tool.id == md[1].to_i
        course = Course.active.where(id: md[2]).first
        raise InvalidSourceId, 'Course is invalid' unless course

        user = course.student_enrollments.active.where(user_id: md[4]).first.try(:user)
        raise InvalidSourceId, 'User is no longer in course' unless user

        assignment = course.assignments.active.where(id: md[3]).first
        raise InvalidSourceId, 'Assignment is invalid' unless assignment

        tag = assignment.external_tool_tag if assignment
        raise InvalidSourceId, 'Assignment is no longer associated with this tool' unless tag and tool.matches_url?(tag.url, false) and tool.workflow_state != 'deleted'

        return course, assignment, user
      end
    end

    def self.process_request(tool, xml)
      res = LtiResponse.new(xml)

      unless res.handle_request(tool)
        res.code_major = 'unsupported'
      end
      return res
    end

    def self.process_legacy_request(tool, params)
      res = LtiResponse::Legacy.new(params)

      unless res.handle_request(tool)
        res.code_major = 'unsupported'
      end
      return res
    end

    class LtiResponse
      attr_accessor :code_major, :severity, :description, :body

      def initialize(lti_request)
        @lti_request = lti_request
        self.code_major = 'success'
        self.severity = 'status'
      end

      def sourcedid
        @lti_request.at_css('imsx_POXBody sourcedGUID > sourcedId').try(:content)
      end

      def message_ref_identifier
        @lti_request.at_css('imsx_POXHeader imsx_messageIdentifier').try(:content)
      end

      def operation_ref_identifier
        tag = @lti_request.at_css('imsx_POXBody *:first').try(:name)
        tag && tag.sub(%r{Request$}, '')
      end

      def result_score
        @lti_request.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultScore > textString').try(:content)
      end

      def result_total_score
        @lti_request.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultTotalScore > textString').try(:content)
      end

      def result_data_text
        @lti_request && @lti_request.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > text').try(:content)
      end

      def result_data_url
        @lti_request && @lti_request.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > url').try(:content)
      end

      def to_xml
        xml = LtiResponse.envelope.dup
        xml.at_css('imsx_POXHeader imsx_statusInfo imsx_codeMajor').content = code_major
        xml.at_css('imsx_POXHeader imsx_statusInfo imsx_severity').content = severity
        xml.at_css('imsx_POXHeader imsx_statusInfo imsx_description').content = description
        xml.at_css('imsx_POXHeader imsx_statusInfo imsx_messageRefIdentifier').content = message_ref_identifier
        xml.at_css('imsx_POXHeader imsx_statusInfo imsx_operationRefIdentifier').content = operation_ref_identifier
        xml.at_css('imsx_POXBody').inner_html = body if body.present?
        xml.to_s
      end

      def self.envelope
        return @envelope if @envelope
        @envelope = Nokogiri::XML.parse <<-XML
      <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXResponseHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier></imsx_messageIdentifier>
            <imsx_statusInfo>
              <imsx_codeMajor></imsx_codeMajor>
              <imsx_severity>status</imsx_severity>
              <imsx_description></imsx_description>
              <imsx_messageRefIdentifier></imsx_messageRefIdentifier> 
              <imsx_operationRefIdentifier></imsx_operationRefIdentifier> 
            </imsx_statusInfo>
          </imsx_POXResponseHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
        </imsx_POXBody>
      </imsx_POXEnvelopeResponse>
        XML
        @envelope.encoding = 'UTF-8'
        @envelope
      end

      def handle_request(tool)
        # verify the lis_result_sourcedid param, which will be a canvas-signed
        # tuple of (course, assignment, user) to ensure that only this launch of
        # the tool is attempting to modify this data.
        source_id = self.sourcedid

        begin
          course, assignment, user = BasicLTI::BasicOutcomes.decode_source_id(tool, source_id) if source_id
        rescue InvalidSourceId => e
          self.code_major = 'failure'
          self.description = e.to_s
          return true
        end

        op = self.operation_ref_identifier
        if self.respond_to?("handle_#{op}", true)
          return self.send("handle_#{op}", tool, course, assignment, user)
        end

        false
      end

      protected

      def handle_replaceResult(tool, course, assignment, user)
        text_value = self.result_score
        new_score = Float(text_value) rescue false
        raw_score = Float(self.result_total_score) rescue false
        error_message = nil
        submission_hash = {:submission_type => 'external_tool'}

        if text = result_data_text
          submission_hash[:body] = text
          submission_hash[:submission_type] = 'online_text_entry'
        elsif url = result_data_url
          submission_hash[:url] = url
          submission_hash[:submission_type] = 'online_url'
        end

        if raw_score
          submission_hash[:grade] = raw_score
        elsif new_score
          if (0.0 .. 1.0).include?(new_score)
            submission_hash[:grade] = "#{new_score * 100}%"
          else
            error_message = I18n.t('lib.basic_lti.bad_score', "Score is not between 0 and 1")
          end
        elsif !text && !url
          error_message = I18n.t('lib.basic_lti.no_score', "No score given")
        end

        if error_message
          self.code_major = 'failure'
          self.description = error_message
        elsif assignment.points_possible.nil?

          unless submission = Submission.where(user_id: user.id, assignment_id: assignment).first
            submission = Submission.create!(submission_hash.merge(:user => user,
                                                                  :assignment => assignment))
          end
          submission.submission_comments.create!(:comment => I18n.t('lib.basic_lti.no_points_comment', <<-NO_POINTS, :grade => submission_hash[:grade]))
An external tool attempted to grade this assignment as %{grade}, but was unable
to because the assignment has no points possible.
          NO_POINTS
          self.code_major = 'failure'
          self.description = I18n.t('lib.basic_lti.no_points_possible', 'Assignment has no points possible.')
        else
          if submission_hash[:submission_type] != 'external_tool'
            @submission = assignment.submit_homework(user, submission_hash.clone)
          end

          if new_score || raw_score
            @submission = assignment.grade_student(user, submission_hash).first
          end

          unless @submission
            self.code_major = 'failure'
            self.description = I18n.t('lib.basic_lti.no_submission_created', 'This outcome request failed to create a new homework submission.')
          end

          self.body = "<replaceResultResponse />"
        end

        true
      end

      def handle_deleteResult(tool, course, assignment, user)
        assignment.grade_student(user, :grade => nil)
        self.body = "<deleteResultResponse />"
        true
      end

      def handle_readResult(tool, course, assignment, user)
        @submission = assignment.submission_for_student(user)
        self.body = %{
        <readResultResponse>
          <result>
            <resultScore>
              <language>en</language>
              <textString>#{submission_score}</textString>
            </resultScore>
          </result>
        </readResultResponse>
      }
        true
      end

      def submission_score
        if @submission.try(:graded?)
          raw_score = @submission.assignment.score_to_grade_percent(@submission.score)
          raw_score / 100.0
        end
      end

      class Legacy < LtiResponse
        def initialize(params)
          super(nil)
          @params = params
        end

        def sourcedid
          @params[:sourcedid]
        end

        def result_score
          @params[:result_resultscore_textstring]
        end

        def operation_ref_identifier
          case @params[:lti_message_type].try(:downcase)
            when 'basic-lis-updateresult'
              'replaceResult'
            when 'basic-lis-readresult'
              'readResult'
            when 'basic-lis-deleteresult'
              'deleteResult'
          end
        end

        def to_xml
          xml = LtiResponse::Legacy.envelope.dup
          xml.at_css('message_response > statusinfo > codemajor').content = code_major.capitalize
          if score = submission_score
            xml.at_css('message_response > result > sourcedid').content = sourcedid
            xml.at_css('message_response > result > resultscore > textstring').content = score
          else
            xml.at_css('message_response > result').remove
          end
          xml.to_s
        end

        def self.envelope
          return @envelope if @envelope
          @envelope = Nokogiri::XML.parse <<-XML
        <message_response>
          <lti_message_type></lti_message_type>
          <statusinfo>
            <codemajor></codemajor>
            <severity>Status</severity>
            <codeminor>fullsuccess</codeminor>
          </statusinfo>
          <result>
            <sourcedid></sourcedid>
            <resultscore>
              <resultvaluesourcedid>decimal</resultvaluesourdedid>
              <textstring></textstring>
              <language>en-US</language>
            </resultscore>
          </result>
        </message_response>
          XML
          @envelope.encoding = 'UTF-8'
          @envelope
        end

      end
    end
  end
end
