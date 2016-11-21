require 'turnitin_api'
module Turnitin
  class SubmissionNotScoredError < StandardError; end
  class OutcomeResponseProcessor

    MAX_ATTEMPTS=14.freeze  # this one goes to 14 (so that the last attempt is ~24hr after the first)

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
      attachment = create_attachment
      submission = @assignment.submit_homework(@user, attachments:[attachment], submission_type: 'online_upload')
      submission.submitted_at = turnitin_client.uploaded_at if turnitin_client.uploaded_at
      asset_string = attachment.asset_string
      update_turnitin_data!(submission, asset_string, status: 'pending', outcome_response: @outcomes_response_json)
      self.send_later_enqueue_args(:update_originality_data, { max_attempts: self.class.max_attempts }, submission, asset_string)
    end
    handle_asynchronously :process, max_attempts: max_attempts, priority: Delayed::LOW_PRIORITY

    def resubmit(submission, asset_string)
      self.send_later_enqueue_args(:update_originality_data, { max_attempts: self.class.max_attempts }, submission, asset_string)
    end

    def turnitin_client
      @_turnitin_client ||= build_turnitin_client
    end

    def build_turnitin_client
      lti_params = {
        'user_id' => Lti::Asset.opaque_identifier_for(@user),
        'context_id' => Lti::Asset.opaque_identifier_for(@assignment.context),
        'context_title' => @assignment.context.name,
        'lis_person_contact_email_primary' => @user.email
      }

      TurnitinApi::OutcomesResponseTransformer.new(
        @tool.consumer_key,
        @tool.shared_secret,
        lti_params,
        @outcomes_response_json
      )
    end

    def update_originality_data(submission, asset_string)
      if turnitin_client.scored?
        update_turnitin_data!(submission, asset_string, turnitin_data)
      elsif attempt_number < self.class.max_attempts
        raise SubmissionNotScoredError
      else
        new_data = {
            status: 'error',
            public_error_message: I18n.t('turnitin.no_score_after_retries', 'Turnitin has not returned a score after %{max_tries} attempts to retrieve one.', max_tries: self.class.max_attempts)
        }
        update_turnitin_data!(submission, asset_string, new_data)
      end
    end

    # dont try and recreate the turnitin client in a delayed job. bad things happen
    def send_later_enqueue_args(*args)
      stash { super(*args) }
    end

    private

    def stash
      old_turnit_client = @_turnitin_client
      @_turnitin_client = nil
      yield
      @_turnitin_client = old_turnit_client
    end

    def attempt_number
      current_job = Delayed::Worker.current_job
      current_job ? current_job.attempts + 1 : 1
    end

    def create_attachment
      attachment = nil
      Dir.mktmpdir do |dirname|
        begin
          turnitin_client.original_submission do |response|
            filename = response.headers['content-disposition'].match(/filename=(\"?)(.+)\1/)[2]
            path = File.join(dirname, filename)
            File.open(path, 'wb') do |f|
              f.write(response.body)
            end
            attachment = @assignment.attachments.new(
                uploaded_data: Rack::Test::UploadedFile.new(path, response.headers['content-type'], true),
                display_name: filename,
                user: @user
            )
            attachment.save!
          end
        rescue StandardError
          if attempt_number == self.class.max_attempts
            @assignment.attachments.create!(
              uploaded_data: StringIO.new(I18n.t('An error occurred while attempting to contact Turnitin.')),
                display_name: 'Failed turnitin submission',
                filename: 'failed_turnitin.txt',
                user: @user
            )
          end
          raise
        end
      end
      attachment
    end

    def turnitin_data
      {
        similarity_score: turnitin_client.originality_data["numeric"]["score"].to_f,
        web_overlap: turnitin_client.originality_data["breakdown"]["internet_score"].to_f,
        publication_overlap: turnitin_client.originality_data["breakdown"]["publications_score"].to_f,
        student_overlap: turnitin_client.originality_data["breakdown"]["submitted_works_score"].to_f,
        state: Turnitin.state_from_similarity_score(turnitin_client.originality_data["numeric"]["score"].to_f),
        report_url: turnitin_client.originality_report_url,
        status: "scored"
      }
    end

    def update_turnitin_data!(submission, asset_string, new_data)
      turnitin_data = submission.turnitin_data || {}
      turnitin_data[asset_string] ||= {}
      turnitin_data[asset_string].merge!(new_data)
      submission.turnitin_data_changed!
      submission.save
    end

  end
end
