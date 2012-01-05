module Api::V1::Enrollment
  include Api::V1::Json

  API_ENROLLMENT_JSON_OPTS = [:root_account_id, :id, :user_id, :course_section_id,
    :limit_privileges_to_course_section, :workflow_state, :course_id, :type]

  def enrollment_json(enrollment, user, session)
    api_json(enrollment, user, session, :only => API_ENROLLMENT_JSON_OPTS).tap do |json|
      json[:enrollment_state] = json.delete('workflow_state')
    end
  end
end
