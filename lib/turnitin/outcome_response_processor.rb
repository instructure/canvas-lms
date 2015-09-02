require 'turnitin_api'
module Turnitin
  class OutcomeResponseProcessor

    MAX_ATTEMPTS=11.freeze  # this one goes to 11
    INTERVAL=5.minutes.freeze
    def initialize(tool, assignment, user, outcomes_response_json)
      @tool = tool
      @assignment = assignment
      @user = user
      @outcomes_response_json = outcomes_response_json
    end

    def process
      attachment = create_attachment
      submission = @assignment.submit_homework(@user, attachments:[attachment], submission_type: 'online_upload')
      asset_string = attachment.asset_string
      update_turnitin_data!(submission, asset_string, status: 'pending', outcome_response: @outcomes_response_json)
      self.send_later(:update_originality_data, submission, asset_string)
    end
    handle_asynchronously :process, max_attempts: 1, priority: Delayed::LOW_PRIORITY

    def turnitin_client
      @turnitin_client ||= (
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
      )
    end

    def update_originality_data(submission, asset_string, attempt=1)
      if turnitin_client.scored?
        update_turnitin_data!(submission, asset_string, turnitin_data)
      elsif attempt <= MAX_ATTEMPTS
        send_at(INTERVAL.from_now, :update_originality_data,  submission, asset_string, attempt + 1)
      else
        new_data = {
            status: 'error',
            public_error_message: I18n.t('turnitin.no_score_after_retries', 'Turnitin has not returned a score after %{max_tries} attempts to retrieve one.', max_tries: MAX_ATTEMPTS)
        }
        update_turnitin_data!(submission, asset_string, new_data)
      end
    end


    # dont try and recreate the turnitin client in a delayed job. bad things happen
    def send_later(*args)
      stash { super(*args) }
    end

    # dont try and recreate the turnitin client in a delayed job. bad things happen
    def send_at(*args)
      stash { super(*args) }
    end

    private

    def stash
      old_turnit_client = @turnitin_client
      @turnitin_client = nil
      yield
      @turnitin_client = old_turnit_client
    end

    def create_attachment
      attachment = nil
      Dir.mktmpdir do |dirname|
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