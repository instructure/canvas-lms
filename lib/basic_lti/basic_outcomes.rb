#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'nokogiri'

module BasicLTI
  module BasicOutcomes
    class Unauthorized < StandardError
      def response_status
        401
      end
    end


    class InvalidRequest < StandardError
      def response_status
        415
      end
    end

    SOURCE_ID_REGEX = %r{^(\d+)-(\d+)-(\d+)-(\d+)-(\w+)$}

    def self.decode_source_id(tool, sourceid)
      tool.shard.activate do
        sourcedid = BasicLTI::Sourcedid.load!(sourceid)
        raise BasicLTI::Errors::InvalidSourceId, 'Tool is invalid' unless tool == sourcedid.tool
        return sourcedid.assignment, sourcedid.user
      end
    end

    def self.process_request(tool, xml)
      res = (quizzes_next_tool?(tool) ? BasicLTI::QuizzesNextLtiResponse : LtiResponse).new(xml)

      unless res.handle_request(tool)
        res.code_major = 'unsupported'
        res.description = 'Request could not be handled. ¯\_(ツ)_/¯'
      end
      res
    end

    def self.quizzes_next_tool?(tool)
      tool.tool_id == 'Quizzes 2' && tool.context.root_account.feature_enabled?(:quizzes_next_submission_history)
    end

    def self.process_legacy_request(tool, params)
      res = LtiResponse::Legacy.new(params)

      unless res.handle_request(tool)
        res.code_major = 'unsupported'
        res.description = 'Legacy request could not be handled. ¯\_(ツ)_/¯'
      end
      return res
    end

    class LtiResponse
      include TextHelper
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
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultScore > textString').try(:content)
      end

      def submission_submitted_at
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > submissionDetails > submittedAt').try(:content)
      end

      def result_total_score
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultTotalScore > textString').try(:content)
      end

      def result_data_text
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > text').try(:content)
      end

      def result_data_url
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > url').try(:content)
      end

      def result_data_download_url
        url = @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > downloadUrl').try(:content)
        name = @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > documentName').try(:content)
        return { url: url, name: name } if url && name
      end

      def result_data_launch_url
        @lti_request&.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > ltiLaunchUrl').try(:content)
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
        # check if we recognize the xml structure
        return false unless operation_ref_identifier
        # verify the lis_result_sourcedid param, which will be a canvas-signed
        # tuple of (assignment, user) to ensure that only this launch of
        # the tool is attempting to modify this data.
        source_id = self.sourcedid

        begin
          assignment, user = BasicLTI::BasicOutcomes.decode_source_id(tool, source_id)
        rescue Errors::InvalidSourceId => e
          self.code_major = 'failure'
          self.description = e.to_s
          self.body = "<#{operation_ref_identifier}Response />"
          return true
        end

        op = self.operation_ref_identifier.underscore
        if self.respond_to?("handle_#{op}", true)
          return self.send("handle_#{op}", tool, assignment, user)
        end

        false
      end

      protected

      # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
      def handle_replace_result(tool, assignment, user)
        text_value = self.result_score
        score_value = self.result_total_score
        error_message = nil
        begin
          new_score = Float(text_value)
        rescue
          new_score = false
          error_message = text_value.nil? ? nil : I18n.t('lib.basic_lti.no_parseable_score.result', <<~NO_POINTS, :grade => text_value)
            Unable to parse resultScore: %{grade}
          NO_POINTS
        end
        begin
          raw_score = Float(score_value)
        rescue
          raw_score = false
          error_message ||= score_value.nil? ? nil : I18n.t('lib.basic_lti.no_parseable_score.result_total', <<~NO_POINTS, :grade => score_value)
            Unable to parse resultTotalScore: %{grade}
          NO_POINTS
        end
        submission_hash = {}
        existing_submission = assignment.submissions.where(user_id: user.id).first
        if (text = result_data_text)
          submission_hash[:body] = text
          submission_hash[:submission_type] = 'online_text_entry'
        elsif (url = result_data_url)
          submission_hash[:url] = url
          submission_hash[:submission_type] = 'online_url'
        elsif (result_data = result_data_download_url)
          url = result_data[:url]
          attachment = Attachment.create!(
            shard: user.shard,
            context: user,
            file_state: 'deleted',
            workflow_state: 'unattached',
            filename: result_data[:name],
            display_name: result_data[:name],
            user: user
          )

          submission_hash[:attachments] = [attachment]
          submission_hash[:submission_type] = 'online_upload'
        elsif (launch_url = result_data_launch_url)
          submission_hash[:url] = launch_url
          submission_hash[:submission_type] = 'basic_lti_launch'
        elsif !existing_submission || existing_submission.submission_type.blank?
          submission_hash[:submission_type] = 'external_tool'
        end

        if raw_score
          submission_hash[:grade] = raw_score
          submission_hash[:grader_id] = -tool.id
        elsif new_score
          if (0.0..1.0).cover?(new_score)
            submission_hash[:grade] = "#{round_if_whole(new_score * 100)}%"
            submission_hash[:grader_id] = -tool.id
          else
            error_message = I18n.t('lib.basic_lti.bad_score', "Score is not between 0 and 1")
          end
        elsif !error_message && !text && !url && !launch_url
          error_message = I18n.t('lib.basic_lti.no_score', "No score given")
        end

        submitted_at = submission_submitted_at
        submitted_at_date = submitted_at.present? ? Time.zone.parse(submitted_at) : nil
        if submitted_at.present? && submitted_at_date.nil?
          error_message = I18n.t('Invalid timestamp - timestamp not parseable')
        elsif submitted_at_date.present? && submitted_at_date > Time.zone.now + 1.minute
          error_message = I18n.t('Invalid timestamp - timestamp in future')
        end

        if error_message
          self.code_major = 'failure'
          self.description = error_message
        elsif assignment.grading_type != "pass_fail" && (assignment.points_possible.nil?)

          unless submission = existing_submission
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
          if attachment
            job_options = {
              :priority => Delayed::HIGH_PRIORITY,
              :max_attempts => 1,
              :n_strand => Attachment.clone_url_strand(url)
            }

            send_later_enqueue_args(
              :fetch_attachment_and_save_submission,
              job_options,
              url,
              attachment,
              tool,
              submission_hash,
              assignment,
              user,
              new_score,
              raw_score
            )
          else
            create_homework_submission tool, submission_hash, assignment, user, new_score, raw_score, submitted_at_date
          end
        end

        self.body = "<replaceResultResponse />"

        true
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength

      # rubocop:disable Metrics/ParameterLists
      def create_homework_submission(tool, submission_hash, assignment, user, new_score, raw_score, submitted_at_date=nil)
        if submission_hash[:submission_type].present? && submission_hash[:submission_type] != 'external_tool'
          @submission = assignment.submit_homework(user, submission_hash.clone)
        end

        if new_score || raw_score
          submission_hash[:grade] = (new_score >= 1 ? "pass" : "fail") if assignment.grading_type == "pass_fail"
          submission_hash[:grader_id] = -tool.id
          @submission = assignment.grade_student(user, submission_hash).first
          if submission_hash[:submission_type] == 'external_tool' && submitted_at_date.nil?
            @submission.submitted_at = Time.zone.now
          end
        end

        if submitted_at_date.present?
          @submission.submitted_at = submitted_at_date
        end

        if @submission
          @submission.attempt -= 1 if @submission.attempt.try(:'>', 0) && @submission.submitted_at_changed?
          @submission.save
        else
          self.code_major = 'failure'
          self.description = I18n.t('lib.basic_lti.no_submission_created', 'This outcome request failed to create a new homework submission.')
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def handle_delete_result(tool, assignment, user)
        assignment.grade_student(user, :grade => nil, grader_id: -tool.id)
        self.body = "<deleteResultResponse />"
        true
      end

      def handle_read_result(_, assignment, user)
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

      # rubocop:disable Metrics/ParameterLists
      def fetch_attachment_and_save_submission(url, attachment, tool, submission_hash, assignment, user, new_score, raw_score)
        attachment.clone_url(url, 'rename', true)
        create_homework_submission tool, submission_hash, assignment, user, new_score, raw_score
      end
      # rubocop:enable Metrics/ParameterLists

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
