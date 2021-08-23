# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Turnitin
  class OutcomeResponseProcessor

    # this one goes to 14 (so that the last attempt is ~24hr after the first)
    MAX_ATTEMPTS=14

    def self.max_attempts
      MAX_ATTEMPTS
    end

    def initialize(tool, assignment, user, outcomes_response_json)
      @tool = tool
      @assignment = assignment
      @user = user
      @outcomes_response_json = outcomes_response_json
    end

    def process
      submission = @assignment.submissions.find_by(user: @user, submitted_at: (turnitin_client.uploaded_at || Time.zone.now))
      submission.nil? ? new_submission : submission.retrieve_lti_tii_score
    end

    def new_submission
      # Create an attachment for the file submitted via the TII tool.
      # If the score is still pending, this will raise
      # `Errors::ScoreStillPendingError`
      attachment = AttachmentManager.create_attachment(@user, @assignment, @tool, @outcomes_response_json)

      # If we've made it this far, we've successfully
      # retrieved an attachment from TII

      asset_string = attachment.asset_string

      # Create a submission using the attachment
      submission = submit_homework(attachment)

      # Set submission processing status to "pending"
      update_turnitin_data!(submission, asset_string, status: 'pending', outcome_response: @outcomes_response_json)

      # Start a job that attempts to retrieve the
      # score from TII.
      #
      # If no score is available yet, this job
      # will terminate and retry up to
      # the max_attempts limit
      #
      stash_turnitin_client do
        delay(max_attempts: self.class.max_attempts).update_originality_data(submission, asset_string)
      end
    rescue Errors::ScoreStillPendingError
      if attempt_number == self.class.max_attempts
        create_error_attachment
        raise
      else
        turnitin_processor = Turnitin::OutcomeResponseProcessor.new(@tool, @assignment, @user, @outcomes_response_json)
        stash_turnitin_client do
          turnitin_processor.delay(max_attempts: Turnitin::OutcomeResponseProcessor.max_attempts,
            priority: Delayed::LOW_PRIORITY,
            attempts: attempt_number,
            run_at: Time.now.utc + (attempt_number ** 4) + 5).
            new_submission
        end
      end
    rescue StandardError
      if attempt_number == self.class.max_attempts
        create_error_attachment
      end
      raise
    end

    def resubmit(submission, asset_string)
      stash_turnitin_client do
        delay(max_attempts: self.class.max_attempts).update_originality_data(submission, asset_string)
      end
    end

    def turnitin_client
      @_turnitin_client ||= TiiClient.new(@user, @assignment, @tool, @outcomes_response_json)
    end

    def update_originality_data(submission, asset_string)
      if turnitin_client.scored?
        update_turnitin_data!(submission, asset_string, turnitin_client.turnitin_data)
      elsif attempt_number < self.class.max_attempts
        InstStatsd::Statsd.increment("submission_not_scored.account_#{@assignment.root_account.global_id}",
                                     short_stat: 'submission_not_scored',
                                     tags: { root_account_id: @assignment.root_account.global_id })
        # Retry the update_originality_data job
        raise Errors::SubmissionNotScoredError
      else
        new_data = {
          status: 'error',
          public_error_message: I18n.t(
            'turnitin.no_score_after_retries',
            'Turnitin has not returned a score after %{max_tries} attempts to retrieve one.',
            max_tries: self.class.max_attempts
          )
        }
        update_turnitin_data!(submission, asset_string, new_data)
      end
    end

    private

    def create_error_attachment
      @assignment.attachments.create!(
        uploaded_data: StringIO.new(I18n.t('An error occurred while attempting to contact Turnitin.')),
        display_name: 'Failed turnitin submission',
        filename: 'failed_turnitin.txt',
        user: @user
      )
    end

    # the turnitin client has a proc embedded
    # in it's faraday connection.  If you try to serialize it,
    # it will fail to deserialize (for good reason, closures can't
    # take the whole state of the system with them when written
    # as yaml).  This method un-sets the ivar long enough to
    # serialize the object for job processing (a turnitin client
    # will be created in the job when necessary).
    def stash_turnitin_client
      old_turnitin_client = @_turnitin_client
      @_turnitin_client = nil
      result = yield
      @_turnitin_client = old_turnitin_client
      result
    end

    def attempt_number
      current_job = Delayed::Worker.current_job
      current_job ? current_job.attempts + 1 : 1
    end

    def update_turnitin_data!(submission, asset_string, new_data)
      turnitin_data = submission.turnitin_data || {}
      turnitin_data[asset_string] ||= {}
      turnitin_data[asset_string].merge!(new_data)
      submission.turnitin_data_changed!
      submission.save
    end

    def submit_homework(attachment)
      @assignment.submit_homework(@user, attachments: [attachment], submission_type: 'online_upload', submitted_at: turnitin_client.uploaded_at)
    end

  end
end
