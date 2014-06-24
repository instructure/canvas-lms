module Common

  def course_exists?(sis_source_id)
    course = Course.where(:sis_source_id => sis_source_id).all
    if course.length == 1
      return true
    end
      false
  end

  # orverride ApplicationController::api_request? to force canvas to treat all calls to /sfu/api/* as an API call
  def api_request?
    return true
  end

end
