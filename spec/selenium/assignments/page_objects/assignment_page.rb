class Assignment
  include SeleniumDependencies

  def visit_as_student(course, assignment)
    get "/courses/#{course}/assignments/#{assignment}"
  end

  def submission_detail_link
    fj("a:contains('Submission Details')")
  end

end
