module Api::V1::EnrollmentTerm
  include Api::V1::Json

  def enrollment_term_json(enrollment_term, user, session, includes)
    api_json(enrollment_term, user, session, :only => %w(id name start_at end_at)).tap do |hash|
      hash['sis_term_id'] = enrollment_term.sis_source_id if enrollment_term.root_account.grants_rights?(user, :read_sis, :manage_sis).values.any?
    end
  end
end