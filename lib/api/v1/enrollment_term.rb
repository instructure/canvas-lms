module Api::V1::EnrollmentTerm
  include Api::V1::Json

  def enrollment_term_json(enrollment_term, user, session, includes)
    api_json(enrollment_term, user, session, :only => %w(id name start_at end_at))
  end
end