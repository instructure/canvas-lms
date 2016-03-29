module AssessmentRequestHelper

  def submission_author_name_for(assessment_request, prepend = '')
    submission = @submission || assessment_request.submission
    if (assessment_request && can_do(assessment_request, @current_user, :read_assessment_user)) || !assessment_request
      "#{prepend}#{context_user_name(@context, submission.user)}"
    else
      "#{prepend}#{I18n.t(:anonymous_user, 'Anonymous User')}"
    end
  end

end