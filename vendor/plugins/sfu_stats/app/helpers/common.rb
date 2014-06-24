module Common

  # orverride ApplicationController::api_request? to force canvas to treat all calls to /sfu/api/* as an API call
  def api_request?
    return true
  end

end
