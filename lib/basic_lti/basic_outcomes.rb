# frozen_string_literal: true

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

require "nokogiri"

# A collection of classes related to LTI 1.1 Grade Passback.
# - Errors used during grade passback requests
# - SourcedId: a canvas-signed tuple of user data used to confirm that only the specific
#     tool launch can modify the given score.
# - BasicOutcomes: responds to grade passback requests by modifying submission data.
#     Conforms to LTI 1.1 spec and parses request and response XML.
# - QuizzesNext*: a group of classes for the special case of responding to a grade
#     passback request from the New Quizzes app. Includes some special behavior for
#     reverting to a previous score.
module BasicLTI
  # Handles LTI 1.1 Grade Passback requests. In charge of decoding the sourcedid
  # parameter to get necessary context, then delegates to one of three related
  # classes for the actual request parsing, data modification, and response.
  # Exposes an LtiResponse to the caller (the LtiApiController).
  #
  # Note that Quizzes has a special workflow that overrides some of the functionality
  # of the base LtiResponse class (namely #handle_replace_request), contained in the
  # quizzes_next_* files, not in this one. It's easy to think of this file when someone mentions
  # "LTI grade passback" or "basic outcomes", but make sure to double-check whether
  # that is coming from quizzes or from an external vendor.
  module BasicOutcomes
    class Unauthorized < StandardError
      def initialize(msg)
        InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.bad_requests",
                                     tags: { error_code: "Unauthorized" })
        super(msg)
      end

      def response_status
        401
      end
    end

    class InvalidRequest < StandardError
      def initialize(msg)
        InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.bad_requests",
                                     tags: { error_code: "InvalidRequest" })
        super(msg)
      end

      def response_status
        415
      end
    end

    # gives instfs about 7 hours to have an outage and eventually take the file
    MAX_ATTEMPTS = 10

    SOURCE_ID_REGEX = /^(\d+)-(\d+)-(\d+)-(\d+)-(\w+)$/

    def self.decode_source_id(tool, sourceid)
      tool.shard.activate do
        sourcedid = BasicLTI::Sourcedid.load!(sourceid)
        raise BasicLTI::Errors::InvalidSourceId.new("Tool is invalid", :tool_invalid) unless tool == sourcedid.tool

        return sourcedid.assignment, sourcedid.user
      end
    end

    def self.process_request(tool, xml)
      InstStatsd::Statsd.time("lti.1_1.basic_outcomes.process_request_time") do
        res = (quizzes_next_tool?(tool) ? BasicLTI::QuizzesNextLtiResponse : LtiResponse).new(xml)

        unless res.handle_request(tool)
          res.code_major = "unsupported"
          res.description = "Request could not be handled. ¯\\_(ツ)_/¯"
        end
        res
      end
    end

    def self.quizzes_next_tool?(tool)
      tool.tool_id == "Quizzes 2" && tool.context.root_account.feature_enabled?(:quizzes_next_submission_history)
    end

    def self.process_legacy_request(tool, params)
      res = LtiResponse::Legacy.new(params)

      unless res.handle_request(tool)
        res.code_major = "unsupported"
        res.description = "Legacy request could not be handled. ¯\\_(ツ)_/¯"
      end
      res
    end

    class LtiResponse
      include TextHelper
      attr_accessor :code_major, :severity, :description, :body, :error_code

      def initialize(lti_request)
        @lti_request = lti_request
        self.code_major = "success"
        self.severity = "status"
      end

      def sourcedid
        @lti_request&.at_css("imsx_POXBody sourcedGUID > sourcedId").try(:content)
      end

      def message_ref_identifier
        @lti_request&.at_css("imsx_POXHeader imsx_messageIdentifier").try(:content)
      end

      def operation_ref_identifier
        tag = @lti_request&.at_css("imsx_POXBody *:first").try(:name)
        tag&.sub(/Request$/, "")
      end

      def result_score
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultScore > textString").try(:content)
      end

      def submission_submitted_at
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > submissionDetails > submittedAt").try(:content)
      end

      def result_total_score
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultTotalScore > textString").try(:content)
      end

      def result_data_text
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > text").try(:content)
      end

      def result_data_url
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > url").try(:content)
      end

      def result_data_download_url
        url = @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > downloadUrl").try(:content)
        name = @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > documentName").try(:content)
        { url:, name: } if url && name
      end

      def result_data_launch_url
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > resultRecord > result > resultData > ltiLaunchUrl").try(:content)
      end

      def prioritize_non_tool_grade?
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > submissionDetails > prioritizeNonToolGrade").present?
      end

      def needs_additional_review?
        @lti_request&.at_css("imsx_POXBody > replaceResultRequest > submissionDetails > needsAdditionalReview").present?
      end

      def user_enrollment_active?(assignment, user)
        assignment.context.student_enrollments.where(user_id: user).active_or_pending_by_date.any?
      end

      def to_xml
        xml = LtiResponse.envelope.dup
        xml.at_css("imsx_POXHeader imsx_statusInfo imsx_codeMajor").content = code_major
        xml.at_css("imsx_POXHeader imsx_statusInfo imsx_severity").content = severity
        xml.at_css("imsx_POXHeader imsx_statusInfo imsx_description").content = description
        xml.at_css("imsx_POXHeader imsx_statusInfo imsx_messageRefIdentifier").content = message_ref_identifier
        xml.at_css("imsx_POXHeader imsx_statusInfo imsx_operationRefIdentifier").content = operation_ref_identifier
        xml.at_css("imsx_POXBody").inner_html = body if body.present?

        error_code_node = xml.at_css("imsx_POXHeader imsx_statusInfo ext_canvas_error_code")
        error_code.present? ? error_code_node.content = error_code : error_code_node.remove

        xml.to_s
      end

      def self.envelope
        return @envelope if @envelope

        @envelope = Nokogiri::XML.parse <<~XML
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
                  <ext_canvas_error_code></ext_canvas_error_code>
                </imsx_statusInfo>
              </imsx_POXResponseHeaderInfo>
            </imsx_POXHeader>
            <imsx_POXBody>
            </imsx_POXBody>
          </imsx_POXEnvelopeResponse>
        XML
        @envelope.encoding = "UTF-8"
        @envelope
      end

      def handle_request(tool)
        # check if we recognize the xml structure
        return false unless operation_ref_identifier

        # verify the lis_result_sourcedid param, which will be a canvas-signed
        # tuple of (assignment, user) to ensure that only this launch of
        # the tool is attempting to modify this data.
        source_id = sourcedid

        begin
          assignment, user = BasicLTI::BasicOutcomes.decode_source_id(tool, source_id)
        rescue Errors::InvalidSourceId => e
          report_failure(e.code, e.to_s)
          self.body = "<#{operation_ref_identifier}Response />"
          return true
        end

        op = operation_ref_identifier.underscore
        return false unless respond_to?(:"handle_#{op}", true)

        InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.requests", tags: { op:, type: request_type })

        # Write results are disabled for concluded users, read results are still allowed
        if op != "read_result" && !user_enrollment_active?(assignment, user)
          report_failure(:course_not_available, "Course not available for student")
          self.body = "<#{operation_ref_identifier}Response />"
          true
        else
          send(:"handle_#{op}", tool, assignment, user)
        end
      end

      def self.ensure_score_update_possible(submission:, prioritize_non_tool_grade:)
        yield if block_given? && !(submission&.grader_id && submission.grader_id > 0 && prioritize_non_tool_grade)
      end

      def self.create_homework_submission(submission_hash, assignment, user)
        submission = assignment.submit_homework(user, submission_hash.clone) if submission_hash[:submission_type].present?
        submission = assignment.grade_student(user, submission_hash).first if submission_hash[:grade].present?
        submission
      end

      def self.fetch_attachment_and_save_submission(url, attachment, submission_hash, assignment, user, attempt_number = 0)
        failed_retryable = attachment.clone_url(url, "rename", true)
        if failed_retryable && ((attempt_number += 1) < MAX_ATTEMPTS)
          # Exits out of the first job and creates a second one so that the run_at time won't hold back
          # the entire n_strand. Also creates it in a different strand for retries, so we shouldn't block
          # any incoming uploads.
          InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.fetch_jobs_failures")
          job_options = {
            priority: Delayed::HIGH_PRIORITY,
            # because inst-jobs only takes 2 items from an array to make a string strand
            # name and this uses 3
            n_strand: (Attachment.clone_url_strand(url) << "failed").join("/"),
            run_at: Time.now.utc + (attempt_number**4) + 5
          }
          delay(**job_options).fetch_attachment_and_save_submission(
            url,
            attachment,
            submission_hash,
            assignment,
            user,
            attempt_number
          )
        else
          InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.fetch_jobs")
          create_homework_submission submission_hash, assignment, user
        end
      end

      protected

      def request_type
        :basic
      end

      def report_failure(code, description)
        self.code_major = "failure"
        self.description = description
        self.error_code = code
        InstStatsd::Statsd.increment("lti.1_1.basic_outcomes.failures", tags: { op: operation_ref_identifier.underscore, type: request_type, error_code: code })
      end

      def failure?
        code_major == "failure"
      end

      # for New Quizzes check BasicLTI::QuizzesNextLtiResponse.handle_replace_result
      def handle_replace_result(tool, assignment, user)
        text_value = result_score
        score_value = result_total_score
        begin
          new_score = Float(text_value)
        rescue
          new_score = false
          unless text_value.nil?
            report_failure(:no_parseable_result_score, I18n.t("lib.basic_lti.no_parseable_score.result", <<~TEXT, grade: text_value))
              Unable to parse resultScore: %{grade}
            TEXT
          end
        end
        begin
          raw_score = Float(score_value)
        rescue
          raw_score = false
          unless score_value.nil? || failure?
            report_failure(:no_parseable_result_total_score, I18n.t("lib.basic_lti.no_parseable_score.result_total", <<~TEXT, grade: score_value))
              Unable to parse resultTotalScore: %{grade}
            TEXT
          end
        end
        submission_hash = {}
        existing_submission = assignment.submissions.where(user_id: user.id).first
        if (text = result_data_text)
          submission_hash[:body] = text
          submission_hash[:submission_type] = "online_text_entry"
        elsif (url = result_data_url)
          submission_hash[:url] = url
          submission_hash[:submission_type] = "online_url"
        elsif (result_data = result_data_download_url)
          url = result_data[:url]
          attachment = Attachment.create!(
            shard: user.shard,
            context: user,
            file_state: "deleted",
            workflow_state: "unattached",
            filename: result_data[:name],
            display_name: result_data[:name],
            user:
          )

          submission_hash[:attachments] = [attachment]
          submission_hash[:submission_type] = "online_upload"
        elsif (launch_url = result_data_launch_url)
          submission_hash[:url] = launch_url
          submission_hash[:submission_type] = "basic_lti_launch"
        elsif !existing_submission || existing_submission.submission_type.blank?
          submission_hash[:submission_type] = "external_tool"
        end

        # Sometimes we want to pass back info, but not overwrite the submission score if entered by something other
        # than the ltitool before the tool finished pushing it. We've seen this need with NewQuizzes
        LtiResponse.ensure_score_update_possible(submission: existing_submission, prioritize_non_tool_grade: prioritize_non_tool_grade?) do
          if assignment.grading_type == "pass_fail" && (raw_score || new_score)
            submission_hash[:grade] = (((raw_score || new_score) > 0) ? "pass" : "fail")
            submission_hash[:grader_id] = -tool.id
          elsif raw_score
            submission_hash[:grade] = raw_score
            submission_hash[:grader_id] = -tool.id
          elsif new_score
            if (0.0..1.0).cover?(new_score)
              submission_hash[:grade] = "#{round_if_whole(new_score * 100)}%"
              submission_hash[:grader_id] = -tool.id
            else
              report_failure(:bad_score, I18n.t("lib.basic_lti.bad_score", "Score is not between 0 and 1"))
            end
          elsif !failure? && !text && !url && !launch_url
            report_failure(:no_score, I18n.t("lib.basic_lti.no_score", "No score given"))
          end
        end

        xml_submitted_at = submission_submitted_at
        submitted_at = xml_submitted_at.present? ? Time.zone.parse(xml_submitted_at) : nil
        if xml_submitted_at.present? && submitted_at.nil?
          report_failure(:timestamp_not_parseable, I18n.t("Invalid timestamp - timestamp not parseable"))
        elsif submitted_at.present? && submitted_at > 1.minute.from_now
          report_failure(:timestamp_in_future, I18n.t("Invalid timestamp - timestamp in future"))
        end
        submission_hash[:submitted_at] = submitted_at || Time.zone.now

        if !failure? && assignment.grading_type != "pass_fail" && assignment.points_possible.nil?
          unless (submission = existing_submission)
            submission = Submission.create!(submission_hash.merge(user:,
                                                                  assignment:))
          end
          submission.submission_comments.create!(comment: I18n.t("lib.basic_lti.no_points_comment", <<~TEXT, grade: submission_hash[:grade]))
            An external tool attempted to grade this assignment as %{grade}, but was unable
            to because the assignment has no points possible.
          TEXT
          report_failure(:no_points_possible, I18n.t("lib.basic_lti.no_points_possible", "Assignment has no points possible."))
        elsif !failure?
          if attachment
            job_options = {
              priority: Delayed::HIGH_PRIORITY,
              n_strand: Attachment.clone_url_strand(url)
            }

            self.class.delay(**job_options).fetch_attachment_and_save_submission(
              url,
              attachment,
              submission_hash,
              assignment,
              user
            )
          elsif !(@submission = self.class.create_homework_submission(submission_hash, assignment, user))
            report_failure(:no_submission_created, I18n.t("lib.basic_lti.no_submission_created", "This outcome request failed to create a new homework submission."))
          end
        end

        self.body = "<replaceResultResponse />"

        true
      end

      def handle_delete_result(tool, assignment, user)
        assignment.grade_student(user, grade: nil, grader_id: -tool.id)
        self.body = "<deleteResultResponse />"
        true
      end

      def handle_read_result(_, assignment, user)
        @submission = assignment.submission_for_student(user)
        self.body = <<~XML
          <readResultResponse>
            <result>
              <resultScore>
                <language>en</language>
                <textString>#{submission_score}</textString>
              </resultScore>
            </result>
          </readResultResponse>
        XML
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

        def request_type
          :legacy
        end

        def sourcedid
          @params[:sourcedid]
        end

        def result_score
          @params[:result_resultscore_textstring]
        end

        def operation_ref_identifier
          {
            "basic-lis-updateresult" => "replaceResult",
            "basic-lis-readresult" => "readResult",
            "basic-lis-deleteresult" => "deleteResult"
          }[@params[:lti_message_type].try(:downcase)]
        end

        def to_xml
          xml = LtiResponse::Legacy.envelope.dup
          xml.at_css("message_response > statusinfo > codemajor").content = code_major.capitalize
          if (score = submission_score)
            xml.at_css("message_response > result > sourcedid").content = sourcedid
            xml.at_css("message_response > result > resultscore > textstring").content = score
          else
            xml.at_css("message_response > result").remove
          end
          xml.to_s
        end

        def self.envelope
          return @envelope if @envelope

          @envelope = Nokogiri::XML.parse <<~XML
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
          @envelope.encoding = "UTF-8"
          @envelope
        end
      end
    end
  end
end
