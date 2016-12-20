require 'turnitin_api'
module Turnitin
  class TiiClient < TurnitinApi::OutcomesResponseTransformer

    def initialize(user, assignment, tool, outcomes_response_json)
      lti_params = {
        'user_id' => Lti::Asset.opaque_identifier_for(user),
        'context_id' => Lti::Asset.opaque_identifier_for(assignment.context),
        'context_title' => assignment.context.name,
        'lis_person_contact_email_primary' => user.email
      }

      super(
        tool.consumer_key,
        tool.shared_secret,
        lti_params,
        outcomes_response_json
      )
    end

    def turnitin_data
      {
        similarity_score: originality_data["numeric"]["score"].to_f,
        web_overlap: originality_data["breakdown"]["internet_score"].to_f,
        publication_overlap: originality_data["breakdown"]["publications_score"].to_f,
        student_overlap: originality_data["breakdown"]["submitted_works_score"].to_f,
        state: Turnitin.state_from_similarity_score(originality_data["numeric"]["score"].to_f),
        report_url: originality_report_url,
        status: "scored"
      }
    end

  end
end
