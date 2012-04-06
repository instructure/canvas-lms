module Api::V1::Enrollment
  include Api::V1::Json
  include Api::V1::User

  API_ENROLLMENT_JSON_OPTS = [:root_account_id, :id, :user_id, :course_section_id,
    :limit_privileges_to_course_section, :workflow_state, :course_id, :type]

  def enrollment_json(enrollment, user, session, includes = [])
    api_json(enrollment, user, session, :only => API_ENROLLMENT_JSON_OPTS).tap do |json|
      json[:enrollment_state] = json.delete('workflow_state')
      if enrollment.student?
        json[:grades] = {
          :html_url => course_student_grades_url(enrollment.course_id, enrollment.user_id),
        }
      end
      json[:html_url] = course_user_url(enrollment.course_id, enrollment.user_id)
      user_includes = includes.include?('avatar_url') ? ['avatar_url'] : []
      json[:user] = user_json(enrollment.user, user, session, user_includes) if includes.include?(:user)
    end
  end
end
