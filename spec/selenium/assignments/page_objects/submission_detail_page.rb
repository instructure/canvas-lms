class SubmissionDetails
  include SeleniumDependencies

  def visit_as_student(courseid,assignmentid,studentid)
    get "/courses/#{courseid}/assignments/#{assignmentid}/submissions/#{studentid}"
  end

  def comment_text_by_id(comment_id)
    f("#submission_comment_#{comment_id} span").text
  end

  def comment_list_div
    f('.comment_list')
  end

  def view_feedback_link
    f("div .file-upload-submission-attachment a").attribute('text')
  end
end
