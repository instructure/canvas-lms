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

module Lti::Ims
  # @API Score
  #
  # Score API for IMS Assignment and Grade Services
  #
  # @model Score
  #     {
  #       "id": "Score",
  #       "description": "",
  #       "properties": {
  #          "userId": {
  #            "description": "The lti_user_id or the Canvas user_id",
  #            "example": "50 | 'abcasdf'",
  #            "type": "string"
  #          },
  #          "scoreGiven": {
  #            "description": "The Current score received in the tool for this line item and user, scaled to the scoreMaximum",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "scoreMaximum": {
  #            "description": "Maximum possible score for this result; it must be present if scoreGiven is present.",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "comment": {
  #            "description": "Comment visible to the student about this score.",
  #            "type": "string"
  #          },
  #          "timestamp": {
  #            "description": "Date and time when the score was modified in the tool. Should use subsecond precision.",
  #            "example": "2017-04-16T18:54:36.736+00:00",
  #            "type": "string"
  #          },
  #          "activityProgress": {
  #            "description": "Indicate to Canvas the status of the user towards the activity's completion. Must be one of Initialized, Started, InProgress, Submitted, Completed",
  #            "example": "Completed",
  #            "type": "string"
  #          },
  #          "gradingProgress": {
  #            "description": "Indicate to Canvas the status of the grading process. A value of PendingManual will require intervention by a grader. Values of NotReady, Failed, and Pending will cause the scoreGiven to be ignored. FullyGraded values will require no action. Possible values are NotReady, Failed, Pending, PendingManual, FullyGraded",
  #            "example": "FullyGraded",
  #            "type": "string"
  #          }
  #       }
  #     }
  class ScoresController < ApplicationController
    include Concerns::GradebookServices
    include Api::V1::Attachment

    before_action(
      :verify_line_item_in_context,
      :verify_user_in_context,
      :verify_required_params,
      :verify_valid_timestamp,
      :verify_exclusive_key_pairs,
      :verify_valid_submitted_at,
    )

    MIME_TYPE = 'application/vnd.ims.lis.v1.score+json'.freeze

    # @API Create a Score
    #
    # Create a new Result from the score params. If this is for the first created line_item for a
    # resourceLinkId, or it is a line item that is not attached to a resourceLinkId, then a submission
    # record will be created for the associated assignment when gradingProgress is set to
    # FullyGraded or PendingManual.
    #
    # The submission score will also be updated when a score object is sent with either of those
    # two values for gradingProgress. If a score object is sent with either of FullyGraded or
    # PendingManual as the value for gradingProgress and scoreGiven is missing, the assignment
    # will not be graded. This also supposes the line_item meets the condition to create a submission.
    #
    # A submission comment with an unknown author will be created when the comment value is included.
    # This also supposes the line_item meets the condition to create a submission.
    #
    # NOTE: Upcoming Feature
    # It will soon be possible to submit a file along with this score, which will attach the file to the
    # submission that is created. Files should be formatted as Content Items, with the correct syntax
    # below.
    #
    # Returns a url pointing to the Result. If any files were submitted, also returns the Content Items
    # which were sent in the request, each with a url pointing to the Progress of the file upload.
    #
    # @argument userId [Required, String]
    #   The lti_user_id or the Canvas user_id.
    #   Returns a 422 if user not found in Canvas or is not a student.
    #
    # @argument activityProgress [Required, String]
    #   Indicate to Canvas the status of the user towards the activity's completion.
    #   Must be one of Initialized, Started, InProgress, Submitted, Completed.
    #
    # @argument gradingProgress [Required, String]
    #   Indicate to Canvas the status of the grading process.
    #   A value of PendingManual will require intervention by a grader.
    #   Values of NotReady, Failed, and Pending will cause the scoreGiven to be ignored.
    #   FullyGraded values will require no action.
    #   Possible values are NotReady, Failed, Pending, PendingManual, FullyGraded.
    #
    # @argument timestamp [Required, String]
    #   Date and time when the score was modified in the tool. Should use subsecond precision.
    #   Returns a 400 if the timestamp is earlier than the updated_at time of the Result.
    #
    # @argument scoreGiven [Number]
    #   The Current score received in the tool for this line item and user,
    #   scaled to the scoreMaximum
    #
    # @argument scoreMaximum [Number]
    #   Maximum possible score for this result; it must be present if scoreGiven is present.
    #   Returns 412 if not present when scoreGiven is present.
    #
    # @argument comment [String]
    #   Comment visible to the student about this score.
    #
    # @argument https://canvas.instructure.com/lti/submission [Optional, Object]
    #   (EXTENSION) Optional submission type and data.
    #   new_submission [Boolean] flag to indicate that this is a new submission. Defaults to true unless submission_type is none.
    #   submission_type [String] permissible values are: none, basic_lti_launch, online_text_entry, external_tool, or online_url. Defaults to external_tool. Ignored if content_items are provided.
    #   submission_data [String] submission data (URL or body text)
    #   submitted_at [String] Date and time that the submission was originally created. Should use subsecond precision. This should match the data and time that the original submission happened in Canvas.
    #   content_items [Array] Files that should be included with the submission. Each item should contain `type: file`, a url pointing to the file, a title, and a progress url that Canvas can report to. If present, submission_type will be online_upload.
    #
    # @returns resultUrl [String]
    #   The url to the result that was created.
    #
    # @returns https://canvas.instructure.com/lti/submission [Optional, Object]
    #   (EXTENSION) Optional data about files included with the submission.
    #   content_items [Array] contains `type:file`, `url`, `title` from the request, and `progress` which points to the Progress API.
    #
    # @example_request
    #   {
    #     "timestamp": "2017-04-16T18:54:36.736+00:00",
    #     "scoreGiven": 83,
    #     "scoreMaximum": 100,
    #     "comment": "This is exceptional work.",
    #     "activityProgress": "Completed",
    #     "gradingProgress": "FullyGraded",
    #     "userId": "5323497",
    #     "https://canvas.instructure.com/lti/submission": {
    #       "new_submission": true,
    #       "submission_type": "online_url",
    #       "submission_data": "https://instructure.com",
    #       "submitted_at": "2017-04-14T18:54:36.736+00:00",
    #       "content_items": [
    #         {
    #           "type": "file",
    #           "url": "https://instructure.com/test_file.txt",
    #           "title": "Submission File"
    #         }
    #       ]
    #     }
    #   }
    #
    # @example_response
    #   {
    #     "resultUrl": "https://canvas.instructure.com/url/to/result",
    #     "https://canvas.instructure.com/lti/submission": {
    #       "content_items": [
    #         {
    #           "type": "file",
    #           "url": "https://instructure.com/test_file.txt",
    #           "title": "Submission File"
    #           "progress": "https://canvas.instructure.com/url/to/progress"
    #         }
    #   }
    def create
      update_or_create_result

      begin
        content_items = upload_submission_files
        render json: {
               resultUrl: result_url,
               Lti::Result::AGS_EXT_SUBMISSION => { content_items: content_items }
             },
             content_type: MIME_TYPE
      rescue Net::ReadTimeout, CanvasHttp::CircuitBreakerError
        render_error('failed to communicate with file service', :gateway_timeout)
      rescue CanvasHttp::InvalidResponseCodeError => err
        err_message = "uploading to file service failed with #{err.code}: #{err.body}"
        return render_error(err_message, :bad_request) if err.code == 400

        # 5xx and other unexpected errors
        render_error(err_message, :internal_server_error)
      end
    end

    private

    REQUIRED_PARAMS = %i[userId activityProgress gradingProgress timestamp].freeze
    OPTIONAL_PARAMS = %i[scoreGiven scoreMaximum comment].freeze
    EXTENSION_PARAMS = [
      :new_submission,
      :submission_type,
      :submission_data,
      :submitted_at,
      content_items: %i[type url title]
    ].freeze
    SCORE_SUBMISSION_TYPES = %w[none basic_lti_launch online_text_entry online_url external_tool online_upload].freeze
    DEFAULT_SUBMISSION_TYPE = 'external_tool'.freeze

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_AGS_SCORE_SCOPE)
    end

    def scores_params
      @_scores_params ||= begin
        update_params = params.permit(REQUIRED_PARAMS + OPTIONAL_PARAMS,
          Lti::Result::AGS_EXT_SUBMISSION => EXTENSION_PARAMS).transform_keys do |k|
            k.to_s.underscore
        end.except(:timestamp, :user_id, :score_given, :score_maximum).to_unsafe_h
        update_params[:extensions] = extract_extensions(update_params)
        update_params.merge(result_score: params[:scoreGiven], result_maximum: params[:scoreMaximum])
      end
    end

    def extract_extensions(update_params)
      {
        Lti::Result::AGS_EXT_SUBMISSION => update_params.delete(Lti::Result::AGS_EXT_SUBMISSION)
      }.compact
    end

    def verify_required_params
      REQUIRED_PARAMS.each { |param| params.require(param) }
    end

    def verify_valid_timestamp
      if timestamp.nil?
        render_error "Provided timestamp of #{params[:timestamp]} not a valid timestamp", :bad_request
      elsif result.present? && result.updated_at > timestamp
        render_error(
          "Provided timestamp of #{params[:timestamp]} before last updated timestamp " \
          "of #{result.updated_at.iso8601(3)}",
          :bad_request
        )
      end
    end

    def verify_valid_submitted_at
      submitted_at = params.dig(Lti::Result::AGS_EXT_SUBMISSION, :submitted_at)
      submitted_at_date = submitted_at.present? ? (Time.zone.parse(submitted_at) rescue nil) : nil
      future_buffer = Setting.get('ags_submitted_at_future_buffer', 1.minute.to_s).to_i.seconds

      if submitted_at.present? && submitted_at_date.nil?
        render_error "Provided submitted_at timestamp of #{submitted_at} not a valid timestamp", :bad_request
      elsif submitted_at_date.present? && submitted_at_date > Time.zone.now + future_buffer
        render_error "Provided submitted_at timestamp of #{submitted_at} in the future", :bad_request
      end
    end

    def verify_exclusive_key_pairs
      return if ignore_score?
      if params.key?(:scoreMaximum)
        return if params[:scoreMaximum].to_f > 0
        render_error('ScoreMaximum must be greater than 0', :unprocessable_entity)
      else
        render_error('ScoreMaximum not supplied when ScoreGiven present.', :unprocessable_entity)
      end
    end

    def score_submission
      return unless line_item.assignment_line_item?

      submission = if new_submission?
        line_item.assignment.submit_homework(user)
      else
        line_item.assignment.find_or_create_submission(user)
      end

      if ignore_score?
        submission.score = nil
      else
        submission = line_item.assignment.grade_student(
          user,
          {score: submission_score, grader_id: -tool.id}
        ).first
      end

      if !submission_type.nil? && SCORE_SUBMISSION_TYPES.include?(submission_type)
        submission.submission_type = submission_type
        case submission_type
        when 'none', 'external_tool', 'online_upload'
          submission.body = nil
          submission.url = nil
        when 'basic_lti_launch', 'online_url'
          submission.body = nil
          submission.url = submission_data
        when 'online_text_entry'
          submission.url = nil
          submission.body = submission_data
        end
      end

      # change submission time without making it a "new" submission
      if submitted_at.present?
        submission.submitted_at = submitted_at
        submission.attempt -= 1 if submission.attempt.try(:'>', 0)
      end

      submission.save!
      submission.add_comment(comment: scores_params[:comment], skip_author: true) if scores_params[:comment].present?
      submission
    end

    def update_or_create_result
      Submission.transaction do
        # As a transaction, the submission update is rolled back if result update fails.
        submission = score_submission
        if result.nil?
          @_result = line_item.results.create!(
            scores_params.merge(created_at: timestamp, updated_at: timestamp, user: user, submission: submission)
          )
        else
          result.update!(scores_params.merge(updated_at: timestamp))
        end
      end
    end

    def upload_submission_files
      file_content_items.map do |item|
        # Pt 1 of the file upload process, which for non-InstFS (ie local or open source) is all that's needed.
        # This upload will always be URL-only, so unless InstFS is enabled a job will be created to pull the
        # file from the given url.
        preflight_json = api_attachment_preflight(
          user,
          request,
          check_quota: false, # we don't check quota when uploading a file for assignment submission
          folder: user.submissions_folder(context), # organize attachment into the course submissions folder
          assignment: line_item.assignment,
          submit_assignment: true,
          return_json: true,
          override_logged_in_user: true,
          override_current_user_with: user,
          params: {
            url: item[:url],
            name: item[:title],
          }
        )

        if preflight_json[:upload_url]
          # Pt 2 of the file upload process, with InstFS enabled.
          response = CanvasHttp.post(
            preflight_json[:upload_url], form_data: preflight_json[:upload_params], multipart: true)

          if response.code.to_i != 201
            raise CanvasHttp::InvalidResponseCodeError.new(response.code.to_i, response.body)
          end
        end

        {
          type: item[:type],
          url: item[:url],
          title: item[:title],
          progress: preflight_json[:progress][:url]
        }
      end
    end

    def submission_score
      scores_params[:result_score].to_f * line_item_score_maximum_scale
    end

    def line_item_score_maximum_scale
      res_max = scores_params[:result_maximum].to_f
      # if this doesn't make sense, just don't scale
      return 1.0 if res_max.nan? || res_max == 0.0
      line_item.score_maximum / scores_params[:result_maximum].to_f
    end

    def ignore_score?
      Lti::Result::ACCEPT_GIVEN_SCORE_TYPES.exclude?(params[:gradingProgress]) || params[:scoreGiven].nil?
    end

    def result
      @_result ||= Lti::Result.active.where(line_item: line_item, user: user).first
    end

    def timestamp
      @_timestamp = Time.zone.parse(params[:timestamp]) rescue nil
    end

    def result_url
      lti_result_show_url(course_id: context.id, line_item_id: line_item.id, id: result.id)
    end

    def submission_type
      # content_items override the provided submission type in favor of uploading a file
      return 'online_upload' if file_content_items.any?

      scores_params.dig(:extensions, Lti::Result::AGS_EXT_SUBMISSION, :submission_type) || DEFAULT_SUBMISSION_TYPE
    end

    def submission_data
      scores_params.dig(:extensions, Lti::Result::AGS_EXT_SUBMISSION, :submission_data)
    end

    # all submissions should count as new (ie, module-progressing) unless explicitly otherwise,
    # if new_submission flag is present and `false`, or submission_type flag is `none`
    def new_submission?
      new_flag = ActiveRecord::Type::Boolean.new.cast(scores_params.dig(:extensions, Lti::Result::AGS_EXT_SUBMISSION, :new_submission))
      (new_flag || new_flag.nil?) && submission_type != 'none'
    end

    def submitted_at
      submitted_at = scores_params.dig(:extensions, Lti::Result::AGS_EXT_SUBMISSION, :submitted_at)
      submitted_at.present? ? (Time.zone.parse(submitted_at) rescue nil): nil
    end

    def file_content_items
      # disable file submission through AGS until all work is completed: INTEROP-6469
      # see also note in docs on line 94
      return [] unless Rails.env.test?

      scores_params.dig(:extensions, Lti::Result::AGS_EXT_SUBMISSION, :content_items)&.select { |item| item[:type] == "file"} || []
    end
  end
end
