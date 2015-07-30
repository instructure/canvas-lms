require 'turnitin_api'
module Turnitin
  class OutcomeResponseProcessor

    def initialize(tool, assignment, user, outcomes_response_json)
      @tool = tool
      @assignment = assignment
      @user = user
      @outcomes_response_json = outcomes_response_json
    end


    def process
      attachment = create_attachment
      @assignment.submit_homework(@user ,attachments:[attachment], submission_type: 'online_upload')
    end
    handle_asynchronously :process, max_attempts: 1, priority: Delayed::LOW_PRIORITY

    private

    def create_attachment

      lti_params = {
          'user_id' => Lti::Asset.opaque_identifier_for(@user),
          'context_id' => Lti::Asset.opaque_identifier_for(@assignment.context),
          'context_title' => @assignment.context.name,
          'lis_person_contact_email_primary' => @user.email
      }
      turnitin_client = TurnitinApi::OutcomesResponseTransformer.new(@tool.consumer_key, @tool.shared_secret, lti_params, @outcomes_response_json)
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

  end

end